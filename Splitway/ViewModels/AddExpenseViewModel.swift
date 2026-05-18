import Foundation
import SwiftUI

@MainActor
final class AddExpenseViewModel: ObservableObject {

    enum SplitGranularity: Hashable { case individuals, groups }

    // Form state
    @Published var amount: Decimal = .zero
    @Published var category: ExpenseCategory = .groceries
    @Published var description: String = ""
    @Published var date: Date = Date()
    @Published var splitType: SplitType = .equal
    @Published var granularity: SplitGranularity = .individuals
    @Published var participantStates: [ParticipantState] = []
    @Published var groupParticipantStates: [GroupParticipantState] = []
    @Published var paidByUserID: UserID?
    @Published var notes: String = ""

    // UI state
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    private let expenseService: ExpenseService
    private let householdService: HouseholdService
    private let members: [HouseholdMember]
    let groupMembership: [GroupID: [UserID]]

    /// Per-member form state. For Equal, only `isIncluded` matters. For other
    /// split types, `inputValue` carries the percent/amount/share number.
    struct ParticipantState: Identifiable {
        let id: UserID
        let displayName: String
        let avatarEmoji: String?
        let avatarImageData: Data?
        var isIncluded: Bool
        var inputValue: Decimal
    }

    /// Per-group form state, used when `granularity == .groups`. The subtitle
    /// lists the members in the group so the user can sanity-check before saving.
    struct GroupParticipantState: Identifiable {
        let id: GroupID
        let name: String
        let emoji: String?
        let memberNames: [String]
        var isIncluded: Bool
        var inputValue: Decimal
    }

    init(
        expenseService: ExpenseService,
        householdService: HouseholdService,
        members: [HouseholdMember],
        groups: [HouseholdGroup] = [],
        groupMembership: [GroupID: [UserID]] = [:]
    ) {
        self.expenseService = expenseService
        self.householdService = householdService
        self.members = members.filter { !$0.isArchived }
        self.groupMembership = groupMembership

        self.participantStates = self.members.map { m in
            ParticipantState(
                id: m.id,
                displayName: m.displayName,
                avatarEmoji: m.avatarEmoji,
                avatarImageData: m.avatarImageData,
                isIncluded: true,
                inputValue: 0
            )
        }

        let nameByID = Dictionary(uniqueKeysWithValues: self.members.map { ($0.id, $0.displayName) })
        self.groupParticipantStates = groups.map { g in
            let names = (groupMembership[g.id] ?? []).compactMap { nameByID[$0] }
            return GroupParticipantState(
                id: g.id,
                name: g.name,
                emoji: g.emoji,
                memberNames: names,
                isIncluded: true,
                inputValue: 0
            )
        }

        self.paidByUserID = householdService.currentMember?.id
    }

    /// True only when the household has 2+ groups AND all those groups have
    /// at least one member. Otherwise the group toggle is hidden.
    var groupModeAvailable: Bool {
        guard groupParticipantStates.count >= 2 else { return false }
        return groupParticipantStates.allSatisfy { !$0.memberNames.isEmpty }
    }

    var canSave: Bool {
        amount > 0
            && !description.trimmingCharacters(in: .whitespaces).isEmpty
            && paidByUserID != nil
            && !isSaving
    }

    /// Pre-computed per-user shares for the live "shares preview" UI.
    var resolvedShares: [UserID: Decimal] {
        let rule = buildSplitRule()
        guard amount > 0 else { return [:] }
        return SplitResolver.resolveUserShares(
            rule: rule,
            total: amount,
            groupMembership: groupMembership
        )
    }

    /// Pre-computed per-group total shares so the group rows can show a number
    /// while the user picks a split type.
    var resolvedGroupShares: [GroupID: Decimal] {
        let perUser = resolvedShares
        var result: [GroupID: Decimal] = [:]
        for (gid, users) in groupMembership {
            result[gid] = users.reduce(Decimal.zero) { $0 + (perUser[$1] ?? 0) }
        }
        return result
    }

    func save() async {
        guard canSave else { return }
        isSaving = true; errorMessage = nil
        defer { isSaving = false }

        let rule = buildSplitRule()
        if let validationError = SplitResolver.validate(rule, total: amount) {
            errorMessage = validationError.errorDescription
            return
        }

        do {
            try await expenseService.add(
                amount: amount,
                category: category,
                description: description.trimmingCharacters(in: .whitespaces),
                merchant: nil,
                date: date,
                splitRule: rule,
                notes: notes.isEmpty ? nil : notes
            )
            didSave = true
        } catch {
            AppLog.ui.error("Save expense failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    private func buildSplitRule() -> SplitRule {
        switch granularity {
        case .individuals:
            return buildIndividualRule()
        case .groups:
            return buildGroupRule()
        }
    }

    private func buildIndividualRule() -> SplitRule {
        let included = participantStates.filter { $0.isIncluded }
        let participantIDs = included.map { $0.id.raw }

        let values: [ParticipantValue]
        switch splitType {
        case .equal, .excluded:
            values = []
        case .percentages, .amounts, .shares:
            values = included.map { ParticipantValue(participantID: $0.id.raw, value: $0.inputValue) }
        }

        let payerID = paidByUserID ?? included.first?.id ?? UserID()
        let paidBy = [PaidByEntry(userID: payerID.raw, amount: amount)]

        // Type collapse: if user unchecked anyone in an Equal split, this becomes
        // an excluded-style payment (still treated identically by the resolver).
        let effectiveType: SplitType
        if splitType == .equal, included.count < participantStates.count {
            effectiveType = .excluded
        } else {
            effectiveType = splitType
        }

        return SplitRule(
            type: effectiveType,
            participantIDs: participantIDs,
            participantValues: values,
            paidBy: paidBy,
            participantsAreGroups: false
        )
    }

    private func buildGroupRule() -> SplitRule {
        let included = groupParticipantStates.filter { $0.isIncluded }
        let participantIDs = included.map { $0.id.raw }

        let values: [ParticipantValue]
        switch splitType {
        case .equal, .excluded:
            values = []
        case .percentages, .amounts, .shares:
            values = included.map { ParticipantValue(participantID: $0.id.raw, value: $0.inputValue) }
        }

        let payerID = paidByUserID ?? householdService.currentMember?.id ?? UserID()
        let paidBy = [PaidByEntry(userID: payerID.raw, amount: amount)]

        let effectiveType: SplitType
        if splitType == .equal, included.count < groupParticipantStates.count {
            effectiveType = .excluded
        } else {
            effectiveType = splitType
        }

        return SplitRule(
            type: effectiveType,
            participantIDs: participantIDs,
            participantValues: values,
            paidBy: paidBy,
            participantsAreGroups: true
        )
    }
}
