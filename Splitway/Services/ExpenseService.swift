import Foundation

@MainActor
final class ExpenseService: ObservableObject {

    private let expenses: ExpenseRepository
    private let householdService: HouseholdService

    @Published private(set) var expensesList: [Expense] = []

    /// Fires after an expense is saved. Carries the *previous* per-category
    /// budget progress snapshot so subscribers can detect threshold crossings.
    /// Wired by `ServiceContainer` to drive budget alert notifications.
    var onExpenseSaved: ((_ previousProgress: [BudgetProgress], _ savedExpense: Expense) async -> Void)?
    var budgetProgressSnapshot: (() -> [BudgetProgress])?

    init(expenses: ExpenseRepository, householdService: HouseholdService) {
        self.expenses = expenses
        self.householdService = householdService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            expensesList = []
            return
        }
        do {
            expensesList = try await expenses.fetchAll(householdID: id, includeSoftDeleted: false)
        } catch {
            AppLog.data.error("Expense refresh failed: \(error.localizedDescription, privacy: .public)")
            expensesList = []
        }
    }

    func add(
        amount: Decimal,
        category: ExpenseCategory,
        description: String,
        merchant: String?,
        date: Date,
        splitRule: SplitRule,
        notes: String?
    ) async throws {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        if let validationError = SplitResolver.validate(splitRule, total: amount) {
            throw validationError
        }

        let now = Date()
        let expense = Expense(
            id: UUID(),
            householdID: householdID,
            loggedByUserID: me,
            amount: amount,
            currency: "USD",
            category: category,
            description: description,
            merchant: merchant,
            date: date,
            createdAt: now,
            updatedAt: now,
            splitRule: splitRule,
            editHistory: [],
            isSettled: false,
            notes: notes,
            isRecurringInstance: false,
            recurringTemplateID: nil,
            receiptImageData: nil,
            lineItems: [],
            softDeletedAt: nil
        )

        let previousProgress = budgetProgressSnapshot?() ?? []
        try await expenses.create(expense)
        await refresh()
        await onExpenseSaved?(previousProgress, expense)
        AppLog.data.info("Logged expense category=\(expense.category.rawValue, privacy: .public)")
    }

    func softDelete(id: UUID) async throws {
        try await expenses.softDelete(id: id)
        await refresh()
    }
}
