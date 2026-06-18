import CoreData
import CloudKit

/// Wraps `NSPersistentCloudKitContainer` with a dual-store setup:
///   - a PRIVATE store (the user's own iCloud private database), and
///   - a SHARED store (households other people invited you into via CKShare).
///
/// The dual store is what makes household sharing work: when you accept a
/// CKShare, the shared household's records land in the shared store and merge
/// into the same Core Data graph the UI already reads.
///
/// Defensive by design: if the shared store fails to load (older iOS quirk,
/// iCloud signed out, schema not deployed), the app logs and keeps running
/// on the private store alone — sharing is unavailable but the core app is
/// never broken.
///
/// Repositories run writes through `performBackground` so they never block
/// the main thread and contexts stay properly scoped.
final class PersistenceController: ObservableObject, @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    /// The loaded private and shared stores, captured after `loadPersistentStores`.
    /// `sharedStore` is nil when the shared store failed to load or in-memory.
    private(set) var privateStore: NSPersistentStore?
    private(set) var sharedStore: NSPersistentStore?

    /// True once at least the private store has loaded successfully.
    private(set) var isReady = false

    /// Must match the iCloud container in Splitway.entitlements / project.yml.
    static let cloudKitContainerIdentifier = "iCloud.com.mahdibaig.splitway"

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Splitway")

        guard let privateDescription = container.persistentStoreDescriptions.first else {
            fatalError("PersistenceController: no store description")
        }

        if inMemory {
            privateDescription.url = URL(fileURLWithPath: "/dev/null")
            // Pure local store for previews/tests — no CloudKit sync attempts.
            privateDescription.cloudKitContainerOptions = nil
            container.persistentStoreDescriptions = [privateDescription]
            loadStores()
            return
        }

        // PRIVATE store: keep the existing on-disk URL so no data is lost for
        // users upgrading from the single-store build. Explicitly pin the
        // CloudKit container + private scope.
        let privateOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: Self.cloudKitContainerIdentifier
        )
        privateOptions.databaseScope = .private
        privateDescription.cloudKitContainerOptions = privateOptions
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // SHARED store: a second SQLite file alongside the private one, scoped
        // to the CloudKit shared database. Cloned from the private description
        // so it carries the same model + tracking options.
        guard
            let privateURL = privateDescription.url,
            let sharedDescription = privateDescription.copy() as? NSPersistentStoreDescription
        else {
            // Can't build the shared store; run private-only.
            container.persistentStoreDescriptions = [privateDescription]
            loadStores()
            return
        }
        let sharedURL = privateURL
            .deletingLastPathComponent()
            .appendingPathComponent("shared.sqlite")
        sharedDescription.url = sharedURL
        let sharedOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: Self.cloudKitContainerIdentifier
        )
        sharedOptions.databaseScope = .shared
        sharedDescription.cloudKitContainerOptions = sharedOptions

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        loadStores()
    }

    private func loadStores() {
        container.loadPersistentStores { [weak self] description, error in
            guard let self else { return }
            let scope = description.cloudKitContainerOptions?.databaseScope

            if let error = error as NSError? {
                // A shared-store failure must NOT take down the app. Only the
                // private store is essential.
                if scope == .shared {
                    AppLog.data.error("Shared CloudKit store failed to load (sharing disabled): \(error.localizedDescription, privacy: .public)")
                } else {
                    AppLog.data.error("Core Data private store load failed: \(error.localizedDescription, privacy: .public)")
                    assertionFailure("Core Data private store load failed: \(error)")
                }
                return
            }

            // Capture the loaded store so the sharing service can target it.
            if let url = description.url,
               let store = self.container.persistentStoreCoordinator.persistentStore(for: url) {
                if scope == .shared {
                    self.sharedStore = store
                } else {
                    self.privateStore = store
                    self.isReady = true
                }
            } else if scope != .shared {
                self.isReady = true
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Needed so newly-fetched shared objects resolve their relationships
        // against the combined graph.
        try? container.viewContext.setQueryGenerationFrom(.current)
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

    #if DEBUG
    /// Pushes the COMPLETE Core Data model to the **Development** CloudKit
    /// schema in one shot — every record type and every field, including
    /// optional attributes (like `Household.proTierRaw`) that are usually nil
    /// and would otherwise never register. Run once from a Debug build (which
    /// targets the Development environment), then promote Development ->
    /// Production in the CloudKit Console. Never ship this in a release build.
    func initializeCloudKitSchemaForDevelopment() throws {
        try container.initializeCloudKitSchema(options: [])
    }
    #endif

    /// Deletes every entity in the local store. Dev-only; intended for the
    /// "Reset app data" button in Settings.
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
