import Foundation

/// Pure functions that turn a `SplitRule` + a total into per-user amounts owed.
/// All math is `Decimal`; cents are rounded with banker's rounding and any
/// stray pennies are distributed to the first N participants so totals always
/// reconcile to the cent.
enum SplitResolver {

    /// Errors users can hit during validation, keyed back to the form.
    enum ValidationError: Error, LocalizedError, Equatable {
        case noParticipants
        case percentagesMustSumTo100(actual: Decimal)
        case amountsMustSumToTotal(actual: Decimal, expected: Decimal)
        case sharesMustBeNonZero
        case paidByMustSumToTotal(actual: Decimal, expected: Decimal)

        var errorDescription: String? {
            switch self {
            case .noParticipants:                       return "Pick at least one person."
            case .percentagesMustSumTo100(let a):       return "Percentages add up to \(a)%, need 100%."
            case .amountsMustSumToTotal(let a, let e):  return "Amounts add up to \(a), need \(e)."
            case .sharesMustBeNonZero:                  return "Shares must be greater than zero."
            case .paidByMustSumToTotal(let a, let e):   return "'Paid by' adds up to \(a), need \(e)."
            }
        }
    }

    /// Validates the rule against an expense total. Returns nil if OK.
    static func validate(_ rule: SplitRule, total: Decimal) -> ValidationError? {
        guard !rule.participantIDs.isEmpty else { return .noParticipants }

        let paidByTotal = rule.paidBy.reduce(Decimal.zero) { $0 + $1.amount }
        if paidByTotal != total {
            return .paidByMustSumToTotal(actual: paidByTotal, expected: total)
        }

        switch rule.type {
        case .equal, .excluded:
            return nil

        case .percentages:
            let sum = rule.participantValues.reduce(Decimal.zero) { $0 + $1.value }
            return sum == 100 ? nil : .percentagesMustSumTo100(actual: sum)

        case .amounts:
            let sum = rule.participantValues.reduce(Decimal.zero) { $0 + $1.value }
            return sum == total ? nil : .amountsMustSumToTotal(actual: sum, expected: total)

        case .shares:
            let sum = rule.participantValues.reduce(Decimal.zero) { $0 + $1.value }
            return sum > 0 ? nil : .sharesMustBeNonZero
        }
    }

    /// Expands group participants to user IDs. For .equal/.excluded with groups,
    /// the share is split equally among the resolved users.
    static func resolveUserShares(
        rule: SplitRule,
        total: Decimal,
        groupMembership: [GroupID: [UserID]]
    ) -> [UserID: Decimal] {
        let resolvedUsers: [UserID] = rule.participantIDs.flatMap { id -> [UserID] in
            if rule.participantsAreGroups {
                let gid = GroupID(id)
                return groupMembership[gid] ?? []
            } else {
                return [UserID(id)]
            }
        }

        guard !resolvedUsers.isEmpty else { return [:] }

        switch rule.type {
        case .equal, .excluded:
            return equalShares(among: resolvedUsers, total: total)

        case .percentages:
            return percentShares(
                rule: rule,
                total: total,
                groupMembership: groupMembership
            )

        case .amounts:
            return amountShares(rule: rule, groupMembership: groupMembership)

        case .shares:
            return shareShares(
                rule: rule,
                total: total,
                groupMembership: groupMembership
            )
        }
    }

    // MARK: - Internals

    private static func equalShares(among users: [UserID], total: Decimal) -> [UserID: Decimal] {
        let count = Decimal(users.count)
        var per = total / count
        per = per.roundedDownTo(places: 2)
        let allocated = per * count
        var remainder = total - allocated  // remaining pennies
        var result: [UserID: Decimal] = [:]
        let onePenny = Decimal(string: "0.01") ?? .zero

        for user in users {
            var amount = per
            if remainder > 0 {
                amount += onePenny
                remainder -= onePenny
            }
            result[user] = amount
        }
        return result
    }

    private static func percentShares(rule: SplitRule, total: Decimal, groupMembership: [GroupID: [UserID]]) -> [UserID: Decimal] {
        var raw: [UserID: Decimal] = [:]
        for pv in rule.participantValues {
            let amount = (total * pv.value / 100).roundedDownTo(places: 2)
            distribute(amount, participant: pv.participantID, isGroup: rule.participantsAreGroups,
                       groupMembership: groupMembership, into: &raw)
        }
        return reconcilePennies(raw: raw, total: total)
    }

    private static func amountShares(rule: SplitRule, groupMembership: [GroupID: [UserID]]) -> [UserID: Decimal] {
        var raw: [UserID: Decimal] = [:]
        for pv in rule.participantValues {
            distribute(pv.value, participant: pv.participantID, isGroup: rule.participantsAreGroups,
                       groupMembership: groupMembership, into: &raw)
        }
        return raw
    }

    private static func shareShares(rule: SplitRule, total: Decimal, groupMembership: [GroupID: [UserID]]) -> [UserID: Decimal] {
        let totalShares = rule.participantValues.reduce(Decimal.zero) { $0 + $1.value }
        guard totalShares > 0 else { return [:] }

        var raw: [UserID: Decimal] = [:]
        for pv in rule.participantValues {
            let amount = (total * pv.value / totalShares).roundedDownTo(places: 2)
            distribute(amount, participant: pv.participantID, isGroup: rule.participantsAreGroups,
                       groupMembership: groupMembership, into: &raw)
        }
        return reconcilePennies(raw: raw, total: total)
    }

    /// Splits a per-participant amount equally between the underlying users (1
    /// for individuals, N for groups).
    private static func distribute(
        _ amount: Decimal,
        participant: UUID,
        isGroup: Bool,
        groupMembership: [GroupID: [UserID]],
        into out: inout [UserID: Decimal]
    ) {
        if isGroup {
            let members = groupMembership[GroupID(participant)] ?? []
            guard !members.isEmpty else { return }
            let perMember = (amount / Decimal(members.count)).roundedDownTo(places: 2)
            for member in members {
                out[member, default: 0] += perMember
            }
        } else {
            out[UserID(participant), default: 0] += amount
        }
    }

    /// Distributes any remaining cents (from `total - sum(raw)`) one-by-one to
    /// participants in deterministic order so the total reconciles.
    private static func reconcilePennies(raw: [UserID: Decimal], total: Decimal) -> [UserID: Decimal] {
        let allocated = raw.values.reduce(Decimal.zero, +)
        var remainder = total - allocated
        let onePenny = Decimal(string: "0.01") ?? .zero
        var keys = raw.keys.sorted { $0.raw.uuidString < $1.raw.uuidString }
        var out = raw

        while remainder > 0, let next = keys.first {
            out[next, default: 0] += onePenny
            remainder -= onePenny
            keys.removeFirst()
            if keys.isEmpty { break }
        }
        return out
    }
}

private extension Decimal {
    func roundedDownTo(places: Int) -> Decimal {
        var value = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, places, .down)
        return rounded
    }
}
