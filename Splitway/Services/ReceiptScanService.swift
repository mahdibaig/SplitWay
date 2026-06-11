import Foundation
import UIKit

@MainActor
final class ReceiptScanService: ObservableObject {

    private let expenses: ExpenseRepository
    private let householdService: HouseholdService
    private let sharedItemRuleService: SharedItemRuleService
    private let cleanupService: ReceiptCleanupService
    private let retention: ReceiptRetentionService

    init(
        expenses: ExpenseRepository,
        householdService: HouseholdService,
        sharedItemRuleService: SharedItemRuleService,
        cleanupService: ReceiptCleanupService,
        retention: ReceiptRetentionService
    ) {
        self.expenses = expenses
        self.householdService = householdService
        self.sharedItemRuleService = sharedItemRuleService
        self.cleanupService = cleanupService
        self.retention = retention
    }

    /// Scans a receipt photo and returns a `ReceiptDraft`. Primary path is
    /// the cloud vision endpoint (GPT-4o mini via the proxy) which does
    /// OCR + line-item extraction + categorization in one call. If that
    /// fails for any reason (proxy not configured, rate-limited, network
    /// blip, upstream error), falls back to the local Apple-Vision OCR +
    /// Costco parser + LLM cleanup pipeline so the user still gets a
    /// usable draft. Either way the cloud's draft includes a `scanError`
    /// the UI can surface if the fallback path was taken.
    func scan(image: UIImage) async -> ReceiptDraft {
        await sharedItemRuleService.refresh()
        let processedImage = ReceiptImage.processed(from: image) ?? Data()

        // Primary: cloud vision.
        do {
            let cloud = try await CloudReceiptScanner().scan(image: image)
            return await buildDraft(from: cloud, imageData: processedImage)
        } catch {
            AppLog.lifecycle.error("Cloud receipt scan failed; falling back to local Vision: \(error.localizedDescription, privacy: .public)")
            return await fallbackScan(
                image: image,
                imageData: processedImage,
                cloudError: error
            )
        }
    }

    /// Maps the cloud scanner's flat JSON into a `ReceiptDraft`, applying
    /// any matching `SharedItemRule`s so assignees pre-fill.
    private func buildDraft(from cloud: CloudReceiptScanner.Result, imageData: Data) async -> ReceiptDraft {
        var reviewItems: [ReviewItem] = []
        for entry in cloud.items {
            let category = entry.category.flatMap { ExpenseCategory.lookup($0) }
            let normalized = Self.normalize(entry.name)
            var lineItem = LineItem(
                id: UUID(),
                itemName: entry.name,
                displayName: entry.name,
                normalizedItemName: normalized,
                amount: entry.amount,
                quantity: 1,
                assignedToUserIDs: [],
                category: category
            )
            let rule = sharedItemRuleService.match(for: normalized)
            if let rule {
                switch rule.ruleType {
                case .alwaysShared:
                    lineItem.assignedToUserIDs = []
                case .alwaysAssignedTo(let uid):
                    lineItem.assignedToUserIDs = [uid]
                }
            }
            reviewItems.append(ReviewItem(
                lineItem: lineItem,
                matchedRule: rule,
                rememberChoice: .justThisTime,
                // wasAICleaned tells the row to show the "AI" pill so the
                // user can revert to the raw OCR text. Cloud-scanned items
                // are always AI-named by definition, so always true.
                wasAICleaned: true
            ))
        }
        let subtotal = reviewItems.reduce(Decimal.zero) { $0 + $1.lineItem.amount }
        // Prefer the tax/savings the model read straight off the receipt.
        // Fall back to inferring the net adjustment from the total if the
        // model didn't return them.
        let tax: Decimal
        let savings: Decimal
        if let scannedTax = cloud.tax {
            tax = scannedTax
            savings = cloud.savings ?? 0
        } else if let total = cloud.total, total > subtotal {
            tax = total - subtotal
            savings = 0
        } else {
            tax = 0
            savings = 0
        }
        let total = cloud.total ?? (subtotal - savings + tax)
        return ReceiptDraft(
            imageData: imageData,
            merchant: cloud.merchant,
            items: reviewItems,
            parsedTotal: total,
            // Raw OCR lines aren't available from the cloud path. Synthesize
            // a compact summary so the "View raw OCR text" debug panel
            // still shows something useful.
            rawLines: cloud.items.map { "\($0.name)  \($0.amount)" },
            tax: tax,
            savings: savings
        )
    }

