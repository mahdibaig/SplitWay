import Foundation

/// Heuristic parser that turns OCR lines into `LineItem` candidates. Phase 4
/// v1 is intentionally generic: looks for a "$X.XX" pattern at the end of
/// each line and treats everything before it as the item name. Store-aware
/// parsers (H-E-B, Costco, etc.) will live alongside this in a later push.
enum LineItemParser {

    struct ParsedReceipt: Sendable {
        let merchant: String?
        let items: [LineItem]
        let total: Decimal?
    }

    static func parse(lines: [OCRLine]) -> ParsedReceipt {
        var items: [LineItem] = []
        var total: Decimal?
        var merchant: String?

        // First non-empty line that's mostly letters is a decent merchant guess.
        if let firstAlpha = lines.first(where: { isMostlyAlpha($0.text) }) {
            merchant = firstAlpha.text.trimmingCharacters(in: .whitespaces)
        }

        for line in lines {
            let text = line.text

            // "TOTAL" line wins over item parsing.
            if let totalAmount = matchTotal(text) {
                total = totalAmount
                continue
            }

            // Skip noise: subtotal, tax, tender, change, card numbers, etc.
            if shouldIgnore(text) { continue }

            guard let (name, amount) = matchItemAndPrice(text) else { continue }
            let cleaned = name.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { continue }

            items.append(LineItem(
                id: UUID(),
                itemName: cleaned,
                displayName: prettify(cleaned),
                normalizedItemName: normalize(cleaned),
                amount: amount,
                quantity: 1,
                assignedToUserIDs: [],
                category: nil
            ))
        }

        return ParsedReceipt(merchant: merchant, items: items, total: total)
    }

    // MARK: - Regex / heuristics

    /// Captures the trailing money value. Allows $ prefix, optional cents.
    /// Examples that match: "MILK 3.99", "WHL MLK GAL $4.29", "BREAD 1.79"
    private static let itemPriceRegex: NSRegularExpression = {
        // (name) (price at end of string)
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+\$?(\d+\.\d{2})\s*$"#,
            options: []
        )
    }()

    private static let totalRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(?i)^\s*(total|grand total|amount due|balance due)\b.*?\$?(\d+\.\d{2})"#,
            options: []
        )
    }()

    private static let ignorePatterns: [NSRegularExpression] = [
        #"(?i)^sub.?total"#,
        #"(?i)^tax\b"#,
        #"(?i)^cash\b"#,
        #"(?i)^change\b"#,
        #"(?i)^tend(er|ered)\b"#,
        #"(?i)^credit\b"#,
        #"(?i)^debit\b"#,
        #"(?i)^visa\b"#,
        #"(?i)^master\s?card\b"#,
        #"(?i)^card\b"#,
        #"^\d{4}\s+\d{4}"#,                  // card masks
        #"(?i)^reference\b"#,
        #"(?i)^auth\b"#,
        #"(?i)^thank\s+you\b"#,
        #"(?i)^\s*#\s*\d+"#                  // store/order numbers
    ].map { try! NSRegularExpression(pattern: $0) }

    private static func matchItemAndPrice(_ text: String) -> (String, Decimal)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = itemPriceRegex.firstMatch(in: text, range: range),
              match.numberOfRanges == 3,
              let nameRange = Range(match.range(at: 1), in: text),
              let priceRange = Range(match.range(at: 2), in: text),
              let amount = Decimal(string: String(text[priceRange]))
        else { return nil }
        return (String(text[nameRange]), amount)
    }

    private static func matchTotal(_ text: String) -> Decimal? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = totalRegex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 3,
              let priceRange = Range(match.range(at: 2), in: text)
        else { return nil }
        return Decimal(string: String(text[priceRange]))
    }

    private static func shouldIgnore(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return ignorePatterns.contains { $0.firstMatch(in: text, range: range) != nil }
    }

    private static func isMostlyAlpha(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }
        let alpha = trimmed.filter { $0.isLetter }
        return Double(alpha.count) / Double(trimmed.count) > 0.6
    }

    private static func prettify(_ raw: String) -> String {
        // Phase 4 v1: just title-case the words. Real expansion ("WHL MLK GAL"
        // to "Whole milk gallon") will plug in once the assistant LLM lands.
        let lower = raw.lowercased()
        return lower.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
