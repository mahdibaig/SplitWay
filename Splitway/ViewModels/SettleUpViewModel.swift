import Foundation

@MainActor
final class SettleUpViewModel: ObservableObject {

    private let expenseService: ExpenseService
    private let settlementService: SettlementService
    private let membersService: MembersService

    @Published private(set) var payments: [SimplifiedPayment] = []
    @Published private(set) var isWorking = false

    init(expenseService: ExpenseService, settlementService: SettlementService, membersService: MembersService) {
        self.expenseService = expenseService
        self.settlementService = settlementService
        self.membersService = membersService
    }

    func refresh() async {
        await expenseService.refresh()
        await settlementService.refresh()
        await membersService.refresh()
        recompute()
    }

    func recompute() {
        let memberIDs = membersService.members.map(\.id)
        let balances = BalanceService.balances(
            for: memberIDs,
            expenses: expenseService.expensesList,
            settlements: settlementService.settlementsList,
            groupMembership: [:]
        )
        payments = BalanceService.simplify(balances)
    }

    func markPaid(_ payment: SimplifiedPayment) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await settlementService.markPaid(
                from: payment.from,
                to: payment.to,
                amount: payment.amount,
                method: nil
            )
            recompute()
        } catch {
            AppLog.ui.error("Mark paid failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
