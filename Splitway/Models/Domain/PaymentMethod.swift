import Foundation

/// Peer-to-peer payment apps Splitway can hand off to from Settle Up.
///
/// Only Venmo, Cash App, and PayPal expose URL schemes that prefill the
/// recipient and amount cleanly. Zelle does NOT — it lives inside the
/// user's bank app (Chase, BoA, Wells Fargo, etc.) with no central deep
/// link. For Zelle we fall back to copying the payment details to the
/// clipboard and pointing the user at their bank app.
enum PaymentMethod: String, CaseIterable, Codable, Sendable, Identifiable {
    case venmo
    case cashApp
    case paypal
    case zelle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .venmo:   return "Venmo"
        case .cashApp: return "Cash App"
        case .paypal:  return "PayPal"
        case .zelle:   return "Zelle"
        }
    }

    var sfSymbol: String {
        switch self {
        case .venmo:   return "v.circle.fill"
        case .cashApp: return "dollarsign.circle.fill"
        case .paypal:  return "p.circle.fill"
        case .zelle:   return "z.circle.fill"
        }
    }

    /// Placeholder shown in the text field when the user enters their handle.
    var handlePlaceholder: String {
        switch self {
        case .venmo:   return "username (without @)"
        case .cashApp: return "cashtag (without $)"
        case .paypal:  return "paypal.me username"
        case .zelle:   return "email or phone"
        }
    }

    /// True when tapping this method on Settle Up can launch a payment-app
    /// deep link with amount + recipient prefilled. False = handoff is best-
    /// effort (clipboard copy + bank-app instructions, in Zelle's case).
    var supportsDeepLink: Bool {
        self != .zelle
    }
}
