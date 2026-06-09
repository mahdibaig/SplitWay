import SwiftUI
import Charts

/// Reports tab. Matches mockup 12 plus two interactive controls:
///  - Scope toggle (Household / Just me) that flips the entire screen
///    between summed totals and the current user's share.
///  - Trend window picker (3/6/9/12 months) on the trend card.
struct ReportsView: View {
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var householdService: HouseholdService

    @EnvironmentObject private var subscriptions: SubscriptionService

    @State private var selectedMonth: Date = Date()
    @State private var scope: ReportScope = .household
    @State private var trendWindow: TrendWindow = .six
    @State private var showPaywall = false

    var body: some View {
        // Free tier: basic reports = current month, household only, no
        // trends. Pro unlocks scope toggle, month nav, and trends.
        let pro = subscriptions.canUse(.fullReports)
        let effectiveScope: ReportScope = pro ? scope : .household
        let effectiveMonth: Date = pro ? selectedMonth : Date()

        return NavigationStack {
            ScrollView {
                let snapshot = ReportSnapshot(
                    expenses: expenseService.expensesList,
                    selectedMonth: effectiveMonth,
                    scope: effectiveScope,
                    meID: householdService.currentMember?.id,
                    trendMonths: trendWindow.rawValue
                )

                VStack(spacing: Spacing.cardGap) {
                    if pro {
                        scopePicker
                        monthPicker
                    }
                    heroCard(snapshot: snapshot)

                    if snapshot.total > 0 || snapshot.priorTotal > 0 {
                        categoryCard(snapshot: snapshot)
                        if pro {
                            trendCard(snapshot: snapshot)
                        } else {
                            trendsUpsell
                        }
                        if !snapshot.topExpenses.isEmpty {
                            topExpensesCard(snapshot: snapshot)
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
                .padding(.bottom, 80)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Reports")
            .task { await expenseService.refresh() }
            .refreshable { await expenseService.refresh() }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .fullReports)
            }
        }
    }

    private var trendsUpsell: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Trends and personal view")
                        .font(.cardTitle)
                        .foregroundStyle(Color.text1)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brand)
                }
                Text("Splitway Pro adds 3, 6, 9, and 12-month trends, month-by-month history, and a Just-me spending breakdown.")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
                Text("See plans")
                    .font(.cardLabel.weight(.semibold))
                    .foregroundStyle(Color.brand2)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.cardPad)
            .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scope toggle

    private var scopePicker: some View {
        Picker("Scope", selection: $scope) {
            ForEach(ReportScope.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Month picker

    private var monthPicker: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.brand)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(monthLabel(selectedMonth))
                    .font(.cardTitle.weight(.medium))
                    .foregroundStyle(Color.text1)
                Text(canShiftForward ? "Tap to change" : "Latest month")
                    .font(.caption2)
                    .foregroundStyle(Color.text2)
            }
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(canShiftForward ? Color.brand : Color.text3)
                    .frame(width: 32, height: 32)
            }
            .disabled(!canShiftForward)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.surface, in: .rect(cornerRadius: 14))
    }

    // MARK: - Hero card

    private func heroCard(snapshot: ReportSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scope == .mine ? "You spent" : "Household spent")
                .font(.caption)
                .foregroundStyle(Color.ctaText.opacity(0.85))

            Text(CurrencyFormat.usd(snapshot.total))
                .font(.system(size: 32, weight: .medium))
                .kerning(-0.5)
                .foregroundStyle(Color.ctaText)

            if snapshot.priorTotal > 0 {
                HStack(spacing: 6) {
                    Image(systemName: snapshot.delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption)
                    Text(snapshot.comparisonText)
                        .font(.caption)
                }
                .foregroundStyle(Color.ctaText.opacity(0.9))
                .padding(.top, 4)
            } else if snapshot.total > 0 {
                Text("No prior month to compare yet.")
                    .font(.caption)
                    .foregroundStyle(Color.ctaText.opacity(0.85))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.brand, in: .rect(cornerRadius: 20))
    }

    // MARK: - Category donut

    private func categoryCard(snapshot: ReportSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By category")
                .font(.cardLabel.weight(.medium))
                .foregroundStyle(Color.text2)

            if snapshot.byCategory.isEmpty {
                Text("Nothing categorized this month.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
                    .padding(.vertical, 12)
            } else {
                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        Chart(snapshot.byCategory) { bucket in
                            SectorMark(
                                angle: .value("Amount", bucket.amount.doubleValue),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color.categoryFg(bucket.category))
                            .cornerRadius(2)
                        }
                        .frame(width: 120, height: 120)

                        VStack(spacing: 1) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(Color.text2)
                            Text(CurrencyFormat.usd(snapshot.total))
                                .font(.callout.weight(.medium))
                                .foregroundStyle(Color.text1)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(snapshot.byCategory.prefix(5)) { bucket in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.categoryFg(bucket.category))
                                    .frame(width: 10, height: 10)
                                Text(bucket.category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(Color.text1)
                                    .lineLimit(1)
                                Spacer()
                                Text(CurrencyFormat.usd(bucket.amount))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.text1)
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 18))
    }

    // MARK: - Trend card

    private func trendCard(snapshot: ReportSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Trend").font(.cardLabel.weight(.medium)).foregroundStyle(Color.text2)
                Spacer()
                Picker("Window", selection: $trendWindow) {
                    ForEach(TrendWindow.allCases, id: \.self) { w in
                        Text(w.label).tag(w)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            Chart(snapshot.trend) { month in
                BarMark(
                    x: .value("Month", month.label),
                    y: .value("Total", month.total.doubleValue),
                    width: barWidth
                )
                .foregroundStyle(month.isCurrent ? Color.brand : Color.surface3)
                .cornerRadius(4)
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel(centered: true) {
                        if let label = value.as(String.self) {
                            let isCurrent = snapshot.trend.first { $0.label == label }?.isCurrent ?? false
                            Text(label)
                                .font(.caption2.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(isCurrent ? Color.text1 : Color.text2)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)

            Divider().background(Color.divider)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly average")
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                    Text(CurrencyFormat.usd(snapshot.monthlyAverage))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.text1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("vs last month")
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                    Text(snapshot.percentChangeText)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(snapshot.delta <= 0 ? Color.success : Color.warn)
                }
            }
        }
        .padding(Spacing.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 18))
    }

    /// Thinner bars as the window grows so 12 still reads.
    private var barWidth: MarkDimension {
        switch trendWindow {
        case .three:  return 36
        case .six:    return 24
        case .nine:   return 18
        case .twelve: return 14
        }
    }

    // MARK: - Top expenses

    private func topExpensesCard(snapshot: ReportSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scope == .mine ? "Your biggest contributions this month" : "Top expenses this month")
                .font(.cardLabel.weight(.medium))
                .foregroundStyle(Color.text2)
                .padding(.bottom, 4)

            ForEach(snapshot.topExpenses.indices, id: \.self) { idx in
                let row = snapshot.topExpenses[idx]
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.categoryBg(row.expense.category))
                        Image(systemName: row.expense.category.sfSymbol)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.categoryFg(row.expense.category))
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.expense.description.isEmpty ? row.expense.category.displayName : row.expense.description)
                            .font(.cardLabel.weight(.medium))
                            .foregroundStyle(Color.text1)
                        Text("\(row.expense.date.formatted(.dateTime.month(.abbreviated).day())) · \(row.expense.splitRule.type.displayName)")
                            .font(.caption2)
                            .foregroundStyle(Color.text2)
                    }

                    Spacer()

                    Text(CurrencyFormat.usd(row.contribution))
                        .font(.cardLabel.weight(.medium))
                        .foregroundStyle(Color.text1)
                }
                .padding(.vertical, 8)
                if idx < snapshot.topExpenses.count - 1 {
                    Divider().background(Color.divider)
                }
            }
        }
        .padding(Spacing.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 18))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.system(size: 36))
                .foregroundStyle(Color.text3)
            Text(scope == .mine ? "Nothing to chart yet" : "Nothing to chart yet")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text(scope == .mine
                 ? "Log expenses and your personal share will show up here."
                 : "Log some expenses this month and they'll show up here.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Navigation helpers

    private var canShiftForward: Bool {
        let cal = Calendar(identifier: .gregorian)
        return !cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        let cal = Calendar(identifier: .gregorian)
        if let next = cal.date(byAdding: .month, value: delta, to: selectedMonth) {
            if delta > 0, next > Date() {
                selectedMonth = Date()
            } else {
                selectedMonth = next
            }
        }
    }

    private func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

// MARK: - Scope + trend window

enum ReportScope: String, Hashable, CaseIterable {
    case household
    case mine

    var label: String {
        switch self {
        case .household: return "Household"
        case .mine:      return "Just me"
        }
    }
}

enum TrendWindow: Int, Hashable, CaseIterable {
    case three = 3
    case six = 6
    case nine = 9
    case twelve = 12

    var label: String { "\(rawValue)M" }
}

// MARK: - Snapshot

/// Pure value type that summarizes a single month for rendering. Built once
/// per view body and read by every card. Honors the current scope so the
/// same view code handles both "Household" and "Just me" without branches.
private struct ReportSnapshot {

    struct CategoryBucket: Identifiable, Hashable {
        let category: ExpenseCategory
        let amount: Decimal
        var id: String { category.rawValue }
    }

    struct MonthBucket: Identifiable, Hashable {
        let date: Date
        let label: String
        let total: Decimal
        let isCurrent: Bool
        var id: String { ISO8601DateFormatter().string(from: date) }
    }

    struct TopRow: Identifiable, Hashable {
        let expense: Expense
        let contribution: Decimal
        var id: UUID { expense.id }
    }

    let total: Decimal
    let priorTotal: Decimal
    let delta: Decimal
    let byCategory: [CategoryBucket]
    let topExpenses: [TopRow]
    let trend: [MonthBucket]
    let monthlyAverage: Decimal

    init(
        expenses: [Expense],
        selectedMonth: Date,
        scope: ReportScope,
        meID: UserID?,
        trendMonths: Int
    ) {
        let cal = Calendar(identifier: .gregorian)
        let active = expenses.filter { $0.softDeletedAt == nil }

        // Per-expense "what's relevant for this scope?":
        //   Household: full amount.
        //   Just me:   user's share per the split rule.
        func contribution(of expense: Expense) -> Decimal {
            switch scope {
            case .household:
                return expense.amount
            case .mine:
                guard let meID else { return 0 }
                return BalanceService.impact(of: expense, for: meID).share
            }
        }

        func monthExpenses(_ d: Date) -> [Expense] {
            guard let interval = cal.dateInterval(of: .month, for: d) else { return [] }
            return active.filter { interval.contains($0.date) }
        }

        let monthly = monthExpenses(selectedMonth)
        self.total = monthly.reduce(.zero) { $0 + contribution(of: $1) }

        let priorDate = cal.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let priorMonthly = monthExpenses(priorDate)
        self.priorTotal = priorMonthly.reduce(.zero) { $0 + contribution(of: $1) }
        self.delta = self.total - self.priorTotal

        var sums: [ExpenseCategory: Decimal] = [:]
        for e in monthly {
            let c = contribution(of: e)
            guard c > 0 else { continue }
            // Walks per-line-item categories when available so a Costco
            // trip lands in groceries + household supplies (etc.) rather
            // than the single headline category.
            for (cat, amt) in e.categoryDistribution(of: c) {
                sums[cat, default: 0] += amt
            }
        }
        self.byCategory = sums
            .map { CategoryBucket(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        let scored: [TopRow] = monthly
            .map { TopRow(expense: $0, contribution: contribution(of: $0)) }
            .filter { $0.contribution > 0 }
            .sorted { $0.contribution > $1.contribution }
        self.topExpenses = Array(scored.prefix(5))

        var buckets: [MonthBucket] = []
        for offset in (0..<trendMonths).reversed() {
            guard let d = cal.date(byAdding: .month, value: -offset, to: selectedMonth) else { continue }
            let label = d.formatted(.dateTime.month(.abbreviated))
            let t = monthExpenses(d).reduce(Decimal.zero) { $0 + contribution(of: $1) }
            let isCurrent = cal.isDate(d, equalTo: selectedMonth, toGranularity: .month)
            buckets.append(MonthBucket(date: d, label: label, total: t, isCurrent: isCurrent))
        }
        self.trend = buckets

        let totalAcrossWindow = buckets.reduce(Decimal.zero) { $0 + $1.total }
        self.monthlyAverage = trendMonths > 0
            ? totalAcrossWindow / Decimal(trendMonths)
            : 0
    }

    var comparisonText: String {
        let absDelta = abs(delta)
        if delta < 0 {
            return "\(CurrencyFormat.usd(absDelta)) less than last month"
        } else if delta > 0 {
            return "\(CurrencyFormat.usd(absDelta)) more than last month"
        } else {
            return "Same as last month"
        }
    }

    var percentChangeText: String {
        guard priorTotal > 0 else { return "—" }
        let pct = (delta as NSDecimalNumber).doubleValue
            / (priorTotal as NSDecimalNumber).doubleValue * 100.0
        let rounded = Int(pct.rounded())
        if rounded > 0 { return "+\(rounded)%" }
        if rounded < 0 { return "−\(abs(rounded))%" }
        return "0%"
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
