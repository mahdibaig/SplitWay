import CoreData
import Foundation

protocol HouseholdRepository: Sendable {
    func fetchCurrent() async throws -> Household?
    func create(name: String, groupsEnabled: Bool, createdBy: UserID) async throws -> Household
    func updateName(_ name: String, householdID: HouseholdID) async throws
    func setGroupsEnabled(_ enabled: Bool, householdID: HouseholdID) async throws
    func regenerateInviteCode(householdID: HouseholdID) async throws -> String
    func setEntitlement(tierRaw: String?, expiresAt: Date?, householdID: HouseholdID) async throws
}

/// Phase 1 uses "fetch first household in the local store" as the current household.
/// In Phase 2, when CloudKit sharing is wired up, this becomes "the household whose
/// shared zone we're a member of."
final class CoreDataHouseholdRepository: HouseholdRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchCurrent() async throws -> Household? {
        try await persistence.performBackground { ctx in
            let request = HouseholdEntity.fetchRequest()
            request.fetchLimit = 1
            return try ctx.fetch(request).first?.toDomain()
        }
    }

    func create(name: String, groupsEnabled: Bool, createdBy: UserID) async throws -> Household {
        try await persistence.performBackground { ctx in
            let entity = HouseholdEntity(context: ctx)
            entity.id = UUID()
            entity.name = name
            entity.inviteCode = InviteCode.generate()
            entity.inviteCodeExpiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
            entity.groupsEnabled = groupsEnabled
            entity.createdAt = Date()
            entity.createdByUserID = createdBy.raw

            try ctx.save()

            guard let domain = entity.toDomain() else {
                throw RepositoryError.mappingFailed
            }
            return domain
        }
    }

    func updateName(_ name: String, householdID: HouseholdID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findHousehold(id: householdID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.name = name
            try ctx.save()
        }
    }

    func setGroupsEnabled(_ enabled: Bool, householdID: HouseholdID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findHousehold(id: householdID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.groupsEnabled = enabled
            try ctx.save()
        }
    }

    func regenerateInviteCode(householdID: HouseholdID) async throws -> String {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findHousehold(id: householdID, in: ctx) else {
                throw RepositoryError.notFound
            }
            let code = InviteCode.generate()
            entity.inviteCode = code
            entity.inviteCodeExpiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
            try ctx.save()
            return code
        }
    }

    /// Stamps the active shared Pro plan onto the household record. Pass
    /// `tierRaw: nil` to clear it. Syncs to other members via the shared
    /// CloudKit store, where they read it back as `Household.activeProPlan`.
    func setEntitlement(tierRaw: String?, expiresAt: Date?, householdID: HouseholdID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findHousehold(id: householdID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.proTierRaw = tierRaw
            entity.proExpiresAt = expiresAt
            try ctx.save()
        }
    }

    private static func findHousehold(id: HouseholdID, in ctx: NSManagedObjectContext) throws -> HouseholdEntity? {
        let request = HouseholdEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id.raw as CVarArg)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }
}
