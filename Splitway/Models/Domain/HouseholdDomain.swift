import Foundation

/// Plain-value domain models. These cross actor boundaries safely (all Sendable)
/// and never carry a Core Data context with them. NSManagedObject types stay
/// inside the repository layer.

struct Household: Identifiable, Hashable, Sendable {
    let id: HouseholdID
    var name: String
    var inviteCode: String
    var inviteCodeExpiresAt: Date?
    var groupsEnabled: Bool
    var createdAt: Date
    var createdByUserID: UserID
}

struct HouseholdMember: Identifiable, Hashable, Sendable {
    let id: UserID
    var displayName: String
    var avatarEmoji: String?
    var avatarImageData: Data?
    var groupID: GroupID?
    var joinedAt: Date
    var isArchived: Bool

    // Per-member payment handles. Settle Up uses these to deep-link into
    // the right peer-to-peer payment app with amount + recipient prefilled.
    // Nil = the member hasn't set that handle yet.
    var venmoHandle: String? = nil
    var cashAppCashtag: String? = nil
    var paypalMeUsername: String? = nil
    var zelleContact: String? = nil
    /// If set, Settle Up shows this method first. If nil, the first method
    /// the member has a handle for wins.
    var preferredPaymentMethod: PaymentMethod? = nil

    /// All methods this member has a handle saved for, in display order.
    /// Empty when the member hasn't set up any payment info.
    var availablePaymentMethods: [PaymentMethod] {
        var out: [PaymentMethod] = []
        if venmoHandle?.isEmpty == false      { out.append(.venmo) }
        if cashAppCashtag?.isEmpty == false   { out.append(.cashApp) }
        if paypalMeUsername?.isEmpty == false { out.append(.paypal) }
        if zelleContact?.isEmpty == false     { out.append(.zelle) }

        // Bubble the preferred method to the front so it shows as the
        // primary button on Settle Up.
        if let pref = preferredPaymentMethod, out.contains(pref) {
            out.removeAll { $0 == pref }
            out.insert(pref, at: 0)
        }
        return out
    }

    /// Handle string for a given method. Empty/whitespace becomes nil.
    func handle(for method: PaymentMethod) -> String? {
        let raw: String?
        switch method {
        case .venmo:   raw = venmoHandle
        case .cashApp: raw = cashAppCashtag
        case .paypal:  raw = paypalMeUsername
        case .zelle:   raw = zelleContact
        }
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
}

struct HouseholdGroup: Identifiable, Hashable, Sendable {
    let id: GroupID
    var name: String
    var emoji: String?
    var colorTag: String?
    var createdAt: Date
    var createdByUserID: UserID
}
