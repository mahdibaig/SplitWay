import Foundation

@MainActor
final class BudgetService: ObservableObject {

    private let budgets: BudgetRepository
    private let expenseService: ExpenseService
    private let householdService: HouseholdService

    @Published private(set) var budgetsList: [Budget] = []

    init(budgets: BudgetRepository, expenseService: ExpenseService, householdService: HouseholdService) {
        self.budgets = budgets
        self.expenseService = expenseService
        self.householdService = householdService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            budgetsList = []
            return
        }
        do {
            budgetsList = try await budgets.fetchAll(householdID: id)
        } catch {
            AppLog.data.error("Budget refresh failed: \(error.localizedDescription, privacy: .public)")
            budgetsList = []
        }
    }

    @discardableResult
    func setBudget(category: ExpenseCategory, monthlyLimit: Decimal) async throws -> Budget {
        guard let id = householdService.currentHousehold?.id else { throw RepositoryError.notFound }
        let budget = try await budgets.upsert(
            category: category,
            monthlyLimit: monthlyLimit,
            householdID: id
        )
        await refresh()
        return budget
    }

    func deleteBudget(id: UUID) async throws {
        try await budgets.delete(id: id)
        await refresh()
    }

    // MARK: - Computed progress

    /// Per-category budget progress for the given month, sorted by spend %.
    func progress(for month: Date) -> [BudgetProgress] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: month) else { return [] }

        let activeExpenses = expenseService.expensesList
            .filter { $0.softDeletedAt == nil }
            .filter { interval.contains($0.date) }

        return budgetsList.map { budget in
            let spent = activeExpenses
                .filter { $0.category == budget.category }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return BudgetProgress(
                category: budget.category,
                monthlyLimit: budget.monthlyLimit,
                spent: spent
            )
        }
    }

    /// Total monthly limit and total spend across all budgeted categories.
    func monthlyTotals(for month: Date) -> (limit: Decimal, spent: Decimal) {
        let progresses = progress(for: month)
        let limit = progresses.reduce(Decimal.zero) { $0 + $1.monthlyLimit }
        let spent = progresses.reduce(Decimal.zero) { $0 + $1.spent }
        return (limit, spent)
    }
}
