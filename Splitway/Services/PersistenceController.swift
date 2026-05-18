import CoreData
import CloudKit

/// Wraps `NSPersistentCloudKitContainer`. Phase 1 uses the default container with the
/// private CloudKit database. Phase 2+ will add a shared store for household data via CKShare.
///
/// Repositories run their work through `performBackground` so writes never block the
/// main thread and Core Data contexts stay properly scoped.
final class PersistenceController: ObservableObject, @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Splitway")

        if inMemory, let store = container.persistentStoreDescriptions.first {
            store.url = URL(fileURLWithPath: "/dev/null")
        }

        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                AppLog.data.error("Core Data load failed: \(error.localizedDescription, privacy: .public)")
                assertionFailure("Core Data load failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Runs `block` on a fresh background context and returns its result.
    /// The context is created inside this call so it can never leak across boundaries.
    func performBackground<T: Sendable>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return try await context.perform {
            try block(context)
        }
    }

    /// Deletes every entity in the local store. Dev-only; intended for the
    /// "Reset app data" button in Settings. CloudKit sync would later require
    /// a different approach, but Phase 1 data is local.
    func eraseAllData() async throws {
        let entityNames = ["ChatMessage", "SharedItemRule", "RecurringTemplate", "Budget", "Expense", "Settlement", "Group", "User", "Household"]
        try await performBackground { [container] ctx in
            for name in entityNames {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                delete.resultType = .resultTypeObjectIDs
                let result = try ctx.execute(delete) as? NSBatchDeleteResult
                if let ids = result?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                        into: [container.viewContext]
                    )
                }
            }
        }
    }
}
