import Foundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

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
    ///
    /// Before running Vision, the image goes through a preprocessing pass:
    /// upscaled if small, perspective-corrected against any detected document
    /// rectangle, grayscaled, contrast-boosted. This typically lifts Vision's
    /// hit rate substantially on phone-shot receipts (uneven lighting, slight
    /// angle, lower-res cameras).
    static func recognizeText(in image: UIImage) async -> [OCRLine] {
        guard let original = image.cgImage else { return [] }

        // Run OCR on BOTH the preprocessed and the raw image, then merge
        // unique lines. Preprocessing wins on faded ink and slight angle;
        // raw wins when the receipt is crinkled and rectangle detection
        // over-corrects, or when contrast eats fine text. Either pass
        // catching an item is enough.
        let preprocessed = preprocess(original)
        var allLines: [OCRLine] = []

        if let pp = preprocessed {
            let obs = await runRecognition(on: pp)
            allLines.append(contentsOf: groupIntoLines(obs))
        }
        let rawObs = await runRecognition(on: original)
        let rawLines = groupIntoLines(rawObs)
        for line in rawLines where !allLines.contains(where: { $0.text == line.text }) {
            allLines.append(line)
        }
        return allLines
    }

    private static func runRecognition(on cgImage: CGImage) async -> [VNRecognizedTextObservation] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let results = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]
            // Custom vocab nudges Vision toward brand and SKU abbreviations
            // common on receipts so "KS" doesn't become "K5" etc.
            request.customWords = [
                "Costco", "Kirkland", "KS", "GAL", "OZ", "LB", "CT", "PK",
                "Walmart", "Target", "Safeway", "Trader", "Joe's",
                "ORG", "WHL", "MLK", "TWLS", "TPASTE", "LSGN", "MTBLS"
            ]
            // 0 = no minimum text height; we want the small receipt items.
            request.minimumTextHeight = 0

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }

    // MARK: - Preprocessing

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Returns a contrast-boosted, grayscaled, optionally perspective-corrected
    /// version of the image. Returns nil if preprocessing failed at any step
    /// (the caller falls back to the raw image).
    private static func preprocess(_ source: CGImage) -> CGImage? {
        var image = CIImage(cgImage: source)

        // 1. Auto-detect the receipt rectangle and correct its perspective.
        //    Skips silently if the receipt fills the frame (common case
        //    when the user has already cropped in Photos).
        if let corrected = perspectiveCorrect(image) {
            image = corrected
        }

        // 2. Grayscale (kills color casts from fluorescent lighting) +
        //    contrast boost so faded receipt ink stands out from the paper.
        let mono = CIFilter.colorControls()
        mono.inputImage = image
        mono.saturation = 0
        mono.contrast = 1.6
        mono.brightness = 0.05
        guard let stage = mono.outputImage else { return nil }
        image = stage

        // 3. Mild unsharp mask: makes small SKU digits crisper.
        let sharpen = CIFilter.unsharpMask()
        sharpen.inputImage = image
        sharpen.radius = 1.2
        sharpen.intensity = 0.5
        if let sharpened = sharpen.outputImage { image = sharpened }

        // 4. Upscale if the image is small. Vision likes ~1500-2500px on
        //    the long edge for receipts.
        let longSide = max(image.extent.width, image.extent.height)
        if longSide < 1600 {
            let scale = 1600.0 / longSide
            image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        return ciContext.createCGImage(image, from: image.extent)
    }

    /// Find the largest rectangle (the receipt) and perspective-correct it
    /// so the OCR sees a flat front-facing view. Returns nil if no
    /// confident rectangle is found.
    private static func perspectiveCorrect(_ image: CIImage) -> CIImage? {
        let request = VNDetectRectanglesRequest()
        // Lenient settings so crinkled / partially-flat receipts still get
        // perspective-corrected when possible. If none match, we silently
        // skip correction (the dual-pass OCR in the caller still runs the
        // raw image).
        request.minimumConfidence = 0.5
        request.minimumAspectRatio = 0.15     // receipts are very tall
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.25            // receipt may not fill frame
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try? handler.perform([request])
        guard let rect = request.results?.first as? VNRectangleObservation else {
            return nil
        }

        // Vision uses normalized 0-1 coords with origin bottom-left.
        let w = image.extent.width
        let h = image.extent.height
        func denorm(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * w, y: p.y * h)
        }

        let perspective = CIFilter.perspectiveCorrection()
        perspective.inputImage = image
        perspective.topLeft     = denorm(rect.topLeft)
        perspective.topRight    = denorm(rect.topRight)
        perspective.bottomLeft  = denorm(rect.bottomLeft)
        perspective.bottomRight = denorm(rect.bottomRight)
        return perspective.outputImage
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
