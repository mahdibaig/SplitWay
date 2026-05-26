import Foundation

/// Configuration for the Splitway assistant proxy (the Cloudflare Worker that
/// sits between the iOS app and DeepSeek). Both values are read from the app's
/// Info.plist so they can be set per-build without shipping the DeepSeek API
/// key in the binary.
///
/// Required Info.plist keys (see `project.yml`):
///   SplitwayAssistantBaseURL       e.g. "https://api.splitway.app"
///   SplitwayAssistantSharedSecret  long random string set with
///                                  `wrangler secret put APP_SHARED_SECRET`
///
/// When either value is missing or blank, `isConfigured` returns false and the
/// app falls back to "AI not configured" copy with a deep link to Settings,
/// the same UX as when a user hadn't pasted an API key under the old design.
struct AssistantProxyConfig: Sendable {

    static let shared = AssistantProxyConfig()

    private static let baseURLKey       = "SplitwayAssistantBaseURL"
    private static let sharedSecretKey  = "SplitwayAssistantSharedSecret"
    private static let chatPath         = "/v1/chat/completions"

    /// Base URL of the worker (no trailing slash). nil if missing/blank.
    let baseURL: URL?

    /// Shared secret sent in the `X-App-Auth` header. nil if missing/blank.
    let sharedSecret: String?

    init(bundle: Bundle = .main) {
        let raw = (bundle.object(forInfoDictionaryKey: Self.baseURLKey) as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.baseURL = trimmed.isEmpty ? nil : URL(string: trimmed)

        let secret = (bundle.object(forInfoDictionaryKey: Self.sharedSecretKey) as? String) ?? ""
        let secretTrimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sharedSecret = secretTrimmed.isEmpty ? nil : secretTrimmed
    }

    /// True only when both values are present. The app gates AI features on
    /// this so we never attempt a call that we know will 401.
    var isConfigured: Bool {
        baseURL != nil && sharedSecret != nil
    }

    /// Full chat-completions URL on the worker.
    var chatCompletionsURL: URL? {
        baseURL?.appendingPathComponent(Self.chatPath)
    }
}
