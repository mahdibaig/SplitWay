import Foundation
import UIKit
import PDFKit

/// Turns a file URL (PDF or image) picked from the Files app into a UIImage
/// the existing receipt scan pipeline can consume. Used by the "Import
/// from Files" button on the scan flow so digital receipts (Sam's Club
/// Scan & Go PDFs, Costco order PDFs, Apple/Amazon emailed receipts,
/// screenshots saved to Files) all funnel through the same cloud OCR
/// endpoint as a camera scan.
enum DocumentImportService {

    enum ImportError: Error, LocalizedError {
        case securityScopeFailed
        case unsupportedType(String)
        case pdfEmpty
        case pdfRenderFailed
        case imageReadFailed

        var errorDescription: String? {
            switch self {
            case .securityScopeFailed:
                return "Couldn't access that file. Try a different one."
            case .unsupportedType(let ext):
                return "Splitway can import PDFs and images (JPG, PNG, HEIC). \"\(ext)\" isn't supported."
            case .pdfEmpty:
                return "That PDF has no pages."
            case .pdfRenderFailed:
                return "Couldn't render that PDF for scanning."
            case .imageReadFailed:
                return "Couldn't read that image."
            }
        }
    }

    /// Long-edge target for the rendered PDF page. Vision LLMs work well at
    /// roughly this resolution and the file stays small enough to upload
    /// quickly.
    private static let pdfRenderLongEdge: CGFloat = 2400

    /// Loads the file at `url` and returns a UIImage. Handles iOS security
    /// scope for files picked from the document picker. For multi-page
    /// PDFs only the first page is rendered (receipts are single-page).
    static func loadImage(from url: URL) throws -> UIImage {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()

        if ext == "pdf" {
            return try renderFirstPage(of: url)
        }

        // Try as a plain image. Support whatever UIImage can decode
        // natively: JPG, PNG, HEIC, GIF, TIFF, BMP, WebP on iOS 14+.
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            return image
        }

        if !["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "bmp", "webp"].contains(ext) {
            throw ImportError.unsupportedType(ext.isEmpty ? "this file" : ext)
        }
        throw ImportError.imageReadFailed
    }

    /// Renders page 1 of the PDF at high resolution as a bitmap UIImage.
    /// The result feeds the same cloud OCR pipeline as a camera capture.
    private static func renderFirstPage(of url: URL) throws -> UIImage {
        guard let doc = PDFDocument(url: url) else {
            throw ImportError.pdfRenderFailed
        }
        guard doc.pageCount > 0, let page = doc.page(at: 0) else {
            throw ImportError.pdfEmpty
        }
        let pageRect = page.bounds(for: .mediaBox)
        let longest = max(pageRect.width, pageRect.height)
        let scale = max(1, pdfRenderLongEdge / longest)
        let targetSize = CGSize(width: pageRect.width * scale,
                                height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            // Fill white so transparent / dark-background PDFs OCR cleanly.
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            ctx.cgContext.saveGState()
            // PDF coordinates are bottom-left origin; flip so the page
            // renders right-side up in UIKit's top-left coordinate space.
            ctx.cgContext.translateBy(x: 0, y: targetSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
        return image
    }
}
