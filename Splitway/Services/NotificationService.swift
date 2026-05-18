import Foundation
import UserNotifications

/// Local notification scheduling. No server, no entitlement beyond what the
/// app already has, no push tokens. Permission is requested on demand from
/// the Notifications screen in Settings.
@MainActor
final class NotificationService: ObservableObject {

    /// Mirrors `UNAuthorizationStatus` so views don't import UserNotifications.
    enum AuthStatus: Sendable, Equatable {
        case notDetermined
        case denied
        case authorized
        case provisional
        case ephemeral
    }

    @Published private(set) var authStatus: AuthStatus = .notDetermined

    /// Stable identifier prefixes so we can cancel/replace cleanly.
    private enum ID {
        static let recurringPrefix = "splitway.recurring."
        static let budgetAlertPrefix = "splitway.budget."
    }

    private let center = UNUserNotificationCenter.current()

    init() {
        Task { await refreshAuthStatus() }
    }

    // MARK: - Permission

    func refreshAuthStatus() async {
        let settings = await center.notificationSettings()
        authStatus = map(settings.authorizationStatus)
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthStatus()
            return granted
        } catch {
            AppLog.lifecycle.error("Notification auth request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func map(_ raw: UNAuthorizationStatus) -> AuthStatus {
        switch raw {
        case .notDetermined: return .notDetermined
        case .denied:        return .denied
        case .authorized:    return .authorized
        case .provisional:   return .provisional
        case .ephemeral:     return .ephemeral
        @unknown default:    return .notDetermined
        }
    }

    // MARK: - Recurring reminders

    /// Replace all scheduled recurring reminders with notifications for the
    /// given active templates. Idempotent: safe to call after every CRUD.
    func rescheduleRecurringReminders(_ templates: [RecurringTemplate], enabled: Bool) async {
        // Cancel all existing recurring-prefix notifications first.
        let pending = await center.pendingNotificationRequests()
        let stale = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(ID.recurringPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        guard enabled, authStatus == .authorized || authStatus == .provisional else { return }

        for template in templates where template.isActive {
            await scheduleRecurringReminder(template)
        }
    }

    private func scheduleRecurringReminder(_ template: RecurringTemplate) async {
        let cal = Calendar(identifier: .gregorian)
        // Fire at 9am on the day of nextOccurrence.
        var comps = cal.dateComponents([.year, .month, .day], from: template.nextOccurrence)
        comps.hour = 9; comps.minute = 0

        guard let fireDate = cal.date(from: comps), fireDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )

        let content = UNMutableNotificationContent()
        content.title = template.description
        if template.isVariableAmount {
            content.body = "Bill is due today. Open Splitway to enter the amount."
        } else if let amount = template.amount {
            content.body = "Auto-logging \(CurrencyFormat.usd(amount)) today."
        } else {
            content.body = "Bill is due today."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: ID.recurringPrefix + template.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            AppLog.lifecycle.error("Schedule recurring failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Budget threshold alerts

    /// Fires an immediate alert if `progress` just crossed a threshold during
    /// the current month. Caller tracks dedup keys in `NotificationPreferences`.
    func fireBudgetAlertIfCrossed(
        before: BudgetProgress?,
        after: BudgetProgress,
        enabled: Bool,
        alreadySent: (String) -> Bool,
        markSent: (String) -> Void
    ) async {
        guard enabled, authStatus == .authorized || authStatus == .provisional else { return }

        let monthKey = monthKey(for: Date())
        let categoryKey = after.category.rawValue

        let was80 = (before?.fraction ?? 0) >= 0.80
        let now80 = after.fraction >= 0.80
        let was100 = (before?.fraction ?? 0) >= 1.0
        let now100 = after.fraction >= 1.0

        if !was100 && now100 {
            let key = "100.\(categoryKey).\(monthKey)"
            if !alreadySent(key) {
                await postImmediate(
                    title: "Over budget: \(after.category.displayName)",
                    body: "You're at \(CurrencyFormat.usd(after.spent)) of \(CurrencyFormat.usd(after.monthlyLimit)) this month.",
                    identifier: ID.budgetAlertPrefix + key
                )
                markSent(key)
            }
        } else if !was80 && now80 {
            let key = "80.\(categoryKey).\(monthKey)"
            if !alreadySent(key) {
                let pct = Int(after.fraction * 100)
                await postImmediate(
                    title: "Heads up: \(after.category.displayName)",
                    body: "\(pct)% used this month. \(CurrencyFormat.usd(after.remaining)) left.",
                    identifier: ID.budgetAlertPrefix + key
                )
                markSent(key)
            }
        }
    }

    private func postImmediate(title: String, body: String, identifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            AppLog.lifecycle.error("Post immediate failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func monthKey(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
    }
}
