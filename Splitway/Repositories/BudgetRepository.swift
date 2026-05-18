import CoreData
import Foundation

protocol BudgetRepository: Sendable {
    func fetchAll(householdID: HouseholdID) async throws -> [Budget]
    /// Creates or updates the budget for the given category. Categories are
    /// unique per household, so there's never more than one row per category.
    func upsert(category: ExpenseCategory, monthlyLimit: Decimal, householdID: HouseholdID) async throws -> Budget
    func delete(id: UUID) async throws
}

final class CoreDataBudgetRepository: BudgetRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll(householdID: HouseholdID) async throws -> [Budget] {
        try await persistence.performBackground { ctx in
            let request = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func upsert(category: ExpenseCategory, monthlyLimit: Decimal, householdID: HouseholdID) async throws -> Budget {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let existingRequest = BudgetEntity.fetchRequest()
            existingRequest.predicate = NSPredicate(
                format: "household.id == %@ AND category == %@",
                householdID.raw as CVarArg, category.rawValue
            )
            existingRequest.fetchLimit = 1

            let entity = try ctx.fetch(existingRequest).first ?? BudgetEntity(context: ctx)
            if entity.id == nil {
                entity.id = UUID()
                entity.createdAt = Date()
                entity.household = household
            }
            entity.category = category.rawValue
            entity.monthlyLimit = monthlyLimit as NSDecimalNumber
            entity.currency = "USD"
            entity.updatedAt = Date()

            try ctx.save()
            guard let domain = entity.toDomain() else { throw RepositoryError.mappingFailed }
            return domain
        }
    }

    func delete(id: UUID) async throws {
        try await persistence.performBackground { ctx in
            let request = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else {
                throw RepositoryError.notFound
            }
            ctx.delete(entity)
            try ctx.save()
        }
    }
}
