import Foundation
import os.log

/// Logging facade. Default any user data (names, amounts, IDs) to `.private`
/// so it's redacted in release builds. Use `.public` only for non-PII values.
enum AppLog {
    private static let subsystem = "com.mahdibaig.splitway"
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let cloudkit  = Logger(subsystem: subsystem, category: "cloudkit")
    static let data      = Logger(subsystem: subsystem, category: "data")
    static let ui        = Logger(subsystem: subsystem, category: "ui")
}
