import Foundation

/// Calls DeepSeek to expand abbreviated receipt item names ("WHL MLK GAL" to
/// "Whole milk gallon"). Per HANDOFF.md P0/3.3:
///   - One batched call per scan (all uncached items in a single prompt).
///   - Local cache by normalized raw name so repeated items skip the API.
///   - Gated by the same assistant opt-in as the chat tab.
@MainActor
final class ReceiptCleanupService: ObservableObject {

    private let preferences: AssistantPreferences
    private var client = DeepSeekClient()
    private var cache: [String: String]

    private static let cacheKey = "receiptCleanupCache.v1"

    init(preferences: AssistantPreferences) {
        self.preferences = preferences
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.cache = decoded
        } else {
            self.cache = [:]
        }
    }

    /// Returns the items with `displayName` enriched and a parallel `cleanedIDs`
    /// set indicating which line items got their name rewritten by the LLM.
    func cleanup(items: [LineItem]) async -> (items: [LineItem], cleanedIDs: Set<UUID>) {
        var result = items
        var cleanedIDs: Set<UUID> = []

        guard preferences.isConfigured else { return (result, cleanedIDs) }
        guard !items.isEmpty else { return (result, cleanedIDs) }

        // Look up cache first, build the uncached batch for the API call.
        struct Pending { let idx: Int; let rawName: String; let normKey: String }
        var pending: [Pending] = []

        for (idx, item) in items.enumerated() {
            let normalized = Self.normalize(item.itemName)
            if let cached = cache[normalized], !cached.isEmpty {
                if cached != result[idx].displayName {
                    result[idx].displayName = cached
                    cleanedIDs.insert(result[idx].id)
                }
            } else if !item.itemName.trimmingCharacters(in: .whitespaces).isEmpty {
                pending.append(Pending(idx: idx, rawName: item.itemName, normKey: normalized))
            }
        }

        guard !pending.isEmpty else { return (result, cleanedIDs) }

        client.model = preferences.model

        do {
            let cleanedNames = try await callDeepSeek(rawNames: pending.map(\.rawName))
            guard cleanedNames.count == pending.count else {
                AppLog.lifecycle.error("Cleanup count mismatch: got \(cleanedNames.count, privacy: .public), expected \(pending.count, privacy: .public)")
                return (result, cleanedIDs)
            }

            for (i, entry) in pending.enumerated() {
                let cleaned = cleanedNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleaned.isEmpty else { continue }
                if cleaned != result[entry.idx].displayName {
                    result[entry.idx].displayName = cleaned
                    cleanedIDs.insert(result[entry.idx].id)
                }
                cache[entry.normKey] = cleaned
            }
            persistCache()
        } catch {
            // Cleanup failures should never break a scan. Just log and return originals.
            AppLog.lifecycle.error("Receipt cleanup failed: \(error.localizedDescription, privacy: .public)")
        }

        return (result, cleanedIDs)
    }

    /// User tapped the "AI" badge to revert. We don't poison the cache; we
    /// just hand back what the parser's prettifier would have produced.
    func prettifyFallback(for rawItemName: String) -> String {
        // Mirror LineItemParser.prettify so caller gets the pre-cleanup display.
        let lower = rawItemName.lowercased()
        return lower.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// Wipe the cache. Reset app data calls this to keep cleanup state in sync.
    func resetCache() {
        cache.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
    }

    // MARK: - Internals

    private func callDeepSeek(rawNames: [String]) async throws -> [String] {
        let numbered = rawNames.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let system = """
        You normalize abbreviated grocery and retail receipt item names. \
        Convert each raw OCR string into a clear human-readable item name. \
        Rules:
        - Keep it brief: 1 to 4 words.
        - Do not invent details that aren't in the raw text.
        - If the raw text is already a clean name, return it unchanged.
        - Preserve quantity hints (gal, oz, lb) when they're in the raw text.
        - Plain text only. No markdown, no asterisks, no dashes.

        Return a single JSON array of strings in the SAME ORDER as the input. \
        No prose, no code fences, no keys. Example: ["Whole milk gallon", "Bananas"]
        """

        let response = try await client.complete(
            messages: [
                DeepSeekClient.Message(role: "system", content: system),
                DeepSeekClient.Message(role: "user",   content: "Items:\n\(numbered)")
            ],
            apiKey: preferences.apiKey
        )

        return try Self.parseJSONArray(response, expectedCount: rawNames.count)
    }

    private func persistCache() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Strips code fences and pulls the first JSON array of strings out of the
    /// response. LLMs sometimes wrap output in ```json fences despite being asked not to.
    static func parseJSONArray(_ raw: String, expectedCount: Int) throws -> [String] {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip code fences if present.
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") {
                text = String(text.dropLast(3))
            }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Find the first '[' and last ']'.
        guard
            let openIdx = text.firstIndex(of: "["),
            let closeIdx = text.lastIndex(of: "]")
        else {
            throw NSError(domain: "ReceiptCleanup", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No JSON array in response"])
        }

        let jsonSubstring = String(text[openIdx...closeIdx])
        guard let data = jsonSubstring.data(using: .utf8) else {
            throw NSError(domain: "ReceiptCleanup", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't encode JSON"])
        }

        let array = try JSONDecoder().decode([String].self, from: data)
        if array.count != expectedCount {
            AppLog.lifecycle.error("Cleanup expected \(expectedCount, privacy: .public) but parsed \(array.count, privacy: .public)")
        }
        return array
    }
}
