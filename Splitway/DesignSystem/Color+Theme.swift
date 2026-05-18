import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }

    // Surfaces
    static let bg        = adaptive(light: 0xf5ede0, dark: 0x000000)
    /// Fixed warm tan used only by the onboarding flow so it matches the
    /// baked-in background of the onboarding video (no seam). Not adaptive:
    /// the video is the same tan regardless of appearance, and onboarding is
    /// locked to a light color scheme so text stays readable on it.
    static let onboardingBg = Color(hex: 0xFFFFFF)
    // Dark surfaces are near-black warm tiers (Apple-style elevation on a
    // true-black base): each step is just light enough to read as a layer.
    static let surface   = adaptive(light: 0xfdf8f0, dark: 0x161210)
    static let surface2  = adaptive(light: 0xf0e8d8, dark: 0x201a15)
    static let surface3  = adaptive(light: 0xe8dcc8, dark: 0x2b231b)

    // Text
    static let text1 = adaptive(light: 0x2a1d14, dark: 0xf5ede0)
    static let text2 = adaptive(light: 0x8a7a6a, dark: 0xa89888)
    static let text3 = adaptive(light: 0xc4b0a0, dark: 0x6e5e4e)

    // Brand
    static let brand      = adaptive(light: 0xb88a5e, dark: 0xd4a878)
    static let brand2     = adaptive(light: 0x8a6a4a, dark: 0xb88a5e)
    static let brandSoft  = adaptive(light: 0xf0e0c8, dark: 0x2a1f15)

    // Semantic
    static let warn       = adaptive(light: 0xd4824a, dark: 0xe89968)
    static let warnSoft   = adaptive(light: 0xf5d8c2, dark: 0x2e1e14)
    static let success    = adaptive(light: 0x5a7d3e, dark: 0x8aab68)
    static let successSoft = adaptive(light: 0xdfe9d0, dark: 0x1c2614)

    // CTA
    static let cta     = adaptive(light: 0x2a1d14, dark: 0xf5ede0)
    static let ctaText = adaptive(light: 0xfdf8f0, dark: 0x1a130d)

    // Border
    static let borderSubtle = Color.text1.opacity(0.08)
    static let divider      = Color.text1.opacity(0.06)
}

/// Per-person avatar palette. Hash a user ID into one of these slots.
enum AvatarPalette {
    struct Pair { let bg: Color; let fg: Color }

    static let slots: [Pair] = [
        Pair(bg: .init(hex: 0xc0d4b8), fg: .init(hex: 0x3b6d11)), // sage
        Pair(bg: .init(hex: 0xe5b8a8), fg: .init(hex: 0x993556)), // pink
        Pair(bg: .init(hex: 0xd0c4d8), fg: .init(hex: 0x534ab7)), // purple
        Pair(bg: .init(hex: 0xe4c8c0), fg: .init(hex: 0x993c1d))  // coral
    ]

    static func pair(for key: some Hashable) -> Pair {
        let h = abs(key.hashValue) % slots.count
        return slots[h]
    }
}
