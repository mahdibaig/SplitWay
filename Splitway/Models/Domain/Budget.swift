import Foundation

struct Budget: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var category: ExpenseCategory
    var monthlyLimit: Decimal
    var currency: String
    var createdAt: Date
    var updatedAt: Date
}

/// Snapshot of a budget vs actual spend in a given month. Pure value type so
/// the UI can render it without re-reading the underlying expense list.
struct BudgetProgress: Identifiable, Hashable, Sendable {
    let category: ExpenseCategory
    let monthlyLimit: Decimal
    let spent: Decimal

    var id: String { category.rawValue }
    var remaining: Decimal { monthlyLimit - spent }
    var isOver: Bool { spent > monthlyLimit }

    /// 0.0 to potentially > 1.0 if over budget. UI clamps for the bar.
    var fraction: Double {
        guard monthlyLimit > 0 else { return 0 }
        let s = NSDecimalNumber(decimal: spent).doubleValue
        let l = NSDecimalNumber(decimal: monthlyLimit).doubleValue
        return max(0, s / l)
    }

    /// Cap at 1.0 for visual progress bar width.
    var displayFraction: Double { min(1.0, fraction) }
}
