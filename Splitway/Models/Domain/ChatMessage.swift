import Foundation

enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Hashable, Sendable {
    let id: UUID
    let householdID: HouseholdID
    var role: ChatRole
    var content: String
    var createdAt: Date
}
