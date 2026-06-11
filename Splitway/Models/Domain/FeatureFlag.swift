import Foundation

/// Pro-gated capabilities. Per HANDOFF.md the free tier always keeps:
/// all 5 split modes, unlimited expenses (NEVER a daily cap), 1 group,
/// settle up, recurring bills, current-month reports, receipt photo
/// attachment, and 2-person CloudKit sharing. Everything below is Pro.
enum FeatureFlag: String, CaseIterable {
    case unlimitedGroups        // more than 1 group
    case fullReports            // 3/6/9/12-month trends + Just-me scope
    case budgets                // budgets + budget notifications
    case receiptOCR             // Vision OCR + line-item review
    case aiReceiptCleanup       // LLM name cleanup on scans
    case aiAssistant            // the assistant chips
    case csvImportExport        // CSV import + CSV export
    case cloudShare3Plus        // CloudKit sharing for 3+ members

    /// User-facing reason shown on the paywall when this feature is tapped.
    var paywallPitch: String {
        switch self {
        case .unlimitedGroups:  return "Create unlimited groups for every couple and family in your household."
        case .fullReports:      return "See 3, 6, 9, and 12-month trends and your personal spending breakdown."
        case .budgets:          return "Set category budgets and get alerts before you overspend."
        case .receiptOCR:       return "You've used your 3 free scans this month. Go Pro for unlimited scans on our most accurate scanner."
        case .aiReceiptCleanup: return "Turn cryptic receipt text into clean item names."
        case .aiAssistant:      return "Ask the assistant about your spending in plain language."
        case .csvImportExport:  return "Import expenses from a CSV and export your data."
        case .cloudShare3Plus:  return "Share your household with 3 or more people."
        }
    }
}
