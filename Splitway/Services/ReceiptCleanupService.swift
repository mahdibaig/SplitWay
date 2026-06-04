import Foundation

/// Calls DeepSeek to expand abbreviated receipt item names ("WHL MLK GAL" to
/// "Whole milk gallon") AND categorize each line into one of the 10 fixed
/// Splitway categories. Per HANDOFF.md P0/3.3:
///   - One batched call per scan (all uncached items in a single prompt).
///   - Local cache by normalized raw name so repeated items skip the API.
///   - Gated by the same assistant opt-in as the chat tab.
@MainActor
final class ReceiptCleanupService: ObservableObject {

    private let preferences: AssistantPreferences
    private var client = DeepSeekClient()

    /// Cached LLM result per normalized raw name.
    private struct Cached: Codable { let cleaned: String; let category: String? }
    private var cache: [String: Cached]

    private static let cacheKey = "receiptCleanupCache.v2"

    init(preferences: AssistantPreferences) {
        self.preferences = preferences
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let decoded = try? JSONDecoder().decode([String: Cached].self, from: data) {
            self.cache = decoded
        } else {
            self.cache = [:]
        }
    }

    /// Returns the items with `displayName` enriched, `category` filled where
    /// the LLM had a confident guess, and a parallel `cleanedIDs` set listing
    /// the line items the LLM renamed (so the UI can offer revert).
    func cleanup(items: [LineItem]) async -> (items: [LineItem], cleanedIDs: Set<UUID>) {
        var result = items
        var cleanedIDs: Set<UUID> = []

        guard preferences.isConfigured else { return (result, cleanedIDs) }
        guard !items.isEmpty else { return (result, cleanedIDs) }

        struct Pending { let idx: Int; let rawName: String; let normKey: String }
        var pending: [Pending] = []

        // Cache hits short-circuit the API call.
        for (idx, item) in items.enumerated() {
            let normalized = Self.normalize(item.itemName)
            if let cached = cache[normalized] {
                if !cached.cleaned.isEmpty, cached.cleaned != result[idx].displayName {
                    result[idx].displayName = cached.cleaned
                    cleanedIDs.insert(result[idx].id)
                }
                if let raw = cached.category, let cat = ExpenseCategory.lookup(raw) {
                    result[idx].category = cat
                }
            } else if !item.itemName.trimmingCharacters(in: .whitespaces).isEmpty {
                pending.append(Pending(idx: idx, rawName: item.itemName, normKey: normalized))
            }
        }

        guard !pending.isEmpty else { return (result, cleanedIDs) }

        client.model = preferences.model

        do {
            let cleaned = try await callDeepSeek(rawNames: pending.map(\.rawName))
            guard cleaned.count == pending.count else {
                AppLog.lifecycle.error("Cleanup count mismatch: got \(cleaned.count, privacy: .public), expected \(pending.count, privacy: .public)")
                return (result, cleanedIDs)
            }

            for (i, entry) in pending.enumerated() {
                let name = cleaned[i].name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                if name != result[entry.idx].displayName {
                    result[entry.idx].displayName = name
                    cleanedIDs.insert(result[entry.idx].id)
                }
                if let category = cleaned[i].category {
                    result[entry.idx].category = category
                }
                cache[entry.normKey] = Cached(
                    cleaned: name,
                    category: cleaned[i].category?.rawValue
                )
            }
            persistCache()
        } catch {
            AppLog.lifecycle.error("Receipt cleanup failed: \(error.localizedDescription, privacy: .public)")
        }

        return (result, cleanedIDs)
    }

