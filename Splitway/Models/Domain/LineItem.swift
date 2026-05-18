import Foundation

/// One line on a receipt. Lives inside an `Expense` (JSON-encoded on disk).
/// `assignedToUserIDs` defaults to "all participants on the expense" when
/// empty, mirroring the spec's "always shared" default.
struct LineItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var itemName: String          // raw OCR text (e.g., "WHL MLK GAL")
    var displayName: String       // cleaned (e.g., "Whole milk gallon"), falls back to itemName
    var normalizedItemName: String  // lowercased/stripped, for fuzzy match in Phase 4 learning
    var amount: Decimal
    var quantity: Int
    var assignedToUserIDs: [UUID] // empty = shared by all expense participants
    var category: ExpenseCategory?
}
