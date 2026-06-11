import Foundation
import SwiftUI

/// Tracks the free tier's monthly receipt-scan allowance. Non-Pro users get a
/// few cloud scans per month (on the cheaper model) so they can experience the
/// feature before hitting the paywall. Pro users are unlimited and never touch
/// this. Stored locally — a determined user could reset it, but the server's
/// per-IP daily cap is the backstop and the cost on the cheap model is trivial.
@MainActor
final class FreeScanQuota: ObservableObject {

    /// Free cloud scans granted per calendar month.
    static let monthlyLimit = 3

    @Published private(set) var usedThisMonth: Int = 0

    private let usedKey = "freeScan.usedCount"
    private let monthKey = "freeScan.monthKey"

    init() {
        rolloverIfNeeded()
    }

    var remaining: Int { max(0, Self.monthlyLimit - usedThisMonth) }
    var hasRemaining: Bool { remaining > 0 }

    /// Call after a free user completes a successful cloud scan.
    func consume() {
        rolloverIfNeeded()
        usedThisMonth += 1
        UserDefaults.standard.set(usedThisMonth, forKey: usedKey)
    }

    /// Resets the counter when the month rolls over.
    private func rolloverIfNeeded() {
        let current = Self.currentMonthKey()
        let stored = UserDefaults.standard.string(forKey: monthKey)
        if stored != current {
            usedThisMonth = 0
            UserDefaults.standard.set(0, forKey: usedKey)
            UserDefaults.standard.set(current, forKey: monthKey)
        } else {
            usedThisMonth = UserDefaults.standard.integer(forKey: usedKey)
        }
    }

    private static func currentMonthKey() -> String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: Date())
        return "\(c.year ?? 0)-\(String(format: "%02d", c.month ?? 0))"
    }
}
