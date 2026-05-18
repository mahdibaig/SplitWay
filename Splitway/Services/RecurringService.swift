import Foundation

@MainActor
final class RecurringService: ObservableObject {

    private let recurring: RecurringRepository
    private let expenseRepository: ExpenseRepository
    private let householdService: HouseholdService
    private let membersService: MembersService

    @Published private(set) var templates: [RecurringTemplate] = []
    /// Variable-amount templates that are due and need user input. Populated
    /// after `processDue()`. The Home banner reads from this.
    @Published private(set) var pendingVariable: [RecurringTemplate] = []

    /// Fires whenever the template list changes (CRUD or processDue logged
    /// some). Wired by `ServiceContainer` to drive notification rescheduling.
    var onTemplatesChanged: (([RecurringTemplate]) async -> Void)?

    init(
        recurring: RecurringRepository,
        expenseRepository: ExpenseRepository,
        householdService: HouseholdService,
        membersService: MembersService
    ) {
        self.recurring = recurring
        self.expenseRepository = expenseRepository
        self.householdService = householdService
        self.membersService = membersService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            templates = []
            pendingVariable = []
            await onTemplatesChanged?([])
            return
        }
        do {
            templates = try await recurring.fetchAll(householdID: id)
            pendingVariable = templates.filter { $0.isDue && $0.isVariableAmount }
            await onTemplatesChanged?(templates)
        } catch {
            AppLog.data.error("Recurring refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    @discardableResult
    func create(
        description: String,
        category: ExpenseCategory,
        amount: Decimal?,
        isVariableAmount: Bool,
        dayOfMonth: Int,
        isActive: Bool
    ) async throws -> RecurringTemplate {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        let now = Date()
        let template = RecurringTemplate(
            id: UUID(),
            householdID: householdID,
            description: description,
            category: category,
            amount: isVariableAmount ? nil : amount,
            isVariableAmount: isVariableAmount,
            dayOfMonth: dayOfMonth,
            nextOccurrence: RecurrenceCalendar.initialOccurrence(dayOfMonth: dayOfMonth, now: now),
            isActive: isActive,
            createdByUserID: me,
            createdAt: now,
            updatedAt: now
        )
        let saved = try await recurring.create(template)
        await refresh()
        return saved
    }

    func update(_ template: RecurringTemplate) async throws {
        var updated = template
        updated.updatedAt = Date()
        try await recurring.update(updated)
        await refresh()
    }

    func delete(id: UUID) async throws {
        try await recurring.delete(id: id)
        await refresh()
    }

    // MARK: - Due processing

    /// Run on app launch. Fixed-amount templates get auto-logged silently.
    /// Variable ones are surfaced via `pendingVariable` for the UI to prompt.
    /// Catches up if multiple months have passed (logs each cycle separately).
    func processDue() async {
        await refresh()
        var loggedCount = 0

        for template in templates where template.isActive {
            var cursor = template
            // Loop in case more than one occurrence has elapsed (user offline for months).
            while cursor.isDue {
                if cursor.isVariableAmount {
                    // Stop here so the user can enter an amount via prompt.
                    break
                }
                guard let amount = cursor.amount, amount > 0 else {
                    // Misconfigured fixed template, skip without bumping.
                    break
                }
                do {
                    try await logExpense(from: cursor, amount: amount, occurrenceDate: cursor.nextOccurrence)
                    cursor.nextOccurrence = RecurrenceCalendar.nextOccurrence(
                        after: cursor.nextOccurrence,
                        dayOfMonth: cursor.dayOfMonth
                    )
                    cursor.updatedAt = Date()
                    try await recurring.update(cursor)
                    loggedCount += 1
                } catch {
                    AppLog.data.error("Auto-log failed: \(error.localizedDescription, privacy: .public)")
                    break
                }
            }
        }

        await refresh()
        if loggedCount > 0 {
            AppLog.data.info("Auto-logged \(loggedCount, privacy: .public) recurring expense(s)")
        }
    }

    /// Called when the user fills in an amount for a variable template on the
    /// "bills due" prompt.
    func logVariable(_ template: RecurringTemplate, amount: Decimal) async throws {
        guard template.isVariableAmount else { return }
        try await logExpense(from: template, amount: amount, occurrenceDate: template.nextOccurrence)
        var bumped = template
        bumped.nextOccurrence = RecurrenceCalendar.nextOccurrence(
            after: template.nextOccurrence,
            dayOfMonth: template.dayOfMonth
        )
        bumped.updatedAt = Date()
        try await recurring.update(bumped)
        await refresh()
    }

    // MARK: - Internals

    private func logExpense(from template: RecurringTemplate, amount: Decimal, occurrenceDate: Date) async throws {
        guard
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        await membersService.refresh()
        let activeMembers = membersService.members.filter { !$0.isArchived }
        let participantIDs = activeMembers.map(\.id.raw)
        let splitRule = SplitRule(
            type: .equal,
            participantIDs: participantIDs.isEmpty ? [me.raw] : participantIDs,
            participantValues: [],
            paidBy: [PaidByEntry(userID: me.raw, amount: amount)],
            participantsAreGroups: false
        )

        let now = Date()
        let expense = Expense(
            id: UUID(),
            householdID: template.householdID,
            loggedByUserID: me,
            amount: amount,
            currency: "USD",
            category: template.category,
            description: template.description,
            merchant: nil,
            date: occurrenceDate,
            createdAt: now,
            updatedAt: now,
            splitRule: splitRule,
            editHistory: [],
            isSettled: false,
            notes: "Auto-logged from recurring template",
            isRecurringInstance: true,
            recurringTemplateID: template.id,
            receiptImageData: nil,
            lineItems: [],
            softDeletedAt: nil
        )
        try await expenseRepository.create(expense)
    }
}
