import Foundation

/// Typed identifiers prevent accidentally passing a UserID where a HouseholdID is expected.
struct UserID: Hashable, Codable, Sendable, CustomStringConvertible {
    let raw: UUID
    init(_ raw: UUID = UUID()) { self.raw = raw }
    var description: String { raw.uuidString }
}

struct HouseholdID: Hashable, Codable, Sendable, CustomStringConvertible {
    let raw: UUID
    init(_ raw: UUID = UUID()) { self.raw = raw }
    var description: String { raw.uuidString }
}

struct GroupID: Hashable, Codable, Sendable, CustomStringConvertible {
    let raw: UUID
    init(_ raw: UUID = UUID()) { self.raw = raw }
    var description: String { raw.uuidString }
}
