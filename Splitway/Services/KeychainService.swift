import Foundation
import Security

/// Tiny wrapper over Apple's Keychain APIs for secure single-string storage.
/// We use this for the DeepSeek API key (and anywhere else a secret lands).
enum KeychainService {

    /// Stores `value` under `account`. Empty string deletes the entry.
    static func set(_ value: String, account: String) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        // Always delete first so update logic is uniform.
        SecItemDelete(baseQuery as CFDictionary)

        guard !value.isEmpty else { return }

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = value.data(using: .utf8) ?? Data()
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            AppLog.lifecycle.error("Keychain set failed for \(account, privacy: .public): \(status)")
        }
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
