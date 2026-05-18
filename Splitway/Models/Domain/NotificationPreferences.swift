import Foundation
import SwiftUI

/// User-facing notification preferences. Stored in `UserDefaults` via
/// `@AppStorage`, since they're per-device and don't need to sync.
@MainActor
final class NotificationPreferences: ObservableObject {
    @AppStorage("notifications.budgetAlertsEnabled") var budgetAlertsEnabled: Bool = true
    @AppStorage("notifications.recurringRemindersEnabled") var recurringRemindersEnabled: Bool = true

    /// Comma-joined list of dedup keys for budget alerts that have already
    /// fired this month. Cleared automatically when a key's month differs
    /// from the current month.
    @AppStorage("notifications.budgetAlertsSent") private var sentRaw: String = ""

    func hasSent(key: String) -> Bool {
        sentRaw.split(separator: ",").contains { $0 == key }
    }

    func markSent(key: String) {
        var keys = Set(sentRaw.split(separator: ",").map(String.init))
        keys.insert(key)
        sentRaw = keys.joined(separator: ",")
    }

    /// Drop keys whose month no longer matches `currentMonthKey`. Call once
    /// on app launch so the dedup state resets monthly.
    func purgeStaleKeys(currentMonthKey: String) {
        let kept = sentRaw.split(separator: ",")
            .filter { $0.hasSuffix(currentMonthKey) }
        sentRaw = kept.joined(separator: ",")
    }
}
