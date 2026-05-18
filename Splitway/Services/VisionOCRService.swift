import Foundation
import Vision
import UIKit

/// Wraps Apple Vision's text recognition. Returns lines of recognized text in
/// reading order (top to bottom, then left to right within similar y bands).
struct OCRLine: Sendable, Hashable {
    let text: String
    let boundingBox: CGRect  // normalized, origin bottom-left per Vision
}

enum VisionOCRService {
    /// Runs Vision's accurate text recognition, then groups observations into
    /// lines by Y proximity. Language correction is OFF because receipts have
    /// abbreviated brand names ("WHL MLK GAL") that the language model mangles.
    static func recognizeText(in image: UIImage) async -> [OCRLine] {
        guard let cgImage = image.cgImage else { return [] }

        let observations: [VNRecognizedTextObservation] = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let results = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }

        return groupIntoLines(observations)
    }

    /// Vision sometimes emits multiple observations across one visual line (item
    /// on the left, price on the right). Group them by overlapping Y bands.
    private static func groupIntoLines(_ observations: [VNRecognizedTextObservation]) -> [OCRLine] {
        struct Item { let text: String; let box: CGRect }

        let items: [Item] = observations.compactMap { obs in
            guard let top = obs.topCandidates(1).first else { return nil }
            return Item(text: top.string, box: obs.boundingBox)
        }

        // Sort top to bottom. Vision Y origin is bottom-left, so larger y = higher on page.
        let sorted = items.sorted { $0.box.midY > $1.box.midY }

        // Cluster into rows where Y bands overlap > 50%.
        var rows: [[Item]] = []
        for item in sorted {
            if let lastIdx = rows.indices.last,
               let rowSample = rows[lastIdx].first,
               yOverlapFraction(item.box, rowSample.box) > 0.5 {
                rows[lastIdx].append(item)
            } else {
                rows.append([item])
            }
        }

        return rows.map { row in
            let sortedByX = row.sorted { $0.box.midX < $1.box.midX }
            let combined = sortedByX.map(\.text).joined(separator: "  ")
            let unionBox = sortedByX.dropFirst().reduce(sortedByX[0].box) { $0.union($1.box) }
            return OCRLine(text: combined, boundingBox: unionBox)
        }
    }

    private static func yOverlapFraction(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let lower = max(a.minY, b.minY)
        let upper = min(a.maxY, b.maxY)
        let overlap = max(0, upper - lower)
        let shorter = min(a.height, b.height)
        return shorter > 0 ? overlap / shorter : 0
    }
}
