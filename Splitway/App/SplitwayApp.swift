import SwiftUI

@main
struct SplitwayApp: App {
    @StateObject private var services = ServiceContainer.live()
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(services)
                .environmentObject(services.householdService)
                .environmentObject(services.membersService)
                .environmentObject(services.groupService)
                .environmentObject(services.expenseService)
                .environmentObject(services.settlementService)
                .environmentObject(services.budgetService)
                .environmentObject(services.recurringService)
                .environmentObject(services.notificationService)
                .environmentObject(services.notificationPreferences)
                .environmentObject(services.receiptScanService)
                .environmentObject(services.sharedItemRuleService)
                .environmentObject(services.assistantPreferences)
                .environmentObject(services.assistantService)
                .tint(.brand)
                .preferredColorScheme(
                    AppearanceMode(rawValue: appearanceRaw)?.colorScheme
                )
        }
    }
}
