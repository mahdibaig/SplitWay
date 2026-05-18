import CoreData
import Foundation

protocol SettlementRepository: Sendable {
    func fetchAll(householdID: HouseholdID) async throws -> [Settlement]
    func create(_ settlement: Settlement) async throws
}

final class CoreDataSettlementRepository: SettlementRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) { self.persistence = persistence }

    func fetchAll(householdID: HouseholdID) async throws -> [Settlement] {
        try await persistence.performBackground { ctx in
            let request = SettlementEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "settledAt", ascending: false)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func create(_ settlement: Settlement) async throws {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", settlement.householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = SettlementEntity(context: ctx)
            entity.id = settlement.id
            entity.fromUserID = settlement.fromUserID.raw
            entity.toUserID = settlement.toUserID.raw
            entity.amount = settlement.amount as NSDecimalNumber
            entity.currency = settlement.currency
            entity.method = settlement.method
            entity.note = settlement.note
            entity.settledAt = settlement.settledAt
            entity.createdByUserID = settlement.createdByUserID.raw
            entity.household = household

            try ctx.save()
        }
    }
}