    /// Old local pipeline, used as fallback when the cloud path fails.
    private func fallbackScan(image: UIImage, imageData: Data, cloudError: Error) async -> ReceiptDraft {
        let lines = await VisionOCRService.recognizeText(in: image)
        let parsed = LineItemParser.parse(lines: lines)
        let (cleanedItems, aiCleanedIDs) = await cleanupService.cleanup(
            items: parsed.items,
            merchant: parsed.merchant
        )

        var enrichedItems: [ReviewItem] = []
        for item in cleanedItems {
            var lineItem = item
            lineItem.normalizedItemName = Self.normalize(lineItem.displayName)
            let rule = sharedItemRuleService.match(for: lineItem.normalizedItemName)
            if let rule {
                switch rule.ruleType {
                case .alwaysShared:
                    lineItem.assignedToUserIDs = []
                case .alwaysAssignedTo(let uid):
                    lineItem.assignedToUserIDs = [uid]
                }
            }
            enrichedItems.append(ReviewItem(
                lineItem: lineItem,
                matchedRule: rule,
                rememberChoice: .justThisTime,
                wasAICleaned: aiCleanedIDs.contains(lineItem.id)
            ))
        }

        let subtotal = enrichedItems.reduce(Decimal.zero) { $0 + $1.lineItem.amount }
        // Local OCR rarely reads a reliable receipt total, so only treat the
        // gap as tax when the parser actually found a total larger than the
        // subtotal. Otherwise leave it 0 for the user to fill in.
        let total: Decimal = parsed.total ?? subtotal
        let tax = (parsed.total != nil && total > subtotal) ? total - subtotal : 0

        return ReceiptDraft(
            imageData: imageData,
            merchant: parsed.merchant,
            items: enrichedItems,
            parsedTotal: total,
            rawLines: lines.map(\.text),
            fallbackNotice: Self.fallbackNotice(for: cloudError),
            tax: tax,
            savings: 0
        )
    }

