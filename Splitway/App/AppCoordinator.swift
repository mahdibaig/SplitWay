import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var assistantPreferences: AssistantPreferences
    @EnvironmentObject private var sharing: CloudKitSharingService

    @State private var hasLoaded = false
    @AppStorage("onboarding.assistantConsentSeen") private var consentSeen: Bool = false
    @AppStorage("onboarding.proTrialSeen") private var proTrialSeen: Bool = false

    var body: some View {
        Group {
            if !hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bg)
            } else if householdService.currentHousehold == nil {
                OnboardingFlow()
            } else if !consentSeen {
                AssistantConsentView()
            } else if !proTrialSeen && !services.subscriptionService.isPro {
                ProTrialView()
                    .environmentObject(services.subscriptionService)
            } else {
                MainTabs()
            }
        }
        .task {
            await householdService.refresh()
            await householdService.refreshAccountStatus()
            await services.notificationService.refreshAuthStatus()
            services.notificationPreferences.purgeStaleKeys(currentMonthKey: monthKey())
            if householdService.currentHousehold != nil {
                await services.receiptRetentionService.purgeIfNeeded()
                await services.recurringService.processDue()
                await services.expenseService.refresh()
                await services.budgetService.refresh()
                // Wire snapshot AFTER budget is hydrated so alerts see real data.
                services.expenseService.budgetProgressSnapshot = { [weak budgetService = services.budgetService] in
                    budgetService?.progress(for: Date()) ?? []
                }
                // Migration: existing users who already enabled the assistant
                // implicitly consented when they entered their API key.
                if !consentSeen && assistantPreferences.enabled {
                    consentSeen = true
                }
            }
            hasLoaded = true
            AppLog.lifecycle.info("App launched. iCloud=\(String(describing: householdService.iCloudStatus), privacy: .public)")
        }
        .alert("Household invite", isPresented: Binding(
            get: { sharing.lastJoinMessage != nil },
            set: { if !$0 { sharing.lastJoinMessage = nil } }
        )) {
            Button("OK", role: .cancel) { sharing.lastJoinMessage = nil }
        } message: {
            Text(sharing.lastJoinMessage ?? "")
        }
    }

    private func monthKey() -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month], from: Date())
        return "\(c.year ?? 0)-\(String(format: "%02d", c.month ?? 0))"
    }
}
