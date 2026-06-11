import Foundation

/// Composition root. Holds every long-lived service so views can grab them
/// through `@EnvironmentObject` without each view knowing how to construct them.
/// Swap implementations here for previews and tests.
@MainActor
final class ServiceContainer: ObservableObject {

    let persistence: PersistenceController

    // Repositories
    let householdRepository: HouseholdRepository
    let userRepository: UserRepository
    let groupRepository: GroupRepository
    let expenseRepository: ExpenseRepository
    let settlementRepository: SettlementRepository
    let budgetRepository: BudgetRepository
    let recurringRepository: RecurringRepository
    let sharedItemRuleRepository: SharedItemRuleRepository
    let chatRepository: ChatRepository

    // Services
    let accounts: CloudKitAccountService
    let householdService: HouseholdService
    let membersService: MembersService
    let groupService: GroupService
    let expenseService: ExpenseService
    let settlementService: SettlementService
    let budgetService: BudgetService
    let recurringService: RecurringService
    let notificationService: NotificationService
    let notificationPreferences: NotificationPreferences
    let receiptScanService: ReceiptScanService
    let sharedItemRuleService: SharedItemRuleService
    let assistantPreferences: AssistantPreferences
    let assistantService: AssistantService
    let receiptCleanupService: ReceiptCleanupService
    let receiptRetentionService: ReceiptRetentionService
    let splitwiseImportService: SplitwiseImportService
    let expenseExportService: ExpenseExportService
    let subscriptionService: SubscriptionService
    let cloudKitSharingService: CloudKitSharingService
    let freeScanQuota: FreeScanQuota

    init(persistence: PersistenceController, accounts: CloudKitAccountService) {
        self.persistence = persistence
        self.accounts = accounts

        let households = CoreDataHouseholdRepository(persistence: persistence)
        let users = CoreDataUserRepository(persistence: persistence)
        let groupsRepo = CoreDataGroupRepository(persistence: persistence)
        let expensesRepo = CoreDataExpenseRepository(persistence: persistence)
        let settlementsRepo = CoreDataSettlementRepository(persistence: persistence)
        let budgetsRepo = CoreDataBudgetRepository(persistence: persistence)
        let recurringRepo = CoreDataRecurringRepository(persistence: persistence)
        let sharedItemRuleRepo = CoreDataSharedItemRuleRepository(persistence: persistence)
        let chatRepo = CoreDataChatRepository(persistence: persistence)
        self.householdRepository = households
        self.userRepository = users
        self.groupRepository = groupsRepo
        self.expenseRepository = expensesRepo
        self.settlementRepository = settlementsRepo
        self.budgetRepository = budgetsRepo
        self.recurringRepository = recurringRepo
        self.sharedItemRuleRepository = sharedItemRuleRepo
        self.chatRepository = chatRepo

        let householdService = HouseholdService(
            households: households,
            users: users,
            accounts: accounts
        )
        self.householdService = householdService

        self.membersService = MembersService(
            users: users,
            householdService: householdService
        )

        self.groupService = GroupService(
            groups: groupsRepo,
            householdService: householdService
        )

        self.expenseService = ExpenseService(
            expenses: expensesRepo,
            householdService: householdService
        )

        let settlementService = SettlementService(
            settlements: settlementsRepo,
            householdService: householdService
        )
        self.settlementService = settlementService

        self.budgetService = BudgetService(
            budgets: budgetsRepo,
            expenseService: expenseService,
            householdService: householdService
        )

        let recurringService = RecurringService(
            recurring: recurringRepo,
            expenseRepository: expensesRepo,
            householdService: householdService,
            membersService: membersService
        )
        self.recurringService = recurringService

        let notificationService = NotificationService()
        let notificationPreferences = NotificationPreferences()
        self.notificationService = notificationService
        self.notificationPreferences = notificationPreferences

        let sharedItemRuleService = SharedItemRuleService(
            rules: sharedItemRuleRepo,
            householdService: householdService
        )
        self.sharedItemRuleService = sharedItemRuleService

        let assistantPreferences = AssistantPreferences()
        self.assistantPreferences = assistantPreferences

        let receiptCleanupService = ReceiptCleanupService(preferences: assistantPreferences)
        self.receiptCleanupService = receiptCleanupService

        let receiptRetentionService = ReceiptRetentionService(expenses: expensesRepo)
        self.receiptRetentionService = receiptRetentionService

        self.receiptScanService = ReceiptScanService(
            expenses: expensesRepo,
            householdService: householdService,
            sharedItemRuleService: sharedItemRuleService,
            cleanupService: receiptCleanupService,
            retention: receiptRetentionService
        )

        self.splitwiseImportService = SplitwiseImportService(
            expenses: expensesRepo,
            householdService: householdService,
            membersService: membersService,
            expenseService: expenseService
        )

        self.expenseExportService = ExpenseExportService(
            expenseService: expenseService,
            membersService: membersService,
            householdService: householdService
        )

        self.subscriptionService = SubscriptionService()

        self.cloudKitSharingService = CloudKitSharingService(
            persistence: persistence,
            householdService: householdService
        )

        self.freeScanQuota = FreeScanQuota()

        self.assistantService = AssistantService(
            chatRepository: chatRepo,
            householdService: householdService,
            preferences: assistantPreferences,
            contextBuilder: AssistantContextBuilder(
                householdService: householdService,
                membersService: membersService,
                expenseService: expenseService,
                settlementService: settlementService,
                budgetService: budgetService,
                recurringService: recurringService
            )
        )

        // Wire budget alerts: after an expense lands, compare progress before/after.
        expenseService.onExpenseSaved = { [weak budgetService, weak notificationService] previousProgress, _ in
            guard
                let budgetService,
                let notificationService
            else { return }
            for after in budgetService.progress(for: Date()) {
                let before = previousProgress.first { $0.category == after.category }
                await notificationService.fireBudgetAlertIfCrossed(
                    before: before,
                    after: after,
                    enabled: notificationPreferences.budgetAlertsEnabled,
                    alreadySent: { notificationPreferences.hasSent(key: $0) },
                    markSent: { notificationPreferences.markSent(key: $0) }
                )
            }
        }

        // Wire recurring schedule updates: after CRUD, reschedule all reminders.
        recurringService.onTemplatesChanged = { [weak notificationService] templates in
            guard let notificationService else { return }
            await notificationService.rescheduleRecurringReminders(
                templates,
                enabled: notificationPreferences.recurringRemindersEnabled
            )
        }
    }

