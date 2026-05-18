import CoreData
import Foundation

protocol UserRepository: Sendable {
    func fetchMembers(householdID: HouseholdID) async throws -> [HouseholdMember]
    func createMember(
        in householdID: HouseholdID,
        displayName: String,
        avatarEmoji: String?,
        avatarImageData: Data?,
        appleUserID: String?
    ) async throws -> HouseholdMember
    func updateDisplayName(_ name: String, userID: UserID) async throws
    func updateAvatarEmoji(_ emoji: String?, userID: UserID) async throws
    func updateAvatarImage(_ data: Data?, userID: UserID) async throws
    func archiveMember(userID: UserID) async throws
}

final class CoreDataUserRepository: UserRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchMembers(householdID: HouseholdID) async throws -> [HouseholdMember] {
        try await persistence.performBackground { ctx in
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "household.id == %@", householdID.raw as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "joinedAt", ascending: true)]
            return try ctx.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func createMember(
        in householdID: HouseholdID,
        displayName: String,
        avatarEmoji: String?,
        avatarImageData: Data?,
        appleUserID: String?
    ) async throws -> HouseholdMember {
        try await persistence.performBackground { ctx in
            let householdRequest = HouseholdEntity.fetchRequest()
            householdRequest.predicate = NSPredicate(format: "id == %@", householdID.raw as CVarArg)
            householdRequest.fetchLimit = 1
            guard let household = try ctx.fetch(householdRequest).first else {
                throw RepositoryError.notFound
            }

            let entity = UserEntity(context: ctx)
            entity.id = UUID()
            entity.displayName = displayName
            entity.avatarEmoji = avatarEmoji
            entity.avatarImageData = avatarImageData
            entity.appleUserID = appleUserID
            entity.joinedAt = Date()
            entity.isArchived = false
            entity.household = household

            try ctx.save()

            guard let domain = entity.toDomain() else {
                throw RepositoryError.mappingFailed
            }
            return domain
        }
    }

    func updateDisplayName(_ name: String, userID: UserID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findUser(id: userID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.displayName = name
            try ctx.save()
        }
    }

    func updateAvatarEmoji(_ emoji: String?, userID: UserID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findUser(id: userID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.avatarEmoji = emoji
            try ctx.save()
        }
    }

    func updateAvatarImage(_ data: Data?, userID: UserID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findUser(id: userID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.avatarImageData = data
            try ctx.save()
        }
    }

    func archiveMember(userID: UserID) async throws {
        try await persistence.performBackground { ctx in
            guard let entity = try Self.findUser(id: userID, in: ctx) else {
                throw RepositoryError.notFound
            }
            entity.isArchived = true
            entity.archivedAt = Date()
            try ctx.save()
        }
    }

    private static func findUser(id: UserID, in ctx: NSManagedObjectContext) throws -> UserEntity? {
        let request = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id.raw as CVarArg)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }
}
