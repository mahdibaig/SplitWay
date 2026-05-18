import Foundation

/// Computes per-user balances and simplifies them into a minimal set of
/// payments. All math is pure given the inputs, easy to unit-test.
struct BalanceService {

    /// Per-user net balance: positive = owed money, negative = owes money.
    static func balances(
        for memberIDs: [UserID],
        expenses: [Expense],
        settlements: [Settlement],
        groupMembership: [GroupID: [UserID]]
    ) -> [UserBalance] {
        var net: [UserID: Decimal] = Dictionary(uniqueKeysWithValues: memberIDs.map { ($0, .zero) })

        for expense in expenses where expense.softDeletedAt == nil {
            // Credit: amount paid by each payer.
            for paid in expense.splitRule.paidBy {
                net[UserID(paid.userID), default: 0] += paid.amount
            }

            // Debit: each participant's share.
            let shares = SplitResolver.resolveUserShares(
                rule: expense.splitRule,
                total: expense.amount,
                groupMembership: groupMembership
            )
            for (user, amount) in shares {
                net[user, default: 0] -= amount
            }
        }

        for s in settlements {
            // Sender's debt goes down (they paid), receiver gets less owed to them.
            net[s.fromUserID, default: 0] += s.amount
            net[s.toUserID, default: 0]   -= s.amount
        }

        return memberIDs.map { UserBalance(id: $0, net: net[$0] ?? .zero) }
    }

    /// Returns one user's impact on a single expense (share owed, amount paid).
    /// Pure function so views can call it during rendering.
    static func impact(of expense: Expense, for userID: UserID, groupMembership: [GroupID: [UserID]] = [:]) -> ExpenseUserImpact {
        let shares = SplitResolver.resolveUserShares(
            rule: expense.splitRule,
            total: expense.amount,
            groupMembership: groupMembership
        )
        let share = shares[userID] ?? .zero
        let paid = expense.splitRule.paidBy
            .filter { UserID($0.userID) == userID }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return ExpenseUserImpact(share: share, paid: paid)
    }

    /// Greedy debt simplification: pair the biggest debtor with the biggest
    /// creditor until everyone is settled. Minimizes number of payments.
    static func simplify(_ balances: [UserBalance]) -> [SimplifiedPayment] {
        var creditors = balances.filter { $0.net > 0 }.sorted { $0.net > $1.net }
        var debtors   = balances.filter { $0.net < 0 }.sorted { $0.net < $1.net }
        var payments: [SimplifiedPayment] = []

        while let c = creditors.first, let d = debtors.first {
            let pay = min(c.net, -d.net)
            payments.append(SimplifiedPayment(from: d.id, to: c.id, amount: pay))

            var newC = c; newC.net -= pay
            var newD = d; newD.net += pay

            if newC.net == 0 { creditors.removeFirst() } else { creditors[0] = newC }
            if newD.net == 0 { debtors.removeFirst()   } else { debtors[0] = newD }
        }
        return payments
    }

    /// Rolls per-user balances up into per-group balances by summing each
    /// group's members. Members not in any group are dropped (the caller
    /// shouldn't show group mode when most members are ungrouped anyway).
    static func groupBalances(
        from userBalances: [UserBalance],
        groupMembership: [GroupID: [UserID]]
    ) -> [GroupBalance] {
        var net: [GroupID: Decimal] = Dictionary(
            uniqueKeysWithValues: groupMembership.keys.map { ($0, .zero) }
        )
        // Build reverse lookup so each user is mapped to at most one group.
        var userToGroup: [UserID: GroupID] = [:]
        for (gid, users) in groupMembership {
            for u in users { userToGroup[u] = gid }
        }
        for balance in userBalances {
            if let gid = userToGroup[balance.id] {
                net[gid, default: 0] += balance.net
            }
        }
        return net.map { GroupBalance(id: $0.key, net: $0.value) }
            .sorted { $0.id.raw.uuidString < $1.id.raw.uuidString }
    }

    /// Same greedy simplification as `simplify(_:)`, typed for groups.
    static func simplifyGroups(_ balances: [GroupBalance]) -> [SimplifiedGroupPayment] {
        var creditors = balances.filter { $0.net > 0 }.sorted { $0.net > $1.net }
        var debtors   = balances.filter { $0.net < 0 }.sorted { $0.net < $1.net }
        var payments: [SimplifiedGroupPayment] = []

        while let c = creditors.first, let d = debtors.first {
            let pay = min(c.net, -d.net)
            payments.append(SimplifiedGroupPayment(from: d.id, to: c.id, amount: pay))

            var newC = c; newC.net -= pay
            var newD = d; newD.net += pay

            if newC.net == 0 { creditors.removeFirst() } else { creditors[0] = newC }
            if newD.net == 0 { debtors.removeFirst()   } else { debtors[0] = newD }
        }
        return payments
    }
}
