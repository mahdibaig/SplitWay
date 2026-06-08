import SwiftUI

/// Compact expandable list of the line items inside an Expense, grouped by
/// category with subtotals. Used as the "drop down" on Home and the
/// Expenses list — tap an expense row to reveal the breakdown without
/// opening a detail view.
struct ExpenseLineItemList: View {
    let lineItems: [LineItem]

    var body: some View {
        if lineItems.isEmpty {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
                Text("No line items on this expense.")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
            .padding(.top, 6)
        } else {
            VStack(spacing: 10) {
                ForEach(grouped, id: \.key) { group in
                    categorySection(category: group.category, items: group.items, subtotal: group.subtotal)
                }
            }
            .padding(.top, 8)
        }
    }

    /// Bucket items by category, preserve first-appearance order, sum each.
    private struct Group {
        let key: String          // ExpenseCategory.rawValue, or "" for "Uncategorized"
        let category: ExpenseCategory?
        let items: [LineItem]
        let subtotal: Decimal
    }

    private var grouped: [Group] {
        var order: [ExpenseCategory?] = []
        var byCat: [String: [LineItem]] = [:]
        for li in lineItems {
            let key = li.category?.rawValue ?? ""
            if byCat[key] == nil { order.append(li.category) }
            byCat[key, default: []].append(li)
        }
        return order.map { cat in
            let key = cat?.rawValue ?? ""
            let items = byCat[key] ?? []
            let subtotal = items.reduce(Decimal.zero) { $0 + $1.amount }
            return Group(key: key, category: cat, items: items, subtotal: subtotal)
        }
    }

    @ViewBuilder
    private func categorySection(category: ExpenseCategory?, items: [LineItem], subtotal: Decimal) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                if let cat = category {
                    Image(systemName: cat.sfSymbol)
                        .font(.caption2)
                        .foregroundStyle(Color.categoryFg(cat))
                        .frame(width: 18, height: 18)
                        .background(Color.categoryBg(cat), in: .circle)
                    Text(cat.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.text1)
                } else {
                    Image(systemName: "circle.dotted")
                        .font(.caption2)
                        .foregroundStyle(Color.text3)
                        .frame(width: 18, height: 18)
                    Text("Uncategorized")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.text2)
                }
                Spacer(minLength: 8)
                Text(CurrencyFormat.usd(subtotal))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.text1)
            }
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Spacer().frame(width: 18)
                    Text(item.displayName.isEmpty ? item.itemName : item.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(CurrencyFormat.usd(item.amount))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.text3)
                }
            }
        }
        .padding(8)
        .background(Color.surface2, in: .rect(cornerRadius: 10))
    }
}
