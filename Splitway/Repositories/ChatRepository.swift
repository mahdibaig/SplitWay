import CoreData
import Foundation

protocol ChatRepository: Sendable {
    /// Loads the recent message history, oldest first, capped at `limit`.
    func fetchRecent(householdID: HouseholdID, limit: Int) async throws -> [ChatMessage]
    func append(_ message: ChatMessage) async throws
    func deleteAll(householdID: HouseholdID) async throws
    /// Trims to the most recent `keepLast` messages. Used to bound local
    /// storage per the spec's "last 50 messages" cap.
    func trim(householdID: HouseholdID, keepLast: Int) async throws
}

final class CoreDataChatRepository: ChatRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchRecent(householdID: HouseholdID, limit: Int) async throws -> [ChatMessage] {
        try await persistence.performBackground { ctx in
            let request = ChatMessageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = limit
            let descending = try ctx.fetch(request).compactMap { $0.toDomain() }
            return descending.reversed()
        }
    }

    func append(_ message: ChatMessage) async throws {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", message.householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = ChatMessageEntity(context: ctx)
            entity.id = message.id
            entity.role = message.role.rawValue
            entity.content = message.content
            entity.createdAt = message.createdAt
            entity.household = household
            try ctx.save()
        }
    }

    func deleteAll(householdID: HouseholdID) async throws {
        try await persistence.performBackground { ctx in
            let request: NSFetchRequest<NSFetchRequestResult> = ChatMessageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            _ = try? ctx.execute(delete)
            try ctx.save()
        }
    }

    func trim(householdID: HouseholdID, keepLast: Int) async throws {
        try await persistence.performBackground { ctx in
            let request = ChatMessageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let all = try ctx.fetch(request)
            guard all.count > keepLast else { return }
            for entity in all.dropFirst(keepLast) {
                ctx.delete(entity)
            }
            try ctx.save()
        }
    }
}
