import SwiftUI

/// Fixed v1 category list, order matches the picker order.
enum ExpenseCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case rent
    case utilities
    case groceries
    case diningOut
    case transportation
    case entertainment
    case householdSupplies
    case personalCare
    case healthcare
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rent:              return "Rent"
        case .utilities:         return "Utilities"
        case .groceries:         return "Groceries"
        case .diningOut:         return "Dining out"
        case .transportation:    return "Transportation"
        case .entertainment:     return "Entertainment"
        case .householdSupplies: return "Household supplies"
        case .personalCare:      return "Personal care"
        case .healthcare:        return "Healthcare"
        case .other:             return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .rent:              return "house.fill"
        case .utilities:         return "bolt.fill"
        case .groceries:         return "cart.fill"
        case .diningOut:         return "fork.knife"
        case .transportation:    return "car.fill"
        case .entertainment:     return "party.popper.fill"
        case .householdSupplies: return "bag.fill"
        case .personalCare:      return "sparkles"
        case .healthcare:        return "heart.fill"
        case .other:             return "ellipsis"
        }
    }

    /// Tinted background + foreground for the category tile.
    var palette: (bg: UInt32, fg: UInt32, bgDark: UInt32, fgDark: UInt32) {
        switch self {
        case .rent:              return (0xe8dcc8, 0x8a6a4a, 0x332a1f, 0xc4a078)
        case .utilities:         return (0xe0e8d0, 0x5a7d3e, 0x2a3322, 0x8aab68)
        case .groceries:         return (0xf0e0c8, 0xb88a5e, 0x3d2f22, 0xd4a878)
        case .diningOut:         return (0xe8d4c0, 0xd4824a, 0x3a2a1f, 0xe89968)
        case .transportation:    return (0xd0d8e0, 0x4a6580, 0x222a33, 0x7a95b0)
        case .entertainment:     return (0xe0d4b0, 0x7d6a1e, 0x332e1c, 0xc4b07a)
        case .householdSupplies: return (0xe4c8c0, 0x993c1d, 0x3a2218, 0xd89878)
        case .personalCare:      return (0xd0c4d8, 0x534ab7, 0x2a253a, 0xa89dd8)
        case .healthcare:        return (0xe5b8a8, 0x993556, 0x3a2228, 0xd8909a)
        case .other:             return (0xe0d4c8, 0x7a6555, 0x2e271f, 0xa8988a)
        }
    }
}

extension Color {
    static func categoryBg(_ c: ExpenseCategory) -> Color {
        Color.adaptive(light: c.palette.bg, dark: c.palette.bgDark)
    }

    static func categoryFg(_ c: ExpenseCategory) -> Color {
        Color.adaptive(light: c.palette.fg, dark: c.palette.fgDark)
    }
}
