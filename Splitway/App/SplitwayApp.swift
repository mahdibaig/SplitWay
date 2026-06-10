import SwiftUI

@main
struct SplitwayApp: App {
    // Needed for the CloudKit share-acceptance callback (UIKit-only API).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var services = ServiceContainer.live()
    @StateObject private var shareInbox = ShareAcceptanceInbox.shared
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(services)
                .environmentObject(shareInbox)
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
                .environmentObject(services.subscriptionService)
                .environmentObject(services.receiptRetentionService)
                .environmentObject(services.cloudKitSharingService)
                .onChange(of: shareInbox.token) { _, token in
                    guard token != nil, let metadata = shareInbox.metadata else { return }
                    Task {
                        await services.cloudKitSharingService.acceptShare(metadata: metadata)
                        shareInbox.clear()
                    }
                }
                .tint(.brand)
                .preferredColorScheme(
                    AppearanceMode(rawValue: appearanceRaw)?.colorScheme
                )
        }
    }
}
