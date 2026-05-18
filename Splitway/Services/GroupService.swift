import Foundation

@MainActor
final class GroupService: ObservableObject {

    private let groups: GroupRepository
    private let householdService: HouseholdService

    @Published private(set) var groupsList: [HouseholdGroup] = []

    init(groups: GroupRepository, householdService: HouseholdService) {
        self.groups = groups
        self.householdService = householdService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            groupsList = []
            return
        }
        do {
            groupsList = try await groups.fetchAll(householdID: id)
        } catch {
            AppLog.data.error("Group refresh failed: \(error.localizedDescription, privacy: .public)")
            groupsList = []
        }
    }

    func create(name: String, emoji: String?, colorTag: String?) async throws -> HouseholdGroup {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        let group = try await groups.create(
            name: name,
            emoji: emoji,
            colorTag: colorTag,
            in: householdID,
            by: me
        )
        await refresh()
        return group
    }

    func rename(_ id: GroupID, to name: String) async throws {
        try await groups.rename(id, to: name)
        await refresh()
    }

    func delete(_ id: GroupID) async throws {
        try await groups.delete(id)
        await refresh()
    }

    func setGroup(_ id: GroupID?, forUser userID: UserID) async throws {
        try await groups.setGroup(id, forUser: userID)
        await refresh()
    }

    func groupMembership() async -> [GroupID: [UserID]] {
        var result: [GroupID: [UserID]] = [:]
        for group in groupsList {
            if let members = try? await groups.memberUserIDs(in: group.id) {
                result[group.id] = members
            }
        }
        return result
    }
}
