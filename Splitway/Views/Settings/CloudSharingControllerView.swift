import SwiftUI
import CloudKit
import UIKit

/// SwiftUI wrapper around `UICloudSharingController`, Apple's system UI for
/// inviting people, managing permissions, and stopping sharing. We hand it a
/// CKShare that's already been created + saved via the persistent container
/// (see `CloudKitSharingService.prepareShare()`).
struct CloudSharingControllerView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let title: String
    var onDidSave: () -> Void = {}
    var onDidStop: () -> Void = {}

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(title: title, onDidSave: onDidSave, onDidStop: onDidStop)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let title: String
        let onDidSave: () -> Void
        let onDidStop: () -> Void

        init(title: String, onDidSave: @escaping () -> Void, onDidStop: @escaping () -> Void) {
            self.title = title
            self.onDidSave = onDidSave
            self.onDidStop = onDidStop
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { title }

        func cloudSharingController(_ csc: UICloudSharingController,
                                    failedToSaveShareWithError error: Error) {
            AppLog.data.error("CloudSharingController save failed: \(error.localizedDescription, privacy: .public)")
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDidSave()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDidStop()
        }
    }
}
