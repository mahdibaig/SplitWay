import Foundation

/// What the user has paid for. `free` is the baseline; everything else is Pro.
/// The first build ships Individual (just the subscriber) and Household (up to
/// 6, shared via Apple Family Sharing for now). A Duo tier and CloudKit-based
/// Pro sharing for roommates are wired up but held back until the multi-user
/// identity layer lands, so Duo stays out of `ProductID.shipping`.
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

    /// Every product the app knows how to honor, including ones not yet offered.
    static let all: [String] = [
        individualMonthly, individualYearly,
        duoMonthly, duoYearly,
        householdMonthly, householdYearly
    ]

    /// Products actually offered in the current build's paywall. Duo is held
    /// back until CloudKit-based Pro sharing exists, so it is omitted here while
    /// remaining fully wired in `all` / `tier(for:)` for when it returns.
    static let shipping: [String] = [
        individualMonthly, individualYearly,
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
