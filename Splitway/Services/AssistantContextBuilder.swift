import Foundation

/// Snapshots the household's current financial state into a JSON string the
/// assistant can read. Kept compact so prompt tokens stay reasonable. Only
/// non-sensitive identifiers (display names) are included, never Apple IDs.
@MainActor
struct AssistantContextBuilder {

    let householdService: HouseholdService
    let membersService: MembersService
    let expenseService: ExpenseService
    let settlementService: SettlementService
    let budgetService: BudgetService
    let recurringService: RecurringService

    func snapshotJSON(now: Date = Date()) -> String {
        let snapshot = buildSnapshot(now: now)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private func buildSnapshot(now: Date) -> Snapshot {
        let me = householdService.currentMember
        let members = membersService.members.filter { !$0.isArchived }
        let memberByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.displayName) })

        let cal = Calendar(identifier: .gregorian)
        let thisMonth = cal.dateInterval(of: .month, for: now)
        let lastMonthStart = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let lastMonth = cal.dateInterval(of: .month, for: lastMonthStart)

        let activeExpenses = expenseService.expensesList.filter { $0.softDeletedAt == nil }
        let thisMonthExpenses = activeExpenses.filter { thisMonth?.contains($0.date) ?? false }
        let lastMonthExpenses = activeExpenses.filter { lastMonth?.contains($0.date) ?? false }

        // Balances
        let memberIDs = members.map(\.id)
        let balances = BalanceService.balances(
            for: memberIDs,
            expenses: activeExpenses,
            settlements: settlementService.settlementsList,
            groupMembership: [:]
        )
        let simplified = BalanceService.simplify(balances)

        return Snapshot(
            currentDate: ISO8601DateFormatter().string(from: now),
            currency: "USD",
            you: me.map { SnapshotMember(id: $0.id.raw.uuidString, name: $0.displayName) },
            household: SnapshotHousehold(
                name: householdService.currentHousehold?.name ?? "",
                members: members.map { SnapshotMember(id: $0.id.raw.uuidString, name: $0.displayName) }
            ),
            balances: balances.map {
                SnapshotBalance(
                    member: memberByID[$0.id] ?? "?",
                    net: $0.net.doubleValue
                )
            },
            simplifiedPayments: simplified.map {
                SnapshotPayment(
                    from: memberByID[$0.from] ?? "?",
                    to: memberByID[$0.to] ?? "?",
                    amount: $0.amount.doubleValue
                )
            },
            currentMonth: buildMonth(label: monthLabel(now), expenses: thisMonthExpenses, memberByID: memberByID),
            previousMonth: buildMonth(label: monthLabel(lastMonthStart), expenses: lastMonthExpenses, memberByID: memberByID),
            budgets: budgetService.progress(for: now).map {
                SnapshotBudget(
                    category: $0.category.displayName,
                    limit: $0.monthlyLimit.doubleValue,
                    spent: $0.spent.doubleValue,
                    over: $0.isOver
                )
            },
            recurring: recurringService.templates.filter(\.isActive).map {
                SnapshotRecurring(
                    description: $0.description,
                    category: $0.category.displayName,
                    amount: $0.amount?.doubleValue,
                    variable: $0.isVariableAmount,
                    dayOfMonth: $0.dayOfMonth
                )
            },
            recentExpenses: Array(activeExpenses.prefix(20)).map { e in
                SnapshotExpense(
                    description: e.description,
                    category: e.category.displayName,
                    amount: e.amount.doubleValue,
                    date: ISO8601DateFormatter().string(from: e.date),
                    payer: e.splitRule.paidBy.first.flatMap { memberByID[UserID($0.userID)] }
                )
            }
        )
    }

    private func buildMonth(label: String, expenses: [Expense], memberByID: [UserID: String]) -> SnapshotMonth {
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        var byCategory: [String: Decimal] = [:]
        for e in expenses {
            // Walk per-line-item categories so a Costco trip is split
            // correctly across groceries / household supplies / etc.
            for (cat, amt) in e.categoryDistribution(of: e.amount) {
                byCategory[cat.displayName, default: 0] += amt
            }
        }
        return SnapshotMonth(
            label: label,
            total: total.doubleValue,
            byCategory: byCategory.mapValues { $0.doubleValue }
        )
    }

    private func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Snapshot DTOs

    struct Snapshot: Encodable {
        let currentDate: String
        let currency: String
        let you: SnapshotMember?
        let household: SnapshotHousehold
        let balances: [SnapshotBalance]
        let simplifiedPayments: [SnapshotPayment]
        let currentMonth: SnapshotMonth
        let previousMonth: SnapshotMonth
        let budgets: [SnapshotBudget]
        let recurring: [SnapshotRecurring]
        let recentExpenses: [SnapshotExpense]
    }
    struct SnapshotMember: Encodable { let id: String; let name: String }
    struct SnapshotHousehold: Encodable { let name: String; let members: [SnapshotMember] }
    struct SnapshotBalance: Encodable { let member: String; let net: Double }
    struct SnapshotPayment: Encodable { let from: String; let to: String; let amount: Double }
    struct SnapshotMonth: Encodable { let label: String; let total: Double; let byCategory: [String: Double] }
    struct SnapshotBudget: Encodable {
        let category: String; let limit: Double; let spent: Double; let over: Bool
    }
    struct SnapshotRecurring: Encodable {
        let description: String; let category: String; let amount: Double?; let variable: Bool; let dayOfMonth: Int
    }
    struct SnapshotExpense: Encodable {
        let description: String; let category: String; let amount: Double; let date: String; let payer: String?
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
