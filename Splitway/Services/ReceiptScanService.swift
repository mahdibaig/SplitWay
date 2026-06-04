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

    /// Compresses the image, runs Vision OCR, parses lines, batches the items
    /// through the LLM for name cleanup (one call per scan, cached), applies
    /// any matching `SharedItemRule`s to pre-fill assignments, returns a draft.
    func scan(image: UIImage) async -> ReceiptDraft {
        await sharedItemRuleService.refresh()
        let processed = ReceiptImage.processed(from: image) ?? Data()
        let lines = await VisionOCRService.recognizeText(in: image)
        let parsed = LineItemParser.parse(lines: lines)

        // AI cleanup pass on the raw line items, with caching.
        let (cleanedItems, aiCleanedIDs) = await cleanupService.cleanup(items: parsed.items)

        // Apply rule pre-fill per item AFTER cleanup so SharedItemRule lookups
        // hit consistently using the cleaned display name.
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

        let total: Decimal = parsed.total
            ?? parsed.items.reduce(.zero) { $0 + $1.amount }

        return ReceiptDraft(
            imageData: processed,
            merchant: parsed.merchant,
            items: enrichedItems,
            parsedTotal: total,
            rawLines: lines.map(\.text)
        )
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Saves the reviewed receipt as one or more real Expenses (one per
    /// distinct line-item category, so a Costco trip with food + paper goods
    /// + medicine lands cleanly in reports). Falls back to a single Expense
    /// in the common case where every line item resolves to the same
    /// category. Also upserts any `SharedItemRule`s the user asked to
    /// remember.
    @discardableResult
    func saveExpense(
        from draft: ReceiptDraft,
        items: [ReviewItem],
        category: ExpenseCategory,
        description: String,
        date: Date,
        activeMembers: [HouseholdMember]
    ) async throws -> [Expense] {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        let activeIDs = activeMembers.filter { !$0.isArchived }.map(\.id)
        guard !items.isEmpty else { return [] }

        // Bucket items by their per-item category, falling back to the
        // expense-level category for any item the user/AI left unset.
        let buckets: [(category: ExpenseCategory, items: [ReviewItem])] = {
            var byCat: [ExpenseCategory: [ReviewItem]] = [:]
            var order: [ExpenseCategory] = []
            for item in items {
                let cat = item.lineItem.category ?? category
                if byCat[cat] == nil { order.append(cat) }
                byCat[cat, default: []].append(item)
            }
            return order.map { ($0, byCat[$0] ?? []) }
        }()

        let storeImage = retention.shouldStoreNewReceipts
        var created: [Expense] = []
        let now = Date()

        for bucket in buckets {
            let bucketItems = bucket.items
            let lineItems = bucketItems.map { item -> LineItem in
                var li = item.lineItem
                // Make the per-bucket expense self-consistent: every line
                // item it contains carries the bucket's category.
                li.category = bucket.category
                return li
            }
            let total = lineItems.reduce(Decimal.zero) { $0 + $1.amount }
            guard total > 0 else { continue }

            let splitRule = Self.makeSplitRule(
                lineItems: lineItems,
                activeIDs: activeIDs,
                paidBy: me,
                total: total
            )

            // Description is just the merchant (or whatever the user typed).
            // No " · Groceries" suffix — the category icon on each row
            // already tells split-receipt entries apart visually.
            let resolvedDescription = description.isEmpty
                ? (draft.merchant ?? "Receipt")
                : description

            let expense = Expense(
                id: UUID(),
                householdID: householdID,
                loggedByUserID: me,
                amount: total,
                currency: "USD",
                category: bucket.category,
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
                receiptImageData: storeImage ? draft.imageData : nil,
                lineItems: lineItems,
                softDeletedAt: nil
            )

            try await expenses.create(expense)
            created.append(expense)

            // Per-bucket SharedItemRule upserts so future scans pre-fill
            // each known item against the right category.
            for item in bucketItems {
                guard !item.lineItem.normalizedItemName.isEmpty else { continue }
                switch item.rememberChoice {
                case .justThisTime:
                    continue
                case .alwaysShared:
                    try? await sharedItemRuleService.upsert(
                        normalizedItemName: item.lineItem.normalizedItemName,
                        ruleType: .alwaysShared,
                        category: bucket.category
                    )
                case .alwaysAssignedTo(let uid):
                    try? await sharedItemRuleService.upsert(
                        normalizedItemName: item.lineItem.normalizedItemName,
                        ruleType: .alwaysAssignedTo(userID: uid),
                        category: bucket.category
                    )
                }
            }
        }

        return created
    }

    /// Builds the per-Expense split rule from its own line items, mirroring
    /// the old monolithic logic but limited to this bucket.
    private static func makeSplitRule(
        lineItems: [LineItem],
        activeIDs: [UserID],
        paidBy: UserID,
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
