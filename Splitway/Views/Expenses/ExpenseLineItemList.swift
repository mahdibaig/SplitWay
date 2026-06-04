import SwiftUI

/// Compact expandable list of the line items inside an Expense. Used as the
/// "drop down" on Home and the Expenses list, so the user can tap a Costco
/// purchase and see what was actually in it without opening detail view.
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
            VStack(spacing: 6) {
                ForEach(lineItems) { item in
                    row(for: item)
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func row(for item: LineItem) -> some View {
        HStack(spacing: 8) {
            if let cat = item.category {
                Image(systemName: cat.sfSymbol)
                    .font(.caption2)
                    .foregroundStyle(Color.categoryFg(cat))
                    .frame(width: 18, height: 18)
                    .background(Color.categoryBg(cat), in: .circle)
            } else {
                Image(systemName: "circle.dotted")
                    .font(.caption2)
                    .foregroundStyle(Color.text3)
                    .frame(width: 18, height: 18)
            }

            Text(item.displayName.isEmpty ? item.itemName : item.displayName)
                .font(.caption)
                .foregroundStyle(Color.text1)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(CurrencyFormat.usd(item.amount))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.text2)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.surface2, in: .rect(cornerRadius: 8))
    }
}
