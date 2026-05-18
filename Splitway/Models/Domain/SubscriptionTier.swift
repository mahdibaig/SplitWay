import Foundation

/// What the user has paid for. `free` is the baseline; everything else is Pro.
enum SubscriptionTier: String, Sendable, Equatable {
    case free
    case individual
    case family
    case lifetime

    var isPro: Bool { self != .free }

    var displayName: String {
        switch self {
        case .free:       return "Free"
        case .individual: return "Individual"
        case .family:     return "Family"
        case .lifetime:   return "Household Lifetime"
        }
    }
}

/// StoreKit product identifiers. Must match App Store Connect (and the
/// bundled Splitway.storekit config used for local testing).
enum ProductID {
    static let individualYearly  = "splitway_individual_yearly"
    static let familyYearly      = "splitway_family_yearly"
    static let householdLifetime = "splitway_household_lifetime"

    static let all: [String] = [individualYearly, familyYearly, householdLifetime]

    static func tier(for id: String) -> SubscriptionTier {
        switch id {
        case individualYearly:  return .individual
        case familyYearly:      return .family
        case householdLifetime: return .lifetime
        default:                return .free
        }
    }
}
