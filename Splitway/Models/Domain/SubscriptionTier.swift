import Foundation

/// What the user has paid for. `free` is the baseline; everything else is Pro.
/// v1 ships three tiers: Individual (just the subscriber), Duo (up to 2), and
/// Household (up to 6). Pro is shared across the people in your Splitway
/// household: a subscriber's plan is stamped on the shared household record and
/// every member within the plan's `proSeatCap` inherits Pro. Household is also
/// Apple-Family-shareable as a reliable fallback for families.
enum SubscriptionTier: String, Sendable, Equatable {
    case free
    case individual
    case duo
    case household

    var isPro: Bool { self != .free }

    /// Relative value ranking. Used to pick the best tier when more than one
    /// entitlement is somehow active on a single device (Household > Duo >
    /// Individual > Free).
    var rank: Int {
        switch self {
        case .free:       return 0
        case .individual: return 1
        case .duo:        return 2
        case .household:  return 3
        }
    }

    /// How many people in a household this plan grants Pro to. The subscriber's
    /// plan is stamped on the shared household record; members are covered while
    /// the household's participant count stays within this cap.
    var proSeatCap: Int {
        switch self {
        case .free:       return 0
        case .individual: return 1
        case .duo:        return 2
        case .household:  return 6
        }
    }

    var displayName: String {
        switch self {
        case .free:       return "Free"
        case .individual: return "Individual"
        case .duo:        return "Duo"
        case .household:  return "Household"
        }
    }
}

/// StoreKit product identifiers. Must match App Store Connect (and the
/// bundled Splitway.storekit config used for local testing).
enum ProductID {
    static let individualMonthly = "splitway_individual_monthly"
    static let individualYearly  = "splitway_individual_yearly"
    static let duoMonthly        = "splitway_duo_monthly"
    static let duoYearly         = "splitway_duo_yearly"
    static let householdMonthly  = "splitway_household_monthly"
    static let householdYearly   = "splitway_household_yearly"

    static let all: [String] = [
        individualMonthly, individualYearly,
        duoMonthly, duoYearly,
        householdMonthly, householdYearly
    ]

    static func tier(for id: String) -> SubscriptionTier {
        switch id {
        case individualMonthly, individualYearly: return .individual
        case duoMonthly, duoYearly:               return .duo
        case householdMonthly, householdYearly:   return .household
        default:                                  return .free
        }
    }

    static func isYearly(_ id: String) -> Bool {
        id == individualYearly || id == duoYearly || id == householdYearly
    }
}
