import Foundation

/// A template that auto-creates expenses on a monthly schedule.
/// Fixed templates log silently. Variable templates surface a prompt for the
/// amount when they come due.
struct RecurringTemplate: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var description: String
    var category: ExpenseCategory
    /// nil means variable. Otherwise the fixed monthly amount.
    var amount: Decimal?
    var isVariableAmount: Bool
    var dayOfMonth: Int
    var nextOccurrence: Date
    var isActive: Bool
    var createdByUserID: UserID
    var createdAt: Date
    var updatedAt: Date

    var isDue: Bool {
        guard isActive else { return false }
        return nextOccurrence <= Date()
    }
}

/// Calendar math for monthly recurrence. Always computes inside Gregorian to
/// keep tests deterministic regardless of the user's locale.
enum RecurrenceCalendar {
    private static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }()

    /// First occurrence given a `dayOfMonth`. If the day hasn't passed yet this
    /// month, use this month. Otherwise next month.
    static func initialOccurrence(dayOfMonth: Int, now: Date = Date()) -> Date {
        let cal = calendar
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        let daysInThisMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 28
        let targetDay = max(1, min(dayOfMonth, daysInThisMonth))

        if (comps.day ?? 1) <= targetDay {
            comps.day = targetDay
            comps.hour = 0; comps.minute = 0; comps.second = 0
            return cal.date(from: comps) ?? now
        } else {
            // Day passed, jump to next month
            var firstComps = comps
            firstComps.day = 1
            firstComps.hour = 0; firstComps.minute = 0; firstComps.second = 0
            let first = cal.date(from: firstComps) ?? now
            return nextOccurrence(after: first, dayOfMonth: dayOfMonth)
        }
    }

    /// Strictly the FIRST of the next month after `current`, clamped to `dayOfMonth`.
    /// So Jan 31 → Feb 28, but Feb 28 → Mar 31 (not Mar 28).
    static func nextOccurrence(after current: Date, dayOfMonth: Int) -> Date {
        let cal = calendar
        var firstComps = cal.dateComponents([.year, .month], from: current)
        firstComps.day = 1
        firstComps.hour = 0; firstComps.minute = 0; firstComps.second = 0
        let firstOfCurrent = cal.date(from: firstComps) ?? current
        let firstOfNext = cal.date(byAdding: .month, value: 1, to: firstOfCurrent) ?? current
        let daysInNext = cal.range(of: .day, in: .month, for: firstOfNext)?.count ?? 28
        var resultComps = cal.dateComponents([.year, .month], from: firstOfNext)
        resultComps.day = max(1, min(dayOfMonth, daysInNext))
        resultComps.hour = 0; resultComps.minute = 0; resultComps.second = 0
        return cal.date(from: resultComps) ?? current
    }
}
