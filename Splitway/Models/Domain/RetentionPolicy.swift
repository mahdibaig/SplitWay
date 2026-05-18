import Foundation

/// How long receipt images are kept on device. Per HANDOFF.md P1/4.1.
/// `never` means the image is discarded at save time (the expense and its
/// parsed line items are still kept, just not the photo).
enum RetentionPolicy: String, CaseIterable, Identifiable, Sendable {
    case never
    case sixMonths
    case twelveMonths
    case forever

    var id: String { rawValue }

    var label: String {
        switch self {
        case .never:         return "Don't store receipts"
        case .sixMonths:     return "6 months"
        case .twelveMonths:  return "12 months"
        case .forever:       return "Forever"
        }
    }

    var detail: String {
        switch self {
        case .never:         return "Receipt photos are never saved. Line items and totals still are."
        case .sixMonths:     return "Receipt photos are removed 6 months after the expense date."
        case .twelveMonths:  return "Receipt photos are removed 12 months after the expense date."
        case .forever:       return "Receipt photos are kept until you delete the expense."
        }
    }

    /// Cutoff date: receipts for expenses dated before this are purged. nil
    /// means no time-based purge (forever) or no storage at all (never).
    func cutoff(now: Date = Date()) -> Date? {
        let cal = Calendar(identifier: .gregorian)
        switch self {
        case .never, .forever: return nil
        case .sixMonths:       return cal.date(byAdding: .month, value: -6, to: now)
        case .twelveMonths:    return cal.date(byAdding: .month, value: -12, to: now)
        }
    }

    static let storageKey = "settings.receiptRetention"
}
