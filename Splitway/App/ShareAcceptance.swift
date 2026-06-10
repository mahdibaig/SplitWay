import SwiftUI
import CloudKit

/// Bridges the UIKit app-delegate share-accept callback into SwiftUI. When a
/// user taps a Splitway household invitation link, iOS calls
/// `application(_:userDidAcceptCloudKitShareWith:)` on the app delegate. That
/// callback fires before (or independently of) our service container being
/// ready, so we stash the metadata here and the app drains it once services
/// exist.
@MainActor
final class ShareAcceptanceInbox: ObservableObject {
    static let shared = ShareAcceptanceInbox()

    /// Equatable trigger (CKShare.Metadata is an NSObject and can't drive
    /// SwiftUI `onChange` directly). Bumps each time a new invite arrives.
    @Published private(set) var token: UUID?
    /// The most recent metadata to process; read after `token` changes.
    private(set) var metadata: CKShare.Metadata?

    private init() {}

    func deliver(_ metadata: CKShare.Metadata) {
        self.metadata = metadata
        self.token = UUID()
    }

    func clear() {
        metadata = nil
    }
}

/// Minimal UIApplicationDelegate so SwiftUI can receive the CloudKit
/// share-acceptance callback. Wired via `@UIApplicationDelegateAdaptor` in
/// `SplitwayApp`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            ShareAcceptanceInbox.shared.deliver(cloudKitShareMetadata)
        }
    }
}