    private static func fallbackNotice(for error: Error) -> String {
        if let scanError = error as? CloudReceiptScanner.ScanError {
            switch scanError {
            case .rateLimited(let limit):
                return "Cloud scan limit reached for today (\(limit)). Showing local OCR results — accuracy may be lower."
            case .visionNotConfigured, .proxyNotConfigured:
                return "Cloud scanning isn't available; using local OCR. Accuracy may be lower."
            case .badStatus(let code, _):
                // Surface the HTTP status so a config issue is diagnosable:
                // 401 = shared secret mismatch, 429 = rate limited,
                // 5xx = worker/provider problem.
                return "Cloud scan failed (HTTP \(code)); using local OCR. Accuracy may be lower."
            case .malformedResponse:
                return "Cloud scan got an unreadable response; using local OCR. Accuracy may be lower."
            }
        }
        // Non-ScanError (network/transport).
        return "Cloud scan failed (network); using local OCR. Accuracy may be lower."
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Saves the reviewed receipt as one or more real Expenses (one per
    /// Saves the reviewed receipt as a SINGLE Expense. Per-line-item
    /// categories are preserved on each `LineItem` (so the Home tab
    /// dropdown can group by category), and the expense's top-level
    /// category is set to the dominant line-item category (by total
    /// amount). Also upserts any `SharedItemRule`s the user asked to
    /// remember.
    @discardableResult
    func saveExpense(
        from draft: ReceiptDraft,
        items: [ReviewItem],
        category: ExpenseCategory,
        description: String,
        date: Date,
        taxAndFees: Decimal,
        activeMembers: [HouseholdMember]
    ) async throws -> Expense {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        let activeIDs = activeMembers.filter { !$0.isArchived }.map(\.id)
        guard !items.isEmpty else { throw RepositoryError.notFound }

        let lineItems = items.map { item -> LineItem in
            var li = item.lineItem
            // Fill in the expense-level category for any line item the
            // user/AI didn't tag, so the dropdown always has something to
            // group by.
            if li.category == nil { li.category = category }
            return li
        }

        let subtotal = lineItems.reduce(Decimal.zero) { $0 + $1.amount }
        // The real amount charged = itemized subtotal + tax/fees (minus any
        // discounts folded into tax/fees as a negative). This is what the
        // expense should record, not the bare subtotal.
        let total = subtotal + taxAndFees
        guard total > 0 else { throw RepositoryError.notFound }

        // Dominant-by-amount category becomes the expense's headline
        // category (icon shown in lists, used by reports). Falls back to
        // the user-picked category if line items have no categories.
        let topCategory: ExpenseCategory = {
            var totals: [ExpenseCategory: Decimal] = [:]
            for li in lineItems {
                guard let cat = li.category else { continue }
                totals[cat, default: 0] += li.amount
            }
            return totals.max(by: { $0.value < $1.value })?.key ?? category
        }()

        let splitRule = Self.makeSplitRule(
            lineItems: lineItems,
            activeIDs: activeIDs,
            paidBy: me,
            subtotal: subtotal,
            total: total
        )

        let resolvedDescription = description.isEmpty
            ? (draft.merchant ?? "Receipt")
            : description

        let now = Date()
        let expense = Expense(
            id: UUID(),
            householdID: householdID,
            loggedByUserID: me,
            amount: total,
            currency: "USD",
            category: topCategory,
            description: resolvedDescription,
            merchant: draft.merchant,
            date: date,
            createdAt: now,
            updatedAt: now,
            splitRule: splitRule,
            editHistory: [],
            isSettled: false,
            notes: nil,
            isRecurringInstance: false,
            recurringTemplateID: nil,
            receiptImageData: retention.shouldStoreNewReceipts ? draft.imageData : nil,
            lineItems: lineItems,
            softDeletedAt: nil
        )

        try await expenses.create(expense)

        for item in items {
            guard !item.lineItem.normalizedItemName.isEmpty else { continue }
            let itemCategory = item.lineItem.category ?? topCategory
            switch item.rememberChoice {
            case .justThisTime:
                continue
            case .alwaysShared:
                try? await sharedItemRuleService.upsert(
                    normalizedItemName: item.lineItem.normalizedItemName,
                    ruleType: .alwaysShared,
                    category: itemCategory
                )
            case .alwaysAssignedTo(let uid):
                try? await sharedItemRuleService.upsert(
                    normalizedItemName: item.lineItem.normalizedItemName,
                    ruleType: .alwaysAssignedTo(userID: uid),
                    category: itemCategory
                )
            }
        }

        return expense
    }

    /// Builds the per-Expense split rule from its line items, then scales each
    /// person's share so tax/fees (the gap between `subtotal` and `total`) is
    /// allocated proportionally — everyone pays tax in proportion to what they
    /// bought, and the shares sum to the real amount paid.
    private static func makeSplitRule(
        lineItems: [LineItem],
        activeIDs: [UserID],
        paidBy: UserID,
        subtotal: Decimal,
        total: Decimal
    ) -> SplitRule {
        var shareByUser: [UserID: Decimal] = [:]
        for item in lineItems {
            if let qpu = item.quantityPerUser, !qpu.isEmpty {
                let totalUnits = qpu.values.reduce(0, +)
                if totalUnits > 0 {
                    for (uidString, units) in qpu where units > 0 {
                        guard let uuid = UUID(uuidString: uidString) else { continue }
                        let share = item.amount * Decimal(units) / Decimal(totalUnits)
                        shareByUser[UserID(uuid), default: 0] += share
                    }
                    continue
                }
            }
            let assignees: [UserID]
            if item.assignedToUserIDs.isEmpty {
                assignees = activeIDs
            } else {
                assignees = item.assignedToUserIDs.map(UserID.init)
            }
            guard !assignees.isEmpty else { continue }
            let perAssignee = item.amount / Decimal(assignees.count)
            for user in assignees {
                shareByUser[user, default: 0] += perAssignee
            }
        }

        // Scale subtotal-based shares up (or down) to the real total so tax,
        // fees, and discounts ride along proportionally. Guard subtotal > 0.
        if subtotal > 0, total != subtotal {
            let factor = total / subtotal
            for (user, share) in shareByUser {
                shareByUser[user] = share * factor
            }
        }

        let participantsWithShare = shareByUser.filter { $0.value > 0 }
        let participantIDs = participantsWithShare.keys.map(\.raw)
        let participantValues = participantsWithShare.map {
            ParticipantValue(participantID: $0.key.raw, value: $0.value)
        }

        return SplitRule(
            type: .amounts,
            participantIDs: participantIDs.isEmpty ? [paidBy.raw] : participantIDs,
            participantValues: participantValues,
            paidBy: [PaidByEntry(userID: paidBy.raw, amount: total)],
            participantsAreGroups: false
        )
    }
}

/// One row on the review screen. Wraps a `LineItem` with the matched rule (if
/// any), the user's "remember" choice for this scan, and a flag telling the
/// UI whether the DeepSeek cleanup pass renamed it (so we can offer revert).
struct ReviewItem: Identifiable, Sendable, Hashable {
    var id: UUID { lineItem.id }
    var lineItem: LineItem
    var matchedRule: SharedItemRule?
    var rememberChoice: RememberChoice
    var wasAICleaned: Bool = false
}

/// In-flight scan result, handed from `scan(image:)` to the review screen.
struct ReceiptDraft: Sendable {
    var imageData: Data
    var merchant: String?
    var items: [ReviewItem]
    var parsedTotal: Decimal
    var rawLines: [String]
    /// Set when the cloud scanner failed and we fell back to local OCR, so
    /// the review screen can warn the user that accuracy may be lower.
    var fallbackNotice: String? = nil
    /// Tax as printed on the receipt (0 if none / unknown).
    var tax: Decimal = 0
    /// Discounts / instant savings as a positive number (0 if none).
    var savings: Decimal = 0
}

/// Receipt image compression. Bigger than avatars because users need to read
/// the receipt back, but bounded so Core Data stays manageable.
enum ReceiptImage {
    static let maxDimension: CGFloat = 1400
    static let jpegQuality: CGFloat = 0.6

    static func processed(from image: UIImage) -> Data? {
        let resized = image.aspectFitted(to: maxDimension)
        return resized.jpegData(compressionQuality: jpegQuality)
    }
}

private extension UIImage {
    func aspectFitted(to maxDim: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        if longest <= maxDim { return self }
        let scale = maxDim / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
