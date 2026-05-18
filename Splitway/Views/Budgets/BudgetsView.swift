import SwiftUI

/// Main Budgets screen. Matches mockup 18: hero summary + per-category cards
/// with progress bars. Over-budget cards get a coral left border + coral text.
/// Accessed from Settings.
struct BudgetsView: View {
    @EnvironmentObject private var budgetService: BudgetService
    @EnvironmentObject private var expenseService: ExpenseService

    @State private var month: Date = Date()
    @State private var addBudgetCategory: ExpenseCategory?
    @State private var editingBudget: Budget?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                heroCard

                ForEach(budgetService.progress(for: month)) { progress in
                    Button {
                        if let b = budgetService.budgetsList.first(where: { $0.category == progress.category }) {
                            editingBudget = b
                        }
                    } label: {
                        BudgetProgressCard(progress: progress)
                    }
                    .buttonStyle(.plain)
                }

                addBudgetTile
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await expenseService.refresh()
            await budgetService.refresh()
        }
        .refreshable {
            await expenseService.refresh()
            await budgetService.refresh()
        }
        .sheet(item: $addBudgetCategory) { category in
            BudgetEditSheet(mode: .new(category: category))
        }
        .sheet(item: $editingBudget) { budget in
            BudgetEditSheet(mode: .edit(budget: budget))
        }
    }

    private var heroCard: some View {
        let totals = budgetService.monthlyTotals(for: month)
        let fraction: Double = {
            guard totals.limit > 0 else { return 0 }
            let s = NSDecimalNumber(decimal: totals.spent).doubleValue
            let l = NSDecimalNumber(decimal: totals.limit).doubleValue
            return min(1.0, max(0, s / l))
        }()
        let remaining = totals.limit - totals.spent

        return VStack(alignment: .leading, spacing: 6) {
            Text("\(monthLabel) budget")
                .font(.caption)
                .foregroundStyle(Color.ctaText.opacity(0.85))
                .textCase(.uppercase)
                .kerning(0.5)

            Text("\(CurrencyFormat.usd(totals.spent)) / \(CurrencyFormat.usd(totals.limit))")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.ctaText)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.25))
                    Capsule().fill(Color.ctaText)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            .padding(.top, 6)

            if totals.limit == 0 {
                Text("Set a budget to track spending this month.")
                    .font(.caption)
                    .foregroundStyle(Color.ctaText.opacity(0.85))
            } else if remaining >= 0 {
                Text("\(CurrencyFormat.usd(remaining)) left for the month")
                    .font(.caption)
                    .foregroundStyle(Color.ctaText.opacity(0.85))
            } else {
                Text("\(CurrencyFormat.usd(-remaining)) over budget")
                    .font(.caption)
                    .foregroundStyle(Color.ctaText.opacity(0.85))
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.brand, in: .rect(cornerRadius: Radius.card))
    }

    private var addBudgetTile: some View {
        let unbudgeted = ExpenseCategory.allCases.filter { c in
            !budgetService.budgetsList.contains(where: { $0.category == c })
        }

        return Menu {
            if unbudgeted.isEmpty {
                Text("All categories have budgets.")
            } else {
                ForEach(unbudgeted) { c in
                    Button {
                        addBudgetCategory = c
                    } label: {
                        Label(c.displayName, systemImage: c.sfSymbol)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add a budget").font(.cardLabel)
            }
            .foregroundStyle(Color.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.text3)
            )
        }
        .disabled(unbudgeted.isEmpty)
    }

    private var monthLabel: String {
        month.formatted(.dateTime.month(.wide))
    }
}

/// Per-category progress card. Bar uses the category color. Over-budget gets a
/// 3pt coral left border and coral status text.
struct BudgetProgressCard: View {
    let progress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.categoryBg(progress.category))
                    Image(systemName: progress.category.sfSymbol)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.categoryFg(progress.category))
                }
                .frame(width: 32, height: 32)

                Text(progress.category.displayName)
                    .font(.cardLabel.weight(.medium))
                    .foregroundStyle(Color.text1)

                Spacer()

                Text("\(CurrencyFormat.usd(progress.spent)) / \(CurrencyFormat.usd(progress.monthlyLimit))")
                    .font(.cardLabel.weight(.medium))
                    .foregroundStyle(progress.isOver ? Color.warn : Color.text1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.surface2)
                    Capsule().fill(progress.isOver ? Color.warn : Color.categoryFg(progress.category))
                        .frame(width: geo.size.width * progress.displayFraction)
                }
            }
            .frame(height: 4)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(progress.isOver ? Color.warn : Color.text2)
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        .overlay(alignment: .leading) {
            if progress.isOver {
                Rectangle()
                    .fill(Color.warn)
                    .frame(width: 3)
                    .clipShape(.rect(cornerRadii: .init(topLeading: Radius.card, bottomLeading: Radius.card)))
            }
        }
    }

    private var statusText: String {
        if progress.monthlyLimit == 0 {
            return "No limit set"
        } else if progress.isOver {
            return "\(CurrencyFormat.usd(progress.spent - progress.monthlyLimit)) over budget"
        } else if progress.spent == progress.monthlyLimit {
            return "Fully spent"
        } else {
            return "\(CurrencyFormat.usd(progress.remaining)) left this month"
        }
    }
}
