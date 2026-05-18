import Foundation

@MainActor
final class SettlementService: ObservableObject {

    private let settlements: SettlementRepository
    private let householdService: HouseholdService

    @Published private(set) var settlementsList: [Settlement] = []

    init(settlements: SettlementRepository, householdService: HouseholdService) {
        self.settlements = settlements
        self.householdService = householdService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            settlementsList = []
            return
        }
        do {
            settlementsList = try await settlements.fetchAll(householdID: id)
        } catch {
            AppLog.data.error("Settlement refresh failed: \(error.localizedDescription, privacy: .public)")
            settlementsList = []
        }
    }

    func markPaid(from: UserID, to: UserID, amount: Decimal, method: String? = nil) async throws {
        guard
            let householdID = householdService.currentHousehold?.id,
            let me = householdService.currentMember?.id
        else { throw RepositoryError.notFound }

        let settlement = Settlement(
            id: UUID(),
            householdID: householdID,
            fromUserID: from,
            toUserID: to,
            amount: amount,
            currency: "USD",
            method: method,
            note: nil,
            settledAt: Date(),
            createdByUserID: me
        )
        try await settlements.create(settlement)
        await refresh()
    }
}
