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
    /// User-facing result of opening an invite link (success or the real
    /// error), surfaced as an alert at the app root because the joiner isn't on
    /// the sharing screen when a link opens the app.
    @Published var lastJoinMessage: String?

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

    /// Public database, used for the invite-code → share-URL lookup so people
    /// can join by typing a 6-char code (not only by opening the link).
    private var publicDB: CKDatabase { cloudContainer.publicCloudDatabase }

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
    /// one), configured so anyone with the invite link can join. The returned
    /// share is saved to CloudKit, ready to hand to `UICloudSharingController`.
    func prepareShare() async throws -> CKShare {
        let share: CKShare
        if let existing = existingShare() {
            // Upgrade shares created before link-join was enabled.
            if existing.publicPermission != .readWrite {
                existing.publicPermission = .readWrite
                try? await persistShareUpdate(existing)
            }
            share = existing
        } else {
            guard let object = currentHouseholdObject() else {
                throw SharingError.noHousehold
            }
            isPreparing = true
            defer { isPreparing = false }

            let (_, newShare, _) = try await container.share([object], to: nil)
            newShare[CKShare.SystemFieldKey.title] =
                (householdService.currentHousehold?.name ?? "Splitway household") as CKRecordValue
            // Anyone with the link can join and edit the shared ledger. Without
            // this the share is invite-only and a recipient who wasn't added by
            // iCloud account hits "you don't have permission to access this".
            newShare.publicPermission = .readWrite
            try await persistShareUpdate(newShare)
            share = newShare
        }

        // Publish the code → share-URL mapping (best effort) so a housemate can
        // join by typing the invite code shown in Settings.
        if let code = householdService.currentHousehold?.inviteCode, let url = share.url {
            await publishInvite(code: code, shareURL: url)
        }
        return share
    }

    /// Persists changes made to a CKShare (e.g. `publicPermission`) back to
    /// CloudKit via the container's shared-record machinery.
    private func persistShareUpdate(_ share: CKShare) async throws {
        guard let store = persistence.privateStore else { return }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            container.persistUpdatedShare(share, in: store) { _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    /// Accept an incoming share invitation, routing its records into the
    /// shared store so they merge into the local graph. Called from the
    /// app delegate's `userDidAcceptCloudKitShareWith`.
    func acceptShare(metadata: CKShare.Metadata) async {
        do {
            try await acceptShareThrowing(metadata: metadata)
            AppLog.data.info("Accepted CloudKit share")
            lastJoinMessage = "You've joined the household."
        } catch {
            errorMessage = error.localizedDescription
            lastJoinMessage = "Couldn't join this household: \(error.localizedDescription)"
            AppLog.data.error("Accept share failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Accepts a share and refreshes the household, throwing on failure (so the
    /// invite-code path can surface the outcome).
    func acceptShareThrowing(metadata: CKShare.Metadata) async throws {
        guard let sharedStore = persistence.sharedStore else {
            throw SharingError.sharingUnavailable
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
        // Give CloudKit a moment to import, then refresh the UI's view of the
        // household membership.
        await householdService.refresh()
    }

    // MARK: - Invite codes (public-DB lookup)

    /// Writes a public `code → share URL` record so a housemate can join by
    /// typing the code. The record name IS the namespaced code, so resolving is
    /// a direct fetch (no queryable index to configure). Best-effort.
    private func publishInvite(code: String, shareURL: URL) async {
        let normalized = InviteCode.normalize(code)
        guard !normalized.isEmpty else { return }
        let record = CKRecord(
            recordType: "HouseholdInvite",
            recordID: CKRecord.ID(recordName: "invite_\(normalized)")
        )
        record["shareURL"] = shareURL.absoluteString as CKRecordValue
        do {
            _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
        } catch {
            AppLog.data.error("Publish invite failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Resolves an invite code to its share via the public lookup record, then
    /// accepts the share. Throws if the code is unknown or accepting fails.
    func joinByCode(_ code: String) async throws {
        let normalized = InviteCode.normalize(code)
        let recordID = CKRecord.ID(recordName: "invite_\(normalized)")
        let record: CKRecord
        do {
            record = try await publicDB.record(for: recordID)
        } catch {
            throw SharingError.inviteNotFound
        }
        guard let urlString = record["shareURL"] as? String,
              let url = URL(string: urlString) else {
            throw SharingError.inviteNotFound
        }
        let metadata = try await fetchShareMetadata(for: url)
        try await acceptShareThrowing(metadata: metadata)
    }

    /// Fetches CKShare metadata for a share URL (resolved from an invite code).
    private func fetchShareMetadata(for url: URL) async throws -> CKShare.Metadata {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CKShare.Metadata, Error>) in
            let operation = CKFetchShareMetadataOperation(shareURLs: [url])
            operation.shouldFetchRootRecord = false
            var fetched: CKShare.Metadata?
            operation.perShareMetadataResultBlock = { _, result in
                if case .success(let metadata) = result { fetched = metadata }
            }
            operation.fetchShareMetadataResultBlock = { result in
                switch result {
                case .success:
                    if let fetched { cont.resume(returning: fetched) }
                    else { cont.resume(throwing: SharingError.inviteNotFound) }
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            cloudContainer.add(operation)
        }
    }

    enum SharingError: LocalizedError {
        case noHousehold
        case sharingUnavailable
        case inviteNotFound
        var errorDescription: String? {
            switch self {
            case .noHousehold:
                return "Create a household before inviting people."
            case .sharingUnavailable:
                return "Sharing isn't available on this device yet. Make sure you're signed in to iCloud."
            case .inviteNotFound:
                return "That invite code doesn't match an active household. Ask your housemate to open Share household, then try again."
            }
        }
    }
}
