import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var notificationPreferences: NotificationPreferences
    @EnvironmentObject private var recurringService: RecurringService

    var body: some View {
        List {
            Section {
                statusRow
            } footer: {
                Text(statusFooter)
            }

            Section {
                Toggle("Budget alerts", isOn: $notificationPreferences.budgetAlertsEnabled)
                Toggle("Recurring bill reminders", isOn: Binding(
                    get: { notificationPreferences.recurringRemindersEnabled },
                    set: { newValue in
                        notificationPreferences.recurringRemindersEnabled = newValue
                        Task {
                            await notificationService.rescheduleRecurringReminders(
                                recurringService.templates,
                                enabled: newValue
                            )
                        }
                    }
                ))
            } header: {
                Text("What to send")
            } footer: {
                Text("Budget alerts fire at 80% and 100% spent for each category, once per month. Recurring reminders fire at 9 a.m. on the day each bill is due.")
            }

            Section {
                Text("Coming later: balance reminders (weekly or monthly), monthly summary, and alerts when housemates log expenses.")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await notificationService.refreshAuthStatus() }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch notificationService.authStatus {
        case .notDetermined:
            Button("Allow notifications") {
                Task {
                    _ = await notificationService.requestAuthorization()
                    if notificationService.authStatus == .authorized {
                        await notificationService.rescheduleRecurringReminders(
                            recurringService.templates,
                            enabled: notificationPreferences.recurringRemindersEnabled
                        )
                    }
                }
            }
        case .denied:
            HStack {
                Image(systemName: "bell.slash")
                Text("Disabled in iOS Settings")
                Spacer()
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        case .authorized, .provisional, .ephemeral:
            HStack {
                Image(systemName: "bell.badge").foregroundStyle(Color.success)
                Text("Enabled")
                Spacer()
                Text(label(for: notificationService.authStatus))
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
        }
    }

    private var statusFooter: String {
        switch notificationService.authStatus {
        case .notDetermined:
            return "Splitway can buzz you about budgets and recurring bills. All local, no servers."
        case .denied:
            return "iOS is blocking notifications. Open Settings, then turn them on for Splitway."
        case .authorized, .provisional, .ephemeral:
            return "All scheduled locally on this device."
        }
    }

    private func label(for status: NotificationService.AuthStatus) -> String {
        switch status {
        case .authorized:   return "Full"
        case .provisional:  return "Quiet"
        case .ephemeral:    return "Session"
        default:            return ""
        }
    }
}
