import Foundation

/// Minimal DeepSeek V4 chat client. We don't talk to DeepSeek directly any
/// more — every request goes through our Cloudflare Worker proxy, which
/// injects the master `Authorization: Bearer <DEEPSEEK_API_KEY>` server-side.
/// The app authenticates with the worker using a shared secret in the
/// `X-App-Auth` header (configured via `AssistantProxyConfig`).
///
/// The JSON shape on the wire is unchanged: the worker forwards the body
/// untouched, and DeepSeek's response is returned untouched. So this still
/// looks like a normal OpenAI-compatible client.
struct DeepSeekClient: Sendable {

    var model: String = "deepseek-chat"
    var session: URLSession = .shared
    var proxy: AssistantProxyConfig = .shared

    enum ClientError: Error, LocalizedError {
        case proxyNotConfigured
        case badStatus(Int, String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .proxyNotConfigured:
                return "AI assistant isn't available in this build. The proxy URL or shared secret is missing."
            case .badStatus(let code, let body):
                return "Assistant proxy returned HTTP \(code). \(body.prefix(200))"
            case .malformedResponse:
                return "Couldn't parse the assistant response."
            }
        }
    }

    struct Message: Codable, Sendable {
        let role: String
        let content: String
    }

    func complete(messages: [Message]) async throws -> String {
        guard let endpoint = proxy.chatCompletionsURL,
              let secret = proxy.sharedSecret else {
            throw ClientError.proxyNotConfigured
        }

        struct Body: Encodable {
            let model: String
            let messages: [Message]
            let temperature: Double
        }
        let body = Body(model: model, messages: messages, temperature: 0.3)
        let payload = try JSONEncoder().encode(body)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(secret, forHTTPHeaderField: "X-App-Auth")
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
