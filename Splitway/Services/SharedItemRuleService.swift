import Foundation

@MainActor
final class SharedItemRuleService: ObservableObject {

    private let rules: SharedItemRuleRepository
    private let householdService: HouseholdService

    @Published private(set) var rulesList: [SharedItemRule] = []

    init(rules: SharedItemRuleRepository, householdService: HouseholdService) {
        self.rules = rules
        self.householdService = householdService
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            rulesList = []
            return
        }
        do {
            rulesList = try await rules.fetchAll(householdID: id)
        } catch {
            AppLog.data.error("Shared item rules refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Returns the best matching rule for the given normalized name, or nil.
    func match(for normalizedName: String) -> SharedItemRule? {
        let lower = normalizedName.lowercased()
        return rulesList.first { $0.normalizedItemName.lowercased() == lower }
    }

    @discardableResult
    func upsert(
        normalizedItemName: String,
        ruleType: SharedItemRuleType,
        category: ExpenseCategory?
    ) async throws -> SharedItemRule {
        guard let householdID = householdService.currentHousehold?.id else { throw RepositoryError.notFound }
        let saved = try await rules.upsert(
            normalizedItemName: normalizedItemName,
            ruleType: ruleType,
            category: category,
            householdID: householdID
        )
        await refresh()
        return saved
    }

    func delete(id: UUID) async throws {
        try await rules.delete(id: id)
        await refresh()
    }
}
