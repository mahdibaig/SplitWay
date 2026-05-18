import Foundation

/// Per-spec "shared-items learning" rule. Lets the app remember decisions
/// like "milk is always shared" or "face wash is always Hamza's" so future
/// receipt scans pre-fill assignments instead of asking again.
struct SharedItemRule: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var normalizedItemName: String
    var category: ExpenseCategory?
    var ruleType: SharedItemRuleType
    /// Count of confirmations (how many times this rule has been used).
    /// Higher = more confident; useful for resolving conflicts later.
    var confidence: Int
    var lastUsedAt: Date
    var createdAt: Date
}

enum SharedItemRuleType: Hashable, Sendable {
    case alwaysShared
    case alwaysAssignedTo(userID: UUID)

    var assignedUserID: UUID? {
        if case .alwaysAssignedTo(let id) = self { return id }
        return nil
    }

    var isAlwaysShared: Bool {
        if case .alwaysShared = self { return true }
        return false
    }
}

/// "Remember this choice?" options on the assignment sheet. Stored on the
/// in-flight line item; consumed by `ReceiptScanService.saveExpense` to
/// upsert rules in batch.
enum RememberChoice: Sendable, Hashable {
    case justThisTime
    case alwaysShared
    case alwaysAssignedTo(userID: UUID)
}
