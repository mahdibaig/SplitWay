import SwiftUI
import VisionKit
import UIKit

/// SwiftUI wrapper around `VNDocumentCameraViewController` — Apple's
/// built-in document scanner (same one Notes and Files use). It handles
/// camera permission UI, real-time edge detection, auto-capture when the
/// receipt is stable, perspective correction, and "retake / keep" all in
/// one native sheet. Way better input for the cloud OCR than a raw camera
/// photo.
///
/// For receipt scanning we only need the first page; the user can retake
/// or shoot again from the scanner before tapping Save.
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanned: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanned: (UIImage) -> Void
        let onCancel: () -> Void

        init(onScanned: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onScanned = onScanned
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Receipts are a single page; take the first scanned page.
            // (If the user shot multiple, we ignore the rest for v1.)
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            let image = scan.imageOfPage(at: 0)
            onScanned(image)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            AppLog.lifecycle.error("Document scanner failed: \(error.localizedDescription, privacy: .public)")
            onCancel()
        }
    }
}
