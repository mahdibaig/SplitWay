import Foundation

/// Read model for the Members screen. Splits browsing from mutation so the
/// MembersView can subscribe to a single `@Published` array without pulling in
/// HouseholdService's larger surface.
@MainActor
final class MembersService: ObservableObject {

    private let users: UserRepository
    private let householdService: HouseholdService

    @Published private(set) var members: [HouseholdMember] = []

    init(users: UserRepository, householdService: HouseholdService) {
        self.users = users
        self.householdService = householdService
    }

    func refresh() async {
        guard let householdID = householdService.currentHousehold?.id else {
            members = []
            return
        }
        do {
            members = try await users.fetchMembers(householdID: householdID)
        } catch {
            AppLog.data.error("Members refresh failed: \(error.localizedDescription, privacy: .public)")
            members = []
        }
    }

    /// Derived map of group to its user IDs, computed from members. Used by
    /// `SplitResolver` and `BalanceService` when a SplitRule resolves group
    /// participants down to individual users.
    var groupMembership: [GroupID: [UserID]] {
        var map: [GroupID: [UserID]] = [:]
        for member in members where !member.isArchived {
            if let gid = member.groupID {
                map[gid, default: []].append(member.id)
            }
        }
        return map
    }
}
