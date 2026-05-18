import Foundation

// MARK: - Split types

enum SplitType: String, Codable, Hashable, CaseIterable, Sendable {
    case equal
    case percentages
    case amounts
    case shares
    case excluded

    var displayName: String {
        switch self {
        case .equal:       return "Equal"
        case .percentages: return "Percent"
        case .amounts:     return "Amount"
        case .shares:      return "Shares"
        case .excluded:    return "Custom"
        }
    }
}

/// Codable-friendly participant value entry. We avoid `Dictionary<UUID, Decimal>` so
/// JSON serialization stays as a stable array of objects rather than a flat key/value
/// array (which is what Swift produces for non-string-key dictionaries).
struct ParticipantValue: Codable, Hashable, Sendable {
    let participantID: UUID  // user or group, depending on the rule's granularity
    var value: Decimal       // percent / amount / shares depending on SplitType
}

struct PaidByEntry: Codable, Hashable, Sendable {
    let userID: UUID
    var amount: Decimal
}

struct SplitRule: Codable, Hashable, Sendable {
    var type: SplitType
    /// Either user IDs or group IDs. When `groupsEnabled` and the granularity is
    /// "by group", these are group IDs and the resolver expands them to users.
    var participantIDs: [UUID]
    var participantValues: [ParticipantValue]
    var paidBy: [PaidByEntry]
    var participantsAreGroups: Bool

    static func equalSplit(amongUserIDs: [UUID], paidBy: UUID, total: Decimal) -> SplitRule {
        SplitRule(
            type: .equal,
            participantIDs: amongUserIDs,
            participantValues: [],
            paidBy: [PaidByEntry(userID: paidBy, amount: total)],
            participantsAreGroups: false
        )
    }
}

// MARK: - Edit history

struct EditRecord: Codable, Hashable, Sendable {
    let editedAt: Date
    let editedByUserID: UUID
    let fieldChanged: String
    let oldValueDescription: String
    let newValueDescription: String
}

// MARK: - Expense

/// A single user's impact on one expense. "Net" reflects out-of-pocket minus
/// owed share, so positive means the user is owed money back on this row.
struct ExpenseUserImpact: Sendable, Equatable {
    let share: Decimal     // owed per the split (their slice)
    let paid:  Decimal     // what they paid up front

    var net: Decimal { paid - share }
    var isExcluded: Bool { share == .zero && paid == .zero }
}

struct Expense: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var loggedByUserID: UserID
    var amount: Decimal
    var currency: String
    var category: ExpenseCategory
    var description: String
    var merchant: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var splitRule: SplitRule
    var editHistory: [EditRecord]
    var isSettled: Bool
    var notes: String?

    /// Phase 3 placeholders.
    var isRecurringInstance: Bool
    var recurringTemplateID: UUID?

    /// Phase 4: optional receipt image (compressed JPEG) and parsed line items.
    var receiptImageData: Data?
    var lineItems: [LineItem]

    /// True if the expense has been soft-deleted (within 30-day recovery window).
    var softDeletedAt: Date?
}

// MARK: - Settlement

struct Settlement: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var fromUserID: UserID
    var toUserID: UserID
    var amount: Decimal
    var currency: String
    var method: String?
    var note: String?
    var settledAt: Date
    var createdByUserID: UserID
}

// MARK: - Balance value type (per user, signed)

struct UserBalance: Identifiable, Hashable, Sendable {
    let id: UserID
    /// Positive: this user is owed money. Negative: this user owes money.
    var net: Decimal
}

/// One simplified payment between two users.
struct SimplifiedPayment: Identifiable, Hashable, Sendable {
    var id: String { "\(from.raw.uuidString)->\(to.raw.uuidString)" }
    let from: UserID
    let to: UserID
    let amount: Decimal
}

/// Group-level rollup of net balances, used by the "Who owes who" card when
/// the user toggles into Group mode.
struct GroupBalance: Identifiable, Hashable, Sendable {
    let id: GroupID
    var net: Decimal
}

/// Simplified payment between two groups (couple-vs-couple). Same greedy
/// algorithm as the user-level version, just typed for groups.
struct SimplifiedGroupPayment: Identifiable, Hashable, Sendable {
    var id: String { "\(from.raw.uuidString)->\(to.raw.uuidString)" }
    let from: GroupID
    let to: GroupID
    let amount: Decimal
}