    /// Mirror of LineItemParser.prettify for the "tap AI badge to revert" path.
    func prettifyFallback(for rawItemName: String) -> String {
        let lower = rawItemName.lowercased()
        return lower.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    func resetCache() {
        cache.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
    }

    // MARK: - Internals

    private struct Cleaned { let name: String; let category: ExpenseCategory? }

    private func callDeepSeek(rawNames: [String]) async throws -> [Cleaned] {
        let numbered = rawNames.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let categoryList = ExpenseCategory.allCases.map(\.rawValue).joined(separator: ", ")
        let system = """
        You normalize abbreviated retail receipt item names AND assign each \
        item to ONE of these exact category strings: \(categoryList).

        IMPORTANT: receipts often mix categories. A single Costco, Walmart, \
        Target, or grocery-store trip routinely includes food AND paper goods \
        AND batteries AND toiletries AND medicine AND occasionally gasoline. \
        DO NOT default everything to "groceries". Evaluate each item on its \
        own merits. If an item is clearly not food or drink for home, pick a \
        more specific category.

        Category guide:
        - groceries: edible food and non-alcoholic drinks for home cooking \
          (milk, eggs, produce, meat, bread, snacks, soda, bottled water, \
          coffee beans, condiments).
        - diningOut: prepared restaurant meals, takeout, deli sandwiches, \
          coffee-shop drinks, alcohol at a bar.
        - transportation: gasoline, diesel, fuel, parking, tolls, transit \
          fares, ride share, car wash, motor oil, windshield washer fluid.
        - householdSupplies: paper towels, toilet paper, dish soap, laundry \
          detergent, cleaning products, trash bags, foil, plastic wrap, \
          batteries, light bulbs, kitchen tools, small appliances, \
          electronics, hardware, garden, pet supplies.
        - personalCare: shampoo, conditioner, body wash, toothpaste, makeup, \
          razors, deodorant, hair products.
        - healthcare: over-the-counter medicine, vitamins, supplements, \
          prescriptions, bandages, first aid.
        - entertainment: movie tickets, streaming subscriptions, books, \
          games, toys, hobby supplies, sporting equipment.
        - utilities: bills only (water, electric, gas, internet). Almost \
          never appears on a retail receipt.
        - rent: rent only. Almost never appears on a retail receipt.
        - other: only if the item genuinely fits none of the above.

        Rules for the name field:
        - Keep it brief: 1 to 4 words.
        - Do not invent details that aren't in the raw text.
        - If the raw text is already a clean name, return it unchanged.
        - Preserve quantity hints (gal, oz, lb) when in the raw text.
        - Plain text only, no markdown, no asterisks, no dashes.

        Rules for the category field:
        - Use one of the exact strings from the list above.
        - If genuinely unsure, return "other" — but try the guide first.

        Return a single JSON array in the SAME ORDER as the input. Each \
        element MUST be an object: {"name": "...", "category": "..."}. \
        No prose, no code fences, no other keys.

        Examples (mixed-category trip):
        Input:
        1. WHL MLK GAL
        2. KS PAPER TWLS
        3. UNLEADED GAS
        4. ADVIL 100CT
        5. KS BATT AA40
        6. CREST TPASTE
        Output:
        [{"name":"Whole milk gallon","category":"groceries"},\
        {"name":"Kirkland paper towels","category":"householdSupplies"},\
        {"name":"Unleaded gas","category":"transportation"},\
        {"name":"Advil 100 ct","category":"healthcare"},\
        {"name":"Kirkland AA batteries","category":"householdSupplies"},\
        {"name":"Crest toothpaste","category":"personalCare"}]
        """

        let response = try await client.complete(
            messages: [
                DeepSeekClient.Message(role: "system", content: system),
                DeepSeekClient.Message(role: "user",   content: "Items:\n\(numbered)")
            ]
        )

        return try Self.parseCleanedArray(response, expectedCount: rawNames.count)
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

    /// Strips code fences and pulls the JSON array out of the response.
    /// Tolerates either an array of strings (legacy) or array of objects.
    private static func parseCleanedArray(_ raw: String, expectedCount: Int) throws -> [Cleaned] {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") { text = String(text.dropLast(3)) }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard
            let openIdx = text.firstIndex(of: "["),
            let closeIdx = text.lastIndex(of: "]")
        else {
            throw NSError(domain: "ReceiptCleanup", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No JSON array in response"])
        }
        let json = String(text[openIdx...closeIdx])
        guard let data = json.data(using: .utf8) else {
            throw NSError(domain: "ReceiptCleanup", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't encode JSON"])
        }

        // Try objects first; fall back to strings if the model regressed.
        struct Obj: Decodable { let name: String?; let category: String? }
        if let arr = try? JSONDecoder().decode([Obj].self, from: data) {
            return arr.map { entry in
                let name = entry.name ?? ""
                let cat = entry.category.flatMap { ExpenseCategory.lookup($0) }
                return Cleaned(name: name, category: cat)
            }
        }
        let strings = try JSONDecoder().decode([String].self, from: data)
        if strings.count != expectedCount {
            AppLog.lifecycle.error("Cleanup expected \(expectedCount, privacy: .public) but parsed \(strings.count, privacy: .public)")
        }
        return strings.map { Cleaned(name: $0, category: nil) }
    }
}
