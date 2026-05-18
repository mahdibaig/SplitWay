import Foundation
import SwiftUI

/// Local-only preferences for the AI assistant. The DeepSeek API key lives in
/// Keychain (P0/3.1) since it's the only secret in the app. Other prefs stay
/// in `@AppStorage` because they're not sensitive.
@MainActor
final class AssistantPreferences: ObservableObject {

    @AppStorage("assistant.enabled") var enabled: Bool = false
    @AppStorage("assistant.model") var model: String = "deepseek-chat"

    /// Mirrors what's in the Keychain so SwiftUI can observe changes via
    /// `@Published`. Setter persists through to the Keychain.
    @Published var apiKey: String {
        didSet {
            KeychainService.set(apiKey, account: Self.keychainAccount)
        }
    }

    private static let keychainAccount = "com.mahdibaig.splitway.deepseek.apiKey"
    /// Legacy UserDefaults key. Read once on init to migrate, then cleared.
    private static let legacyDefaultsKey = "assistant.apiKey"

    init() {
        // One-time migration: if the legacy UserDefaults key is present, move
        // it into the Keychain and scrub from UserDefaults so it never sits in
        // a plist again.
        if let legacy = UserDefaults.standard.string(forKey: Self.legacyDefaultsKey),
           !legacy.isEmpty,
           KeychainService.get(account: Self.keychainAccount) == nil {
            KeychainService.set(legacy, account: Self.keychainAccount)
            UserDefaults.standard.removeObject(forKey: Self.legacyDefaultsKey)
            AppLog.lifecycle.info("Migrated DeepSeek API key from UserDefaults to Keychain")
        }

        self.apiKey = KeychainService.get(account: Self.keychainAccount) ?? ""
    }

    var isConfigured: Bool {
        enabled && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
