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
        let merchant = guessMerchant(lines)

        // Costco receipts have a rigid "{4-7 digit SKU} {NAME} {PRICE}"
        // shape that the generic parser misses ~3 items out of 16 on real
        // scans (apostrophes, percent signs, and period-containing names
        // OCR weirdly). When we detect Costco, use a store-specific pass.
        if let merchant, merchant.lowercased().contains("costco") {
            if let costco = parseCostco(lines: lines, merchant: merchant) {
                return costco
            }
        }

        var items: [LineItem] = []
        var total: Decimal?

        // Track the most recent alpha-only "candidate name" so we can pair it
        // with a price-only line that follows (handles column-layout receipts
        // where OCR returns the item name and the price on separate lines).
        var pendingName: String?

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            // TOTAL line wins over item parsing.
            if let totalAmount = matchTotal(text) {
                total = totalAmount
                pendingName = nil
                continue
            }

            // Skip noise.
            if shouldIgnore(text) { pendingName = nil; continue }

            // Lines with 3+ prices are almost always totals/headers/junk
            // on real receipts (payment-details rows, multi-column summaries).
            // 2-price lines come up legitimately on Costco-style receipts
            // (unit price × qty = line total), so we let those through and
            // the regex picks the last price as the actual amount.
            if priceCount(in: text) >= 3 { pendingName = nil; continue }

            // Same-line "item ... $price" match.
            if let (name, amount) = matchItemAndPrice(text) {
                let cleaned = name.trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty, looksLikeItemName(cleaned) {
                    items.append(makeLineItem(name: cleaned, amount: amount))
                    pendingName = nil
                    continue
                }
            }

            // Price-only line: pair with the last alpha line we saw.
            if let priceOnly = matchPriceOnly(text), let name = pendingName,
               looksLikeItemName(name) {
                items.append(makeLineItem(name: name, amount: priceOnly))
                pendingName = nil
                continue
            }

            // Alpha-ish line with no price: stash as a candidate name.
            if looksLikeItemName(text) {
                pendingName = text
            } else {
                pendingName = nil
            }
        }

        return ParsedReceipt(merchant: merchant, items: items, total: total)
    }

    private static func makeLineItem(name: String, amount: Decimal) -> LineItem {
        LineItem(
            id: UUID(),
            itemName: name,
            displayName: prettify(name),
            normalizedItemName: normalize(name),
            amount: amount,
            quantity: 1,
            assignedToUserIDs: [],
            category: nil
        )
    }

    /// Conservative merchant guess. Looks at the first ~8 OCR lines for a
    /// short, mostly-alphabetic line (so we don't dump store numbers or
    /// addresses into the description). Costco gets a fast path because its
    /// header is "COSTCO WHOLESALE" and we want exactly "Costco" downstream.
    private static func guessMerchant(_ lines: [OCRLine]) -> String? {
        for line in lines.prefix(12) {
            let s = line.text.trimmingCharacters(in: .whitespaces)
            if s.uppercased().contains("COSTCO") { return "Costco" }
        }
        for line in lines.prefix(8) {
            let s = line.text.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty, s.count <= 30 else { continue }
            if s.contains(where: { $0.isNumber || $0 == ":" }) { continue }
            let letters = s.filter { $0.isLetter }.count
            guard Double(letters) / Double(s.count) >= 0.7 else { continue }
            return s
        }
        return nil
    }

    // MARK: - Costco-specific parser
    //
    // Costco prints every item as `{SKU} {NAME} {PRICE}` on one OCR line:
    //   24311 VAR. MUFFIN          9.99
    //   1239521 KS ULTRA LIQ      17.99
    //   1474436 KS TRAIL MIX      12.69
    //
    // The generic parser misses ~3 of 16 on a real receipt because OCR
    // sometimes attaches stray characters or because the name contains
    // punctuation that `looksLikeItemName` is suspicious of. This pass is
    // strict about the SKU prefix and permissive about everything else.

    private static let costcoLineRegex: NSRegularExpression = {
        // (SKU 4-7 digits) (name, must contain at least one letter) (price X.XX)
        // The name doesn't have to start with a letter — "18CT EGGS" and
        // "24CT COOKIES" are real Costco lines. We just require *some*
        // alphabetic content so address lines like "2258 315 211 057"
        // can't be mistaken for items.
        try! NSRegularExpression(
            pattern: #"^\s*(\d{4,7})\s+(.*?[A-Za-z].*?)\s+\$?(\d+\.\d{2})\s*$"#,
            options: []
        )
    }()

    private static let costcoTotalRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(?i)^\*+\s*TOTAL\b.*?\$?(\d+\.\d{2})"#,
            options: []
        )
    }()

    private static func parseCostco(lines: [OCRLine], merchant: String) -> ParsedReceipt? {
        var items: [LineItem] = []
        var total: Decimal?

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            // Stop pulling line items once we hit the totals block.
            if text.uppercased().contains("SUBTOTAL")
                || text.uppercased().contains("TOTAL TAX")
                || text.uppercased().contains("BOTTOM OF BASKET") {
                // Don't break — KS TOWEL / KS BATH come AFTER "Bottom of
                // Basket" in real Costco receipts. Just skip this line.
                if let t = matchCostcoTotal(text) { total = t }
                continue
            }

            if let (name, amount) = matchCostcoItem(text) {
                let cleaned = name.trimmingCharacters(in: .whitespaces)
                guard !cleaned.isEmpty else { continue }
                items.append(makeLineItem(name: cleaned, amount: amount))
            }
        }

        // If the Costco-specific pass found nothing useful, fall through to
        // the generic parser by returning nil. Otherwise commit our result.
        guard !items.isEmpty else { return nil }
        return ParsedReceipt(merchant: merchant, items: items, total: total)
    }

    private static func matchCostcoItem(_ text: String) -> (String, Decimal)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = costcoLineRegex.firstMatch(in: text, range: range),
              match.numberOfRanges == 4,
              let nameRange = Range(match.range(at: 2), in: text),
              let priceRange = Range(match.range(at: 3), in: text),
              let amount = Decimal(string: String(text[priceRange]))
        else { return nil }
        return (String(text[nameRange]), amount)
    }

    private static func matchCostcoTotal(_ text: String) -> Decimal? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = costcoTotalRegex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: text)
        else { return nil }
        return Decimal(string: String(text[r]))
    }

    private static func priceCount(in text: String) -> Int {
        let pattern = try! NSRegularExpression(pattern: #"\$?\d+\.\d{2}"#)
        return pattern.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    /// Filters out lines that look like totals, dates, or pure numbers.
    /// Costco-style receipts pad item names with SKU prefixes ("E 1234567 KS
    /// BATT AA40") so the letter ratio can be low. We accept anything with
    /// at least 2 letters AND a 20%+ letter density.
    private static func looksLikeItemName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return false }
        let letters = trimmed.filter { $0.isLetter }.count
        guard letters >= 2 else { return false }
        return Double(letters) / Double(trimmed.count) >= 0.20
    }

    private static let priceOnlyRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"^\$?(\d+\.\d{2})\s*$"#)
    }()

    private static func matchPriceOnly(_ text: String) -> Decimal? {
        let range = NSRange(text.startIndex..., in: text)
        guard
            let match = priceOnlyRegex.firstMatch(in: text, range: range),
            match.numberOfRanges == 2,
            let r = Range(match.range(at: 1), in: text)
        else { return nil }
        return Decimal(string: String(text[r]))
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
