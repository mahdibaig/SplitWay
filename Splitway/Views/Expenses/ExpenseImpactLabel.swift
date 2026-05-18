import SwiftUI

/// Compact per-row line showing what the user actually spent on this expense
/// (their share of the bill, regardless of who paid up front). The net
/// "owed / owe" view lives in the Who Owes Who card on the Expenses tab and
/// the balance hero on Home, so per-row stays a personal-spend lens.
struct ExpenseImpactLabel: View {
    let expense: Expense
    let meID: UserID?

    var body: some View {
        if let meID {
            let impact = BalanceService.impact(of: expense, for: meID)
            content(for: impact)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func content(for impact: ExpenseUserImpact) -> some View {
        if impact.isExcluded {
            Text("Not on you")
                .font(.cardLabel)
                .foregroundStyle(Color.text3)
        } else {
            Text("You paid \(CurrencyFormat.usd(impact.share))")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
        }
    }
}
