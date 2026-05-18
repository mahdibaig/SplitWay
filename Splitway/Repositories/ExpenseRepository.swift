import CoreData
import Foundation

protocol ExpenseRepository: Sendable {
    func fetchAll(householdID: HouseholdID, includeSoftDeleted: Bool) async throws -> [Expense]
    func create(_ expense: Expense) async throws
    func update(_ expense: Expense) async throws
    func softDelete(id: UUID) async throws
    func hardDeleteSoftDeletedOlderThan(_ date: Date) async throws
    /// Nils out receiptImageData for expenses dated before `cutoff`. Returns
    /// how many were purged. The expense + line items are kept.
    @discardableResult
    func purgeReceiptImages(olderThan cutoff: Date) async throws -> Int
}

final class CoreDataExpenseRepository: ExpenseRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll(householdID: HouseholdID, includeSoftDeleted: Bool) async throws -> [Expense] {
        try await persistence.performBackground { ctx in
            let request = ExpenseEntity.fetchRequest()
            if includeSoftDeleted {
                request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            } else {
                request.predicate = NSPredicate(
                    format: "household.id == %@ AND softDeletedAt == nil",
                    householdID.raw as CVarArg
                )
            }
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func create(_ expense: Expense) async throws {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", expense.householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = ExpenseEntity(context: ctx)
            try Self.apply(expense, to: entity)
            entity.household = household
            try ctx.save()
        }
    }

    func update(_ expense: Expense) async throws {
        try await persistence.performBackground { ctx in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else {
                throw RepositoryError.notFound
            }
            try Self.apply(expense, to: entity)
            try ctx.save()
        }
    }

    func softDelete(id: UUID) async throws {
        try await persistence.performBackground { ctx in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else {
                throw RepositoryError.notFound
            }
            entity.softDeletedAt = Date()
            entity.updatedAt = Date()
            try ctx.save()
        }
    }

    func hardDeleteSoftDeletedOlderThan(_ date: Date) async throws {
        try await persistence.performBackground { ctx in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "softDeletedAt != nil AND softDeletedAt < %@",
                date as CVarArg
            )
            let stale = try ctx.fetch(request)
            for e in stale { ctx.delete(e) }
            try ctx.save()
        }
    }

    @discardableResult
    func purgeReceiptImages(olderThan cutoff: Date) async throws -> Int {
        try await persistence.performBackground { ctx in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "receiptImageData != nil AND date < %@",
                cutoff as CVarArg
            )
            let stale = try ctx.fetch(request)
            for e in stale {
                e.receiptImageData = nil
                e.updatedAt = Date()
            }
            if !stale.isEmpty { try ctx.save() }
            return stale.count
        }
    }

    private static func apply(_ expense: Expense, to entity: ExpenseEntity) throws {
        entity.id = expense.id
        entity.loggedByUserID = expense.loggedByUserID.raw
        entity.amount = expense.amount as NSDecimalNumber
        entity.currency = expense.currency
        entity.category = expense.category.rawValue
        entity.descriptionText = expense.description
        entity.merchant = expense.merchant
        entity.date = expense.date
        entity.createdAt = expense.createdAt
        entity.updatedAt = expense.updatedAt
        entity.splitRuleJSON = try CoreDataJSON.encode(expense.splitRule)
        entity.editHistoryJSON = try CoreDataJSON.encode(expense.editHistory)
        entity.lineItemsJSON = try CoreDataJSON.encode(expense.lineItems)
        entity.isSettled = expense.isSettled
        entity.notes = expense.notes
        entity.isRecurringInstance = expense.isRecurringInstance
        entity.recurringTemplateID = expense.recurringTemplateID
        entity.receiptImageData = expense.receiptImageData
        entity.softDeletedAt = expense.softDeletedAt
    }
}
