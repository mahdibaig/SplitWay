import Foundation
import UIKit

/// Sends a receipt photo to the Splitway proxy's vision endpoint, which
/// forwards to OpenAI GPT-4o mini and returns a structured JSON of merchant,
/// date, total, and line items (each with name + amount + category) in a
/// single call. Replaces the old Apple-Vision-OCR + Costco-parser + LLM-
/// cleanup pipeline for users whose builds have the proxy configured.
///
/// On any failure (proxy not configured, network error, rate-limited,
/// upstream error, malformed response), throws — the caller is expected to
/// fall back to local Apple Vision OCR so the user still gets something.
struct CloudReceiptScanner: Sendable {

    var proxy: AssistantProxyConfig = .shared
    var session: URLSession = .shared

    enum ScanError: Error, LocalizedError {
        case proxyNotConfigured
        case visionNotConfigured     // 503 — worker has no OPENAI_API_KEY
        case rateLimited(Int)        // 429 — cap reached for the day
        case badStatus(Int, String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .proxyNotConfigured:
                return "Receipt scanning isn't available in this build."
            case .visionNotConfigured:
                return "Cloud receipt scanning isn't enabled on the server yet."
            case .rateLimited(let limit):
                return "You've hit today's scan limit (\(limit)). Try again tomorrow."
            case .badStatus(let code, let body):
                return "Scan failed (HTTP \(code)). \(body.prefix(180))"
            case .malformedResponse:
                return "The scanner returned a response we couldn't read."
            }
        }
    }

    /// Decoded response from the proxy's /v1/vision/receipt endpoint.
    struct Result: Decodable, Sendable {
        let merchant: String?
        let date: String?              // YYYY-MM-DD
        let subtotal: Decimal?         // as printed, before tax
        let savings: Decimal?          // discounts / instant savings, positive
        let tax: Decimal?              // as printed
        let total: Decimal?
        let items: [Item]

        struct Item: Decodable, Sendable {
            let name: String
            let amount: Decimal
            let quantity: Int?         // units bought; nil/absent treated as 1
            let category: String?      // ExpenseCategory rawValue
        }
    }

    func scan(image: UIImage, useProModel: Bool = true) async throws -> Result {
        guard let baseURL = proxy.baseURL, let secret = proxy.sharedSecret else {
            throw ScanError.proxyNotConfigured
        }
        let endpoint = baseURL.appendingPathComponent("/v1/vision/receipt")
        // Pro = the accurate model; free = the cheaper one. The worker
        // allowlists both, so a spoofed value can't request a pricier model.
        let modelTier = useProModel ? "pro" : "free"

        // Compress to ~1MP JPEG to keep the upload tight (faster, cheaper).
        // GPT-4o mini handles small receipt photos fine; 1MP keeps OCR
        // sharpness on the smallest item-line text.
        guard let jpeg = compress(image) else {
            throw ScanError.malformedResponse
        }
        let base64 = jpeg.base64EncodedString()

        struct Body: Encodable {
            let image_base64: String
            let mime_type: String
            let tier: String
        }
        let payload = try JSONEncoder().encode(Body(
            image_base64: base64,
            mime_type: "image/jpeg",
            tier: modelTier
        ))

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(secret, forHTTPHeaderField: "X-App-Auth")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        // Vision calls take a few seconds; give it room.
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ScanError.malformedResponse
        }
        if http.statusCode == 429 {
            // Pull the cap out of the body so the user gets the actual number.
            let limit = Self.extractRateLimit(from: data) ?? 30
            throw ScanError.rateLimited(limit)
        }
        if http.statusCode == 503 {
            throw ScanError.visionNotConfigured
        }
        if http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ScanError.badStatus(http.statusCode, body)
        }

        // The proxy returns the parsed JSON object directly. amount/total
        // arrive as JSON numbers; Decimal decoding works via JSONDecoder
        // when the keyed-container uses Decimal directly.
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Result.self, from: data)
        } catch {
            AppLog.lifecycle.error("CloudReceiptScanner decode failed: \(error.localizedDescription, privacy: .public)")
            throw ScanError.malformedResponse
        }
    }

    // MARK: - Helpers

    private func compress(_ image: UIImage) -> Data? {
        // 2048px long edge: OpenAI's high-detail vision scales images to fit
        // within 2048x2048 before tiling, so this is the most usable detail
        // we can hand it. Shrinking further (the old 1400) threw away
        // resolution the model could have read, which is why long, dense
        // receipts (Marshalls, etc.) lost line items. Quality 0.85 keeps
        // small receipt text crisp; the result is still ~1-2 MB, well under
        // the proxy's 12 MB cap.
        let maxDim: CGFloat = 2048  // long edge in pixels
        let longest = max(image.size.width, image.size.height)
        let target: CGSize
        if longest <= maxDim {
            target = image.size
        } else {
            let scale = maxDim / longest
            target = CGSize(width: image.size.width * scale,
                            height: image.size.height * scale)
        }
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }

    private static func extractRateLimit(from data: Data) -> Int? {
        struct Body: Decodable { let limit: Int? }
        return (try? JSONDecoder().decode(Body.self, from: data))?.limit
    }
}
