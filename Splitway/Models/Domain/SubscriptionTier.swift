import Foundation

/// What the user has paid for. `free` is the baseline; everything else is Pro.
/// v1 ships two paid tiers: Individual (the subscriber) and Household
/// (Apple-Family-shareable, up to 6). A "Duo" couples tier is planned for a
/// later release once per-seat tracking exists.
enum SubscriptionTier: String, Sendable, Equatable {
    case free
    case individual
    case household

    var isPro: Bool { self != .free }

    var displayName: String {
        switch self {
        case .free:       return "Free"
        case .individual: return "Individual"
        case .household:  return "Household"
        }
    }
}

/// StoreKit product identifiers. Must match App Store Connect (and the
/// bundled Splitway.storekit config used for local testing).
enum ProductID {
    static let individualMonthly = "splitway_individual_monthly"
    static let individualYearly  = "splitway_individual_yearly"
    static let householdMonthly  = "splitway_household_monthly"
    static let householdYearly   = "splitway_household_yearly"

    static let all: [String] = [
        individualMonthly, individualYearly,
        householdMonthly, householdYearly
    ]

    static func tier(for id: String) -> SubscriptionTier {
        switch id {
        case individualMonthly, individualYearly: return .individual
        case householdMonthly, householdYearly:   return .household
        default:                                  return .free
        }
    }

    static func isYearly(_ id: String) -> Bool {
        id == individualYearly || id == householdYearly
    }
}
