import Foundation

/// Business operations on a Household. Composes repositories and never exposes
/// NSManagedObject. Errors here are user-facing.
@MainActor
final class HouseholdService: ObservableObject {

    private let households: HouseholdRepository
    private let users: UserRepository
    private let accounts: CloudKitAccountService

    @Published private(set) var currentHousehold: Household?
    @Published private(set) var currentMember: HouseholdMember?
    @Published private(set) var iCloudStatus: CloudKitAccountStatus = .couldNotDetermine

    init(households: HouseholdRepository, users: UserRepository, accounts: CloudKitAccountService) {
        self.households = households
        self.users = users
        self.accounts = accounts
    }

    /// Initial state load, call once on app launch.
    func refresh() async {
        do {
            currentHousehold = try await households.fetchCurrent()
            if let id = currentHousehold?.id {
                let members = try await users.fetchMembers(householdID: id)
                currentMember = members.first  // Phase 1: single-device, member-zero
            } else {
                currentMember = nil
            }
        } catch {
            AppLog.data.error("Household refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func refreshAccountStatus() async {
        iCloudStatus = await accounts.currentStatus()
    }

    /// Create a new household locally and add the creator as the first member.
    /// Phase 2 will wrap this in a `CKShare` so other devices can join.
    @discardableResult
    func createHousehold(
        name: String,
        groupsEnabled: Bool,
        creatorDisplayName: String,
        creatorEmoji: String?,
        creatorAvatarImageData: Data?
    ) async throws -> Household {
        let creatorID = UserID()
        let appleUserID = try? await accounts.currentUserRecordID()

        let household = try await households.create(
            name: name,
            groupsEnabled: groupsEnabled,
            createdBy: creatorID
        )

        let member = try await users.createMember(
            in: household.id,
            displayName: creatorDisplayName,
            avatarEmoji: creatorEmoji,
            avatarImageData: creatorAvatarImageData,
            appleUserID: appleUserID
        )

        currentHousehold = household
        currentMember = member

        AppLog.data.info("Created household id=\(household.id.description, privacy: .private)")
        return household
    }

    /// Updates payment-app handles on any member of the current household.
    /// In v1 the local user can edit anyone's handles (so you can enter
    /// "Sarah's Venmo @sarahb" on her behalf before CloudKit sharing lands).
    /// Refreshes the local cache so views observing membership pick up the
    /// change without an extra fetch from the caller.
    func updatePaymentInfo(
        userID: UserID,
        venmoHandle: String?,
        cashAppCashtag: String?,
        paypalMeUsername: String?,
        zelleContact: String?,
        preferredMethod: PaymentMethod?
    ) async throws {
        try await users.updatePaymentInfo(
            userID: userID,
            venmoHandle: venmoHandle,
            cashAppCashtag: cashAppCashtag,
            paypalMeUsername: paypalMeUsername,
            zelleContact: zelleContact,
            preferredMethod: preferredMethod
        )
        if let householdID = currentHousehold?.id {
            let refreshed = try? await users.fetchMembers(householdID: householdID)
            if userID == currentMember?.id {
                currentMember = refreshed?.first { $0.id == userID } ?? currentMember
            }
        }
    }

    func updateMyProfile(displayName: String?, avatarEmoji: String?, avatarImageData: Data??) async throws {
        guard let userID = currentMember?.id else { return }
        if let displayName {
            try await users.updateDisplayName(displayName, userID: userID)
        }
        if let avatarEmoji {
            try await users.updateAvatarEmoji(avatarEmoji, userID: userID)
        }
        if let avatarImageData {
            try await users.updateAvatarImage(avatarImageData, userID: userID)
        }
        // Refresh local cache so views update.
        if let householdID = currentHousehold?.id {
            let refreshed = try? await users.fetchMembers(householdID: householdID)
            currentMember = refreshed?.first { $0.id == userID } ?? currentMember
        }
    }

    func renameHousehold(_ name: String) async throws {
        guard let id = currentHousehold?.id else { return }
        try await households.updateName(name, householdID: id)
        currentHousehold?.name = name
    }

    func regenerateInviteCode() async throws -> String {
        guard let id = currentHousehold?.id else { throw RepositoryError.notFound }
        let code = try await households.regenerateInviteCode(householdID: id)
        currentHousehold?.inviteCode = code
        return code
    }

    func setGroupsEnabled(_ enabled: Bool) async throws {
        guard let id = currentHousehold?.id else { return }
        try await households.setGroupsEnabled(enabled, householdID: id)
        currentHousehold?.groupsEnabled = enabled
    }

    /// Phase 2: this routes through `ShareService` + the public `HouseholdShareMapping`
    /// record. For Phase 1 it's a placeholder so the UI can wire up.
    func joinHousehold(inviteCode: String) async throws {
        throw RepositoryError.inviteCodeNotFound
    }
}
