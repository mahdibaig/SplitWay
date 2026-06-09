import Foundation

/// Distributes an Expense (or a user's share of it) across categories using
/// per-line-item categories when available. Used by Reports, Budgets, and
/// the assistant context so a Costco trip with $177 groceries + $40
/// household supplies lands in the correct buckets, not all under the
/// expense's single headline category.
///
/// The `contribution` parameter is the amount we want to distribute — for
/// "household" scope this is `expense.amount`, for "just me" scope it's
/// the user's share per the split rule. Either way the distribution is
/// proportional to each line item's amount.
extension Expense {

    /// Returns a mapping of category to contribution amount. Whatever the
    /// caller passes as `contribution` is fully distributed (the totals
    /// always sum to `contribution`, modulo rounding).
    ///
    /// - If the expense has line items totalling > 0, each line item's
    ///   amount is treated as its share of `contribution`. Line items
    ///   without an explicit category fall back to the expense's headline
    ///   category.
    /// - Otherwise the entire `contribution` goes to the headline category.
    func categoryDistribution(of contribution: Decimal) -> [ExpenseCategory: Decimal] {
        guard contribution > 0 else { return [:] }
        let lineTotal = lineItems.reduce(Decimal.zero) { $0 + $1.amount }
        guard lineTotal > 0 else {
            return [category: contribution]
        }

        var out: [ExpenseCategory: Decimal] = [:]
        for li in lineItems where li.amount > 0 {
            let ratio = li.amount / lineTotal
            let share = contribution * ratio
            let cat = li.category ?? category
            out[cat, default: 0] += share
        }
        return out
    }
}
