import Foundation
import SwiftUI

@MainActor
final class ExpensesListViewModel: ObservableObject {

    @Published var monthFilter: Date = Date()
    @Published var categoryFilter: ExpenseCategory? = nil
    @Published var personFilter: UserID? = nil

    private let expenseService: ExpenseService

    init(expenseService: ExpenseService) {
        self.expenseService = expenseService
    }

    /// Expenses filtered by the current pills, sorted by date desc.
    var filtered: [Expense] {
        let cal = Calendar.current
        let monthInterval = cal.dateInterval(of: .month, for: monthFilter)
        return expenseService.expensesList.filter { e in
            if let interval = monthInterval, !interval.contains(e.date) { return false }
            if let c = categoryFilter, e.category != c { return false }
            if let p = personFilter {
                let participants = Set(e.splitRule.participantIDs.map(UserID.init))
                let payers = Set(e.splitRule.paidBy.map { UserID($0.userID) })
                if !participants.contains(p), !payers.contains(p) { return false }
            }
            return true
        }
    }

    struct Section: Identifiable {
        let id: String
        let title: String
        let expenses: [Expense]
    }

    /// Date-grouped sections like "Today" / "Yesterday" / "Nov 8".
    var sections: [Section] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { day, items in
                let title: String
                if day == today { title = "Today" }
                else if day == yesterday { title = "Yesterday" }
                else { title = day.formatted(.dateTime.month(.abbreviated).day()) }
                return Section(
                    id: day.ISO8601Format(),
                    title: title,
                    expenses: items.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { lhs, rhs in
                (lhs.expenses.first?.date ?? .distantPast) > (rhs.expenses.first?.date ?? .distantPast)
            }
    }

    func incrementMonth(by delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: monthFilter) {
            monthFilter = next
        }
    }

    var monthLabel: String {
        monthFilter.formatted(.dateTime.month(.wide).year())
    }
}
