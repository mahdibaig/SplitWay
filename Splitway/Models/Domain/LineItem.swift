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
    /// Per-person unit counts (user UUID string -> units), e.g. Alice 2
    /// beers, Bob 1. When present and non-empty this overrides the equal
    /// `assignedToUserIDs` split: cost is shared proportionally to units.
    /// Optional so existing stored line items decode unchanged.
    var quantityPerUser: [String: Int]?
    var category: ExpenseCategory?

    init(
        id: UUID,
        itemName: String,
        displayName: String,
        normalizedItemName: String,
        amount: Decimal,
        quantity: Int,
        assignedToUserIDs: [UUID],
        category: ExpenseCategory?,
        quantityPerUser: [String: Int]? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.displayName = displayName
        self.normalizedItemName = normalizedItemName
        self.amount = amount
        self.quantity = quantity
        self.assignedToUserIDs = assignedToUserIDs
        self.quantityPerUser = quantityPerUser
        self.category = category
    }
}
