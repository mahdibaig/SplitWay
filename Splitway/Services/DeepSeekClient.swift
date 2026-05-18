import Foundation

/// Minimal DeepSeek V4 chat client. DeepSeek exposes an OpenAI-compatible
/// REST endpoint, so the JSON shape is the same as `chat/completions`.
struct DeepSeekClient: Sendable {

    /// Default endpoint and model. Override if DeepSeek renames their V4 model.
    var endpoint: URL = URL(string: "https://api.deepseek.com/chat/completions")!
    var model: String = "deepseek-chat"
    var session: URLSession = .shared

    enum ClientError: Error, LocalizedError {
        case missingAPIKey
        case badStatus(Int, String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "DeepSeek API key isn't set. Open Settings, Preferences, Assistant, and paste your key."
            case .badStatus(let code, let body):
                return "DeepSeek returned HTTP \(code). \(body.prefix(200))"
            case .malformedResponse:
                return "Couldn't parse the response from DeepSeek."
            }
        }
    }

    struct Message: Codable, Sendable {
        let role: String
        let content: String
    }

    func complete(messages: [Message], apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ClientError.missingAPIKey }

        struct Body: Encodable {
            let model: String
            let messages: [Message]
            let temperature: Double
        }
        let body = Body(model: model, messages: messages, temperature: 0.3)
        let payload = try JSONEncoder().encode(body)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.malformedResponse }
        if http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.badStatus(http.statusCode, body)
        }

        struct Response: Decodable {
            struct Choice: Decodable {
                let message: Message
            }
            let choices: [Choice]
        }
        do {
            let parsed = try JSONDecoder().decode(Response.self, from: data)
            guard let first = parsed.choices.first?.message.content else {
                throw ClientError.malformedResponse
            }
            return first
        } catch {
            throw ClientError.malformedResponse
        }
    }
}
