import Foundation

/// Builds the right deep link (or clipboard fallback) for a peer-to-peer
/// payment given the recipient member, method, amount, and a note. Pure
/// value type — no UI here, just URL/string assembly. The Settle Up view
/// owns the actual `UIApplication.shared.open(...)` call.
struct PaymentLinkBuilder {

    /// What the UI should do when the user taps a payment method.
    enum Action {
        /// Open this URL (deep link into Venmo/Cash App/PayPal, or web fallback).
        case openURL(URL)
        /// Copy this text to the clipboard, then show an alert telling the
        /// user to finish the payment in their bank app (Zelle case).
        case copyAndInstruct(text: String, alertBody: String)
    }

    static func action(
        for method: PaymentMethod,
        recipient: HouseholdMember,
        amount: Decimal,
        note: String
    ) -> Action? {
        guard let handle = recipient.handle(for: method) else { return nil }
        let amountString = formattedAmount(amount)
        let encodedNote = note.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? "Splitway"

        switch method {
        case .venmo:
            // Venmo's official deep link. `txn=pay` because the local user
            // owes the recipient — they're paying, not requesting.
            let userPart = stripLeading("@", from: handle)
            let urlString = "venmo://paycharge?txn=pay&recipients=\(userPart)&amount=\(amountString)&note=\(encodedNote)"
            if let url = URL(string: urlString) { return .openURL(url) }
            // Web fallback if the app isn't installed.
            if let web = URL(string: "https://venmo.com/\(userPart)") {
                return .openURL(web)
            }
            return nil

        case .cashApp:
            // cash.app universal links open the app when installed, web
            // otherwise. Append /<amount> to prefill the amount field.
            let tag = stripLeading("$", from: handle)
            let urlString = "https://cash.app/$\(tag)/\(amountString)"
            return URL(string: urlString).map { .openURL($0) }

        case .paypal:
            // paypal.me universal link, same deal — opens app or web.
            let user = stripLeading("@", from: handle)
            let urlString = "https://paypal.me/\(user)/\(amountString)"
            return URL(string: urlString).map { .openURL($0) }

        case .zelle:
            // Zelle has no usable deep link. Copy the payment details to
            // the clipboard and instruct the user to send via their bank.
            let copyText = "\(recipient.displayName) — $\(amountString) — Zelle: \(handle)"
            let alertBody = "Open your bank's app and send $\(amountString) via Zelle to \(handle). Payment details copied to your clipboard."
            return .copyAndInstruct(text: copyText, alertBody: alertBody)
        }
    }

    private static func formattedAmount(_ amount: Decimal) -> String {
        // Use period as decimal separator (URL-friendly), 2 decimal places.
        let nsd = NSDecimalNumber(decimal: amount)
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.decimalSeparator = "."
        f.groupingSeparator = ""
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: nsd) ?? "0.00"
    }

    private static func stripLeading(_ char: Character, from s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        while t.first == char { t.removeFirst() }
        return t
    }
}
