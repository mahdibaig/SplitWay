import SwiftUI

/// User-chosen appearance. Stored in `@AppStorage("settings.appearance")` and
/// applied at the app root via `.preferredColorScheme`. `.system` defers to
/// the device setting.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// nil tells SwiftUI to follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    static let storageKey = "settings.appearance"
}
