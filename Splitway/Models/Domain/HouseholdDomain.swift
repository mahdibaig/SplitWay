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
}

struct HouseholdGroup: Identifiable, Hashable, Sendable {
    let id: GroupID
    var name: String
    var emoji: String?
    var colorTag: String?
    var createdAt: Date
    var createdByUserID: UserID
}
