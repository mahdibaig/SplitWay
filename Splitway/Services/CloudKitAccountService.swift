import CloudKit
import Foundation

enum CloudKitAccountStatus: Sendable {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    init(_ raw: CKAccountStatus) {
        switch raw {
        case .available:               self = .available
        case .noAccount:               self = .noAccount
        case .restricted:              self = .restricted
        case .couldNotDetermine:       self = .couldNotDetermine
        case .temporarilyUnavailable:  self = .temporarilyUnavailable
        @unknown default:              self = .couldNotDetermine
        }
    }
}

/// Checks whether the user is signed in to iCloud. Phase 1 spec test #8 requires
/// the app to handle "iCloud signed out" gracefully, that decision branches off
/// this status.
protocol CloudKitAccountService: Sendable {
    func currentStatus() async -> CloudKitAccountStatus
    func currentUserRecordID() async throws -> String?
}

final class LiveCloudKitAccountService: CloudKitAccountService {
    private let container: CKContainer

    init(containerIdentifier: String = "iCloud.com.mahdibaig.splitway") {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    func currentStatus() async -> CloudKitAccountStatus {
        await withCheckedContinuation { cont in
            container.accountStatus { status, _ in
                cont.resume(returning: CloudKitAccountStatus(status))
            }
        }
    }

    func currentUserRecordID() async throws -> String? {
        try await withCheckedThrowingContinuation { cont in
            container.fetchUserRecordID { recordID, error in
                if let error = error { cont.resume(throwing: error); return }
                cont.resume(returning: recordID?.recordName)
            }
        }
    }
}

/// Stub for previews + simulator where iCloud isn't signed in.
struct StubCloudKitAccountService: CloudKitAccountService {
    let status: CloudKitAccountStatus
    let recordID: String?

    func currentStatus() async -> CloudKitAccountStatus { status }
    func currentUserRecordID() async throws -> String? { recordID }
}
