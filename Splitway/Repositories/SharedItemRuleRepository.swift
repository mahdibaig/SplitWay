import CoreData
import Foundation

protocol SharedItemRuleRepository: Sendable {
    func fetchAll(householdID: HouseholdID) async throws -> [SharedItemRule]
    /// Inserts a new rule or bumps the confidence of an existing one with the
    /// same normalized name. Returns the saved domain rule.
    func upsert(
        normalizedItemName: String,
        ruleType: SharedItemRuleType,
        category: ExpenseCategory?,
        householdID: HouseholdID
    ) async throws -> SharedItemRule
    func delete(id: UUID) async throws
}

final class CoreDataSharedItemRuleRepository: SharedItemRuleRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll(householdID: HouseholdID) async throws -> [SharedItemRule] {
        try await persistence.performBackground { ctx in
            let request = SharedItemRuleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "lastUsedAt", ascending: false)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func upsert(
        normalizedItemName: String,
        ruleType: SharedItemRuleType,
        category: ExpenseCategory?,
        householdID: HouseholdID
    ) async throws -> SharedItemRule {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let lookup = SharedItemRuleEntity.fetchRequest()
            lookup.predicate = NSPredicate(
                format: "household.id == %@ AND normalizedItemName ==[c] %@",
                householdID.raw as CVarArg, normalizedItemName
            )
            lookup.fetchLimit = 1

            let entity = try ctx.fetch(lookup).first ?? SharedItemRuleEntity(context: ctx)
            let now = Date()

            if entity.id == nil {
                entity.id = UUID()
                entity.createdAt = now
                entity.confidence = 1
                entity.household = household
            } else {
                // Bump confidence if the user reaffirms the same rule.
                if Self.matchesExisting(entity: entity, newType: ruleType) {
                    entity.confidence = entity.confidence + 1
                } else {
                    // User changed their mind; reset to 1 with the new rule.
                    entity.confidence = 1
                }
            }

            entity.normalizedItemName = normalizedItemName
            entity.category = category?.rawValue
            entity.lastUsedAt = now

            switch ruleType {
            case .alwaysShared:
                entity.ruleTypeRaw = "alwaysShared"
                entity.assignedUserID = nil
            case .alwaysAssignedTo(let uid):
                entity.ruleTypeRaw = "alwaysAssignedTo"
                entity.assignedUserID = uid
            }

            try ctx.save()
            guard let domain = entity.toDomain() else { throw RepositoryError.mappingFailed }
            return domain
        }
    }

    func delete(id: UUID) async throws {
        try await persistence.performBackground { ctx in
            let request = SharedItemRuleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else { throw RepositoryError.notFound }
            ctx.delete(entity)
            try ctx.save()
        }
    }

    private static func matchesExisting(entity: SharedItemRuleEntity, newType: SharedItemRuleType) -> Bool {
        switch newType {
        case .alwaysShared:
            return entity.ruleTypeRaw == "alwaysShared"
        case .alwaysAssignedTo(let newUID):
            return entity.ruleTypeRaw == "alwaysAssignedTo" && entity.assignedUserID == newUID
        }
    }
}
