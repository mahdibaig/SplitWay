import Foundation

enum CurrencyFormat {
    /// "$123.45" using locale-aware grouping but fixed USD symbol for v1.
    static func usd(_ value: Decimal) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    /// "+$5.00" for sage rows, "−$5.00" for coral rows. Sign reflects the *user's*
    /// perspective, not raw arithmetic, caller passes already-flipped values.
    static func signed(_ value: Decimal) -> String {
        let formatted = usd(abs(value))
        if value == 0 {
            return formatted
        } else if value > 0 {
            return "+\(formatted)"
        } else {
            return "−\(formatted)"
        }
    }
}
