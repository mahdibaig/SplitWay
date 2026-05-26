import Foundation
import SwiftUI

/// Local-only preferences for the AI assistant. There's no per-user API key
/// any more: requests go through the Splitway assistant proxy (see
/// `AssistantProxyConfig`), which injects the master DeepSeek key
/// server-side. We only need to remember the user's opt-in and chosen model.
@MainActor
final class AssistantPreferences: ObservableObject {

    @AppStorage("assistant.enabled") var enabled: Bool = false
    @AppStorage("assistant.model") var model: String = "deepseek-chat"

    /// Legacy storage we want to scrub. The old build kept a per-user
    /// DeepSeek key in Keychain (and, earlier, in UserDefaults). We delete
    /// both on first launch so nothing sensitive lingers.
    private static let legacyKeychainAccount = "com.mahdibaig.splitway.deepseek.apiKey"
    private static let legacyDefaultsKey = "assistant.apiKey"
    private static let legacyScrubbedFlag = "assistant.legacyKeyScrubbed"

    init() {
        if !UserDefaults.standard.bool(forKey: Self.legacyScrubbedFlag) {
            UserDefaults.standard.removeObject(forKey: Self.legacyDefaultsKey)
            KeychainService.delete(account: Self.legacyKeychainAccount)
            UserDefaults.standard.set(true, forKey: Self.legacyScrubbedFlag)
            AppLog.lifecycle.info("Scrubbed legacy per-user DeepSeek API key storage")
        }
    }

    /// True only when the user opted in AND the proxy is configured in this
    /// build. If the build is missing the Info.plist proxy values, the toggle
    /// is allowed but the UI shows the "not configured" state.
    var isConfigured: Bool {
        enabled && AssistantProxyConfig.shared.isConfigured
    }
}