    #if DEBUG
    /// Dev-only: adds a fake housemate so multi-person flows can be tested
    /// before CloudKit sharing is wired up. Cycles through a preset name list,
    /// then falls back to "Test Member N".
    func addTestMember() async {
        guard let householdID = householdService.currentHousehold?.id else { return }
        await membersService.refresh()

        let preset: [(name: String, emoji: String)] = [
            ("Sarah",   "🌿"),
            ("Ahmad",   "🦊"),
            ("Hamza",   "😎"),
            ("Aisha",   "⭐"),
            ("Layla",   "🐱"),
            ("Omar",    "🐻"),
            ("Yusuf",   "🐼"),
            ("Maryam",  "🌸")
        ]

        let existing = Set(membersService.members.map { $0.displayName.lowercased() })
        let next = preset.first { !existing.contains($0.name.lowercased()) }
        let name = next?.name ?? "Test Member \(membersService.members.count)"
        let emoji = next?.emoji ?? "🙂"

        do {
            _ = try await userRepository.createMember(
                in: householdID,
                displayName: name,
                avatarEmoji: emoji,
                avatarImageData: nil,
                appleUserID: nil
            )
            await membersService.refresh()
            AppLog.data.info("Added test member \(name, privacy: .public)")
        } catch {
            AppLog.data.error("Add test member failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    #endif

    /// Dev-only: wipes the local store and refreshes every cached service.
    /// AppCoordinator re-routes to onboarding once `currentHousehold` clears.
    func resetAppData() async {
        do {
            try await persistence.eraseAllData()
        } catch {
            AppLog.data.error("Reset app data failed: \(error.localizedDescription, privacy: .public)")
        }
        receiptCleanupService.resetCache()
        // Clear the one-time onboarding gates so the full flow (consent +
        // Pro trial page) replays after a reset.
        UserDefaults.standard.removeObject(forKey: "onboarding.assistantConsentSeen")
        UserDefaults.standard.removeObject(forKey: "onboarding.proTrialSeen")
        #if DEBUG
        // The dev Pro override makes isPro true, which auto-skips the
        // onboarding trial page. A full reset should put the app back in
        // the true first-launch state, so turn it off too.
        subscriptionService.devUnlockPro = false
        #endif
        await householdService.refresh()
        await membersService.refresh()
        await groupService.refresh()
        await expenseService.refresh()
        await settlementService.refresh()
        await budgetService.refresh()
        await recurringService.refresh()
        await sharedItemRuleService.refresh()
    }

    static func live() -> ServiceContainer {
        ServiceContainer(
            persistence: PersistenceController.shared,
            accounts: LiveCloudKitAccountService()
        )
    }

    static func preview() -> ServiceContainer {
        ServiceContainer(
            persistence: PersistenceController(inMemory: true),
            accounts: StubCloudKitAccountService(status: .available, recordID: "preview-user")
        )
    }
}
