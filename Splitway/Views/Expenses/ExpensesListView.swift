import SwiftUI

struct ExpensesListView: View {
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var settlementService: SettlementService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var groupService: GroupService

    @StateObject private var holder = ExpensesListVMHolder()
    @State private var showSettleUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                if let vm = holder.viewModel {
                    ExpensesListContent(viewModel: vm, showSettleUp: $showSettleUp)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Expenses")
            .task {
                if holder.viewModel == nil {
                    holder.viewModel = ExpensesListViewModel(expenseService: expenseService)
                }
                await expenseService.refresh()
                await settlementService.refresh()
                await membersService.refresh()
                await groupService.refresh()
            }
            .sheet(isPresented: $showSettleUp) {
                SettleUpView()
            }
        }
    }
}

@MainActor
private final class ExpensesListVMHolder: ObservableObject {
    @Published var viewModel: ExpensesListViewModel?
}

private struct ExpensesListContent: View {
    @ObservedObject var viewModel: ExpensesListViewModel
    @Binding var showSettleUp: Bool

    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var settlementService: SettlementService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var groupService: GroupService

    var body: some View {
        let memberIDs = membersService.members.map(\.id)
        let groupMembership = membersService.groupMembership
        let balances = BalanceService.balances(
            for: memberIDs,
            expenses: expenseService.expensesList,
            settlements: settlementService.settlementsList,
            groupMembership: groupMembership
        )
        let payments = BalanceService.simplify(balances)
        let groupBalances = BalanceService.groupBalances(
            from: balances,
            groupMembership: groupMembership
        )
        let groupPayments = BalanceService.simplifyGroups(groupBalances)
        let groupsAvailable = (householdService.currentHousehold?.groupsEnabled ?? false)
            && groupMembership.count >= 2

        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                WhoOwesWhoCard(
                    payments: payments,
                    groupPayments: groupPayments,
                    members: membersService.members,
                    groups: groupService.groupsList,
                    groupsAvailable: groupsAvailable,
                    onTapSettleUp: { showSettleUp = true }
                )

                monthBar

                ForEach(viewModel.sections) { section in
                    sectionHeader(section.title)
                    ForEach(section.expenses) { expense in
                        expenseRow(expense)
                    }
                }

                if viewModel.sections.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
            .padding(.bottom, 80)
        }
        .refreshable {
            await expenseService.refresh()
            await settlementService.refresh()
        }
    }

    private var monthBar: some View {
        HStack {
            Button { viewModel.incrementMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(viewModel.monthLabel)
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Spacer()
            Button { viewModel.incrementMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(Color.text2)
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.cardLabel)
            .foregroundStyle(Color.text2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func expenseRow(_ expense: Expense) -> some View {
        let payer = membersService.members.first {
            $0.id == UserID(expense.splitRule.paidBy.first?.userID ?? UUID())
        }
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile).fill(Color.categoryBg(expense.category))
                Image(systemName: expense.category.sfSymbol).foregroundStyle(Color.categoryFg(expense.category))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(expense.description.isEmpty ? expense.category.displayName : expense.description)
                        .font(.cardTitle)
                        .foregroundStyle(Color.text1)
                    if expense.receiptImageData != nil {
                        Image(systemName: "paperclip")
                            .font(.caption2)
                            .foregroundStyle(Color.text3)
                            .accessibilityLabel("Has receipt")
                    }
                }
                Text("\(payer?.displayName ?? "Someone") · \(expense.splitRule.type.displayName)")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormat.usd(expense.amount))
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
                ExpenseImpactLabel(expense: expense, meID: householdService.currentMember?.id)
            }
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray").font(.system(size: 36)).foregroundStyle(Color.text3)
            Text("No expenses yet")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text("Tap the + button to log your first one.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
