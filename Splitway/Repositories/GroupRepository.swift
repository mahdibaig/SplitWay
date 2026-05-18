import CoreData
import Foundation

protocol GroupRepository: Sendable {
    func fetchAll(householdID: HouseholdID) async throws -> [HouseholdGroup]
    func create(name: String, emoji: String?, colorTag: String?, in householdID: HouseholdID, by userID: UserID) async throws -> HouseholdGroup
    func rename(_ groupID: GroupID, to name: String) async throws
    func delete(_ groupID: GroupID) async throws
    func setGroup(_ groupID: GroupID?, forUser userID: UserID) async throws
    func memberUserIDs(in groupID: GroupID) async throws -> [UserID]
}

final class CoreDataGroupRepository: GroupRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) { self.persistence = persistence }

    func fetchAll(householdID: HouseholdID) async throws -> [HouseholdGroup] {
        try await persistence.performBackground { ctx in
            let request = GroupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func create(name: String, emoji: String?, colorTag: String?, in householdID: HouseholdID, by userID: UserID) async throws -> HouseholdGroup {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = GroupEntity(context: ctx)
            entity.id = UUID()
            entity.name = name
            entity.emoji = emoji
            entity.colorTag = colorTag
            entity.createdAt = Date()
            entity.createdByUserID = userID.raw
            entity.household = household
            try ctx.save()

            guard let domain = entity.toDomain() else { throw RepositoryError.mappingFailed }
            return domain
        }
    }

    func rename(_ groupID: GroupID, to name: String) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findGroup(groupID, in: ctx) else { throw RepositoryError.notFound }
            entity.name = name
            try ctx.save()
        }
    }

    func delete(_ groupID: GroupID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findGroup(groupID, in: ctx) else { throw RepositoryError.notFound }
            ctx.delete(entity)
            try ctx.save()
        }
    }

    func setGroup(_ groupID: GroupID?, forUser userID: UserID) async throws {
        try await persistence.performBackground { ctx in
            let userRequest = UserEntity.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userID.raw as CVarArg)
            userRequest.fetchLimit = 1
            guard let user = try ctx.fetch(userRequest).first else { throw RepositoryError.notFound }

            if let groupID {
                guard let group = try Self.findGroup(groupID, in: ctx) else { throw RepositoryError.notFound }
                user.group = group
            } else {
                user.group = nil
            }
            try ctx.save()
        }
    }

    func memberUserIDs(in groupID: GroupID) async throws -> [UserID] {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findGroup(groupID, in: ctx) else { return [] }
            let members = entity.members as? Set<UserEntity> ?? []
            return members.compactMap { $0.id.map(UserID.init) }
        }
    }

    private static func findGroup(_ id: GroupID, in ctx: NSManagedObjectContext) throws -> GroupEntity? {
        let request = GroupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id.raw as CVarArg)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }
}
