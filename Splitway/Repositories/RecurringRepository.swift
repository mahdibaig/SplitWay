import CoreData
import Foundation

protocol RecurringRepository: Sendable {
    func fetchAll(householdID: HouseholdID) async throws -> [RecurringTemplate]
    func create(_ template: RecurringTemplate) async throws -> RecurringTemplate
    func update(_ template: RecurringTemplate) async throws
    func delete(id: UUID) async throws
}

final class CoreDataRecurringRepository: RecurringRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll(householdID: HouseholdID) async throws -> [RecurringTemplate] {
        try await persistence.performBackground { ctx in
            let request = RecurringTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "dayOfMonth", ascending: true)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func create(_ template: RecurringTemplate) async throws -> RecurringTemplate {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", template.householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = RecurringTemplateEntity(context: ctx)
            Self.apply(template, to: entity)
            entity.household = household
            try ctx.save()

            guard let domain = entity.toDomain() else { throw RepositoryError.mappingFailed }
            return domain
        }
    }

    func update(_ template: RecurringTemplate) async throws {
        try await persistence.performBackground { ctx in
            let request = RecurringTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else { throw RepositoryError.notFound }
            Self.apply(template, to: entity)
            try ctx.save()
        }
    }

    func delete(id: UUID) async throws {
        try await persistence.performBackground { ctx in
            let request = RecurringTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try ctx.fetch(request).first else { throw RepositoryError.notFound }
            ctx.delete(entity)
            try ctx.save()
        }
    }

    private static func apply(_ t: RecurringTemplate, to entity: RecurringTemplateEntity) {
        entity.id = t.id
        entity.descriptionText = t.description
        entity.category = t.category.rawValue
        entity.amount = (t.amount ?? .zero) as NSDecimalNumber
        entity.isVariableAmount = t.isVariableAmount
        entity.dayOfMonth = Int16(t.dayOfMonth)
        entity.nextOccurrence = t.nextOccurrence
        entity.isActive = t.isActive
        entity.createdByUserID = t.createdByUserID.raw
        entity.createdAt = t.createdAt
        entity.updatedAt = t.updatedAt
    }
}
