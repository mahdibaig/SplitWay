import CoreData
import CloudKit

/// Owns the CloudKit-sharing operations for a household: creating/fetching the
/// CKShare, accepting incoming invitations, and reading the participant list.
/// The actual invite UI is `UICloudSharingController` (wrapped in
/// `CloudSharingControllerView`); this service prepares the share it needs.
///
/// The whole household graph shares as one unit because every entity hangs off
/// the `Household` root via Core Data relationships — sharing the Household
/// record brings members, expenses, budgets, etc. with it.
@MainActor
final class CloudKitSharingService: ObservableObject {

    private let persistence: PersistenceController
    private let householdService: HouseholdService

    @Published var isPreparing = false
    @Published var errorMessage: String?

    init(persistence: PersistenceController, householdService: HouseholdService) {
        self.persistence = persistence
        self.householdService = householdService
    }

    private var container: NSPersistentCloudKitContainer { persistence.container }

    /// The CloudKit container the UICloudSharingController must use. Built from
    /// the same identifier as the persistent store.
    var cloudContainer: CKContainer {
        CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
    }

    /// True only when the shared store loaded — i.e. accepting/holding shared
    /// data is possible on this device.
    var sharingAvailable: Bool { persistence.sharedStore != nil }

    // MARK: - Lookups

    /// The `Household` managed object for the current household, fetched on the
    /// view context (required: `share(...)` operates on view-context objects).
    private func currentHouseholdObject() -> NSManagedObject? {
        guard let id = householdService.currentHousehold?.id else { return nil }
        let request = NSFetchRequest<NSManagedObject>(entityName: "Household")
        request.predicate = NSPredicate(format: "id == %@", id.raw as CVarArg)
        request.fetchLimit = 1
        return try? container.viewContext.fetch(request).first
    }

    /// The existing CKShare for the current household, or nil if not yet shared.
    func existingShare() -> CKShare? {
        guard let object = currentHouseholdObject() else { return nil }
        let shares = try? container.fetchShares(matching: [object.objectID])
        return shares?[object.objectID]
    }

    /// Number of people on the share (including the owner). 1 = just you /
    /// not shared. Used for the free-tier (2 people) vs Pro (3+) gate.
    func participantCount() -> Int {
        existingShare()?.participants.count ?? 1
    }

    // MARK: - Create / accept

    /// Creates the CKShare for the current household (or returns the existing
    /// one). The returned share is already saved to CloudKit, ready to hand to
    /// `UICloudSharingController`.
    func prepareShare() async throws -> CKShare {
        if let existing = existingShare() { return existing }
        guard let object = currentHouseholdObject() else {
            throw SharingError.noHousehold
        }

        isPreparing = true
        defer { isPreparing = false }

        let (_, share, _) = try await container.share([object], to: nil)
        share[CKShare.SystemFieldKey.title] =
            (householdService.currentHousehold?.name ?? "Splitway household") as CKRecordValue
        return share
    }

    /// Accept an incoming share invitation, routing its records into the
    /// shared store so they merge into the local graph. Called from the
    /// app delegate's `userDidAcceptCloudKitShareWith`.
    func acceptShare(metadata: CKShare.Metadata) async {
        guard let sharedStore = persistence.sharedStore else {
            errorMessage = "Sharing isn't available on this device yet."
            AppLog.data.error("Accept share failed: shared store not loaded")
            return
        }
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            // Give CloudKit a moment to import, then refresh the UI's view of
            // the household membership.
            await householdService.refresh()
            AppLog.data.info("Accepted CloudKit share")
        } catch {
            errorMessage = error.localizedDescription
            AppLog.data.error("Accept share failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    enum SharingError: LocalizedError {
        case noHousehold
        var errorDescription: String? {
            switch self {
            case .noHousehold: return "Create a household before inviting people."
            }
        }
    }
}
