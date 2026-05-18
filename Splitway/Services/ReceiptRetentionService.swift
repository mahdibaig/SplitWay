import Foundation
import SwiftUI

/// Owns the receipt retention policy. Per HANDOFF.md P1/4.1.
///
/// For the household beta we purge at app launch rather than via
/// BGTaskScheduler: it needs no background entitlement, is deterministic,
/// and runs often enough (every cold start). A background task is a later
/// enhancement, not a launch blocker.
@MainActor
final class ReceiptRetentionService: ObservableObject {

    @AppStorage(RetentionPolicy.storageKey) private var policyRaw = RetentionPolicy.forever.rawValue

    private let expenses: ExpenseRepository

    init(expenses: ExpenseRepository) {
        self.expenses = expenses
    }

    var policy: RetentionPolicy {
        get { RetentionPolicy(rawValue: policyRaw) ?? .forever }
        set { policyRaw = newValue.rawValue }
    }

    /// Whether a freshly scanned receipt image should be persisted at all.
    /// `.never` keeps the line items but drops the photo.
    var shouldStoreNewReceipts: Bool {
        policy != .never
    }

    /// Run on launch. Drops receipt images that have aged past the policy.
    /// `.never` also sweeps any images that exist from before the policy
    /// changed, so flipping to "don't store" cleans up retroactively too.
    func purgeIfNeeded(now: Date = Date()) async {
        let p = policy
        if p == .never {
            // Purge everything: cutoff in the far future catches all dated rows.
            do {
                let n = try await expenses.purgeReceiptImages(olderThan: now.addingTimeInterval(86_400 * 365 * 100))
                if n > 0 { AppLog.data.info("Retention(never): purged \(n, privacy: .public) receipt image(s)") }
            } catch {
                AppLog.data.error("Retention purge failed: \(error.localizedDescription, privacy: .public)")
            }
            return
        }
        guard let cutoff = p.cutoff(now: now) else { return }  // forever -> no-op
        do {
            let n = try await expenses.purgeReceiptImages(olderThan: cutoff)
            if n > 0 { AppLog.data.info("Retention(\(p.rawValue, privacy: .public)): purged \(n, privacy: .public) receipt image(s)") }
        } catch {
            AppLog.data.error("Retention purge failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
