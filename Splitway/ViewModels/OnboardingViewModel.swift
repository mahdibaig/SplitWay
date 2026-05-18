import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var emoji: String = "🙂"
    @Published var avatarImageData: Data?
    @Published var householdName: String = "Our household"
    @Published var groupsEnabled: Bool = false

    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private let householdService: HouseholdService

    init(householdService: HouseholdService) {
        self.householdService = householdService
    }

    var canContinueFromName: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canCreateHousehold: Bool {
        !householdName.trimmingCharacters(in: .whitespaces).isEmpty && !isWorking
    }

    func createHousehold() async {
        guard canCreateHousehold else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            _ = try await householdService.createHousehold(
                name: householdName.trimmingCharacters(in: .whitespaces),
                groupsEnabled: groupsEnabled,
                creatorDisplayName: displayName.trimmingCharacters(in: .whitespaces),
                creatorEmoji: avatarImageData == nil ? emoji : nil,
                creatorAvatarImageData: avatarImageData
            )
        } catch {
            AppLog.ui.error("createHousehold failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    func joinHousehold(inviteCode: String) async {
        let code = InviteCode.normalize(inviteCode)
        guard InviteCode.isWellFormed(code) else {
            errorMessage = "Invite codes are 6 letters and numbers."
            return
        }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await householdService.joinHousehold(inviteCode: code)
        } catch {
            AppLog.ui.error("joinHousehold failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }
}
