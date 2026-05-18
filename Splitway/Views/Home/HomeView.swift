import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var settlementService: SettlementService
    @EnvironmentObject private var budgetService: BudgetService
    @EnvironmentObject private var recurringService: RecurringService

    @State private var showVariableSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.cardGap) {
                    greetingHeader()
                    balanceHero()
                    variableDueBanner()
                    budgetSummarySection()
                    recentExpensesSection()
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
                .padding(.bottom, 80)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle(householdService.currentHousehold?.name ?? "Splitway")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await householdService.refresh()
                await membersService.refresh()
                await expenseService.refresh()
                await settlementService.refresh()
                await budgetService.refresh()
                await recurringService.refresh()
            }
            .refreshable {
                await expenseService.refresh()
                await settlementService.refresh()
                await budgetService.refresh()
                await recurringService.refresh()
            }
            .sheet(isPresented: $showVariableSheet) {
                VariableAmountSheet()
            }
        }
    }

    @ViewBuilder
    private func variableDueBanner() -> some View {
        let pending = recurringService.pendingVariable
        if !pending.isEmpty {
            Button { showVariableSheet = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title3)
                        .foregroundStyle(Color.warn)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pending.count == 1 ? "1 bill due" : "\(pending.count) bills due")
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                        Text("Tap to enter this month's amount.")
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.text3)
                }
                .padding(Spacing.cardPad)
                .background(Color.warnSoft, in: .rect(cornerRadius: Radius.card))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func greetingHeader() -> some View {
        let name = householdService.currentMember?.displayName ?? ""
        let greeting = greeting(for: Date())
        Text("\(greeting)\(name.isEmpty ? "" : ", \(name)")")
            .font(.serifTitle)
            .foregroundStyle(Color.text1)
            .padding(.top, 8)
    }

    @ViewBuilder
    private func balanceHero() -> some View {
        let myID = householdService.currentMember?.id
        let memberIDs = membersService.members.map(\.id)
        let balances = BalanceService.balances(
            for: memberIDs,
            expenses: expenseService.expensesList,
            settlements: settlementService.settlementsList,
            groupMembership: [:]
        )
        let myBalance = balances.first { $0.id == myID }?.net ?? .zero

        VStack(alignment: .leading, spacing: 8) {
            Text(label(forBalance: myBalance))
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text(CurrencyFormat.usd(abs(myBalance)))
                .font(.bigNumber)
                .foregroundStyle(myBalance < 0 ? Color.warn : (myBalance > 0 ? Color.success : Color.text1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private func budgetSummarySection() -> some View {
        let progresses = budgetService.progress(for: Date())
        if !progresses.isEmpty {
            let overCount = progresses.filter(\.isOver).count
            NavigationLink {
                BudgetsView()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("This month's budgets")
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.text3)
                    }
                    if overCount > 0 {
                        Text(overCount == 1
                             ? "1 category over budget"
                             : "\(overCount) categories over budget")
                            .font(.cardLabel.weight(.medium))
                            .foregroundStyle(Color.warn)
                    } else {
                        Text("On track")
                            .font(.cardLabel)
                            .foregroundStyle(Color.success)
                    }
                    miniProgressBars(progresses: Array(progresses.prefix(4)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.cardPad)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func miniProgressBars(progresses: [BudgetProgress]) -> some View {
        VStack(spacing: 8) {
            ForEach(progresses) { p in
                HStack(spacing: 8) {
                    Image(systemName: p.category.sfSymbol)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.categoryFg(p.category))
                        .frame(width: 14)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.surface2)
                            Capsule().fill(p.isOver ? Color.warn : Color.categoryFg(p.category))
                                .frame(width: geo.size.width * p.displayFraction)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
    }

    @ViewBuilder
    private func recentExpensesSection() -> some View {
        Text("Recent")
            .font(.cardLabel)
            .foregroundStyle(Color.text2)
            .padding(.top, 12)

        let recents = Array(expenseService.expensesList.prefix(5))
        if recents.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("No expenses yet.")
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
                Text("Tap the + button to log your first one.")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.cardPad)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        } else {
            ForEach(recents) { expense in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.tile).fill(Color.categoryBg(expense.category))
                        Image(systemName: expense.category.sfSymbol).foregroundStyle(Color.categoryFg(expense.category))
                    }
                    .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(expense.description.isEmpty ? expense.category.displayName : expense.description)
                            .font(.cardTitle).foregroundStyle(Color.text1)
                        Text(expense.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.cardLabel).foregroundStyle(Color.text2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormat.usd(expense.amount))
                            .font(.cardTitle).foregroundStyle(Color.text1)
                        ExpenseImpactLabel(expense: expense, meID: householdService.currentMember?.id)
                    }
                }
                .padding(Spacing.cardPad)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))
            }
        }
    }

    private func label(forBalance balance: Decimal) -> String {
        if balance > 0 { return "You're owed" }
        if balance < 0 { return "You owe" }
        return "All settled up"
    }

    private func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hi"
        }
    }
}
