import SwiftUI

/// Compact balances summary. Powered by `BalanceService.simplify` (or the
/// group-level equivalent) so it shows the minimal set of payments rather
/// than every pairwise balance. A People / Groups toggle appears only when
/// the household has at least 2 groups and the user has assigned members.
struct WhoOwesWhoCard: View {
    let payments: [SimplifiedPayment]
    let groupPayments: [SimplifiedGroupPayment]
    let members: [HouseholdMember]
    let groups: [HouseholdGroup]
    let groupsAvailable: Bool
    let onTapSettleUp: () -> Void

    @State private var mode: Mode = .people

    enum Mode: String, Hashable { case people, groups }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Who owes who").font(.cardTitle).foregroundStyle(Color.text1)
                Spacer()
                if !payments.isEmpty {
                    Button("Settle up", action: onTapSettleUp)
                        .font(.cardLabel)
                        .foregroundStyle(Color.brand2)
                }
            }

            if groupsAvailable {
                Picker("View", selection: $mode) {
                    Text("People").tag(Mode.people)
                    Text("Groups").tag(Mode.groups)
                }
                .pickerStyle(.segmented)
            }

            content
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .people:
            if payments.isEmpty {
                Text("Everyone's even.")
                    .font(.cardLabel)
                    .foregroundStyle(Color.success)
            } else {
                ForEach(payments) { payment in
                    paymentRow(payment)
                }
            }
        case .groups:
            if groupPayments.isEmpty {
                Text("Groups are even.")
                    .font(.cardLabel)
                    .foregroundStyle(Color.success)
            } else {
                ForEach(groupPayments) { payment in
                    groupPaymentRow(payment)
                }
                Text("Each group settles internally.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
            }
        }
    }

    @ViewBuilder
    private func paymentRow(_ payment: SimplifiedPayment) -> some View {
        let fromName = name(for: payment.from)
        let toName   = name(for: payment.to)
        HStack(spacing: 12) {
            avatar(for: payment.from)
            Image(systemName: "arrow.right").foregroundStyle(Color.text3)
            avatar(for: payment.to)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(fromName) → \(toName)")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
                Text(CurrencyFormat.usd(payment.amount))
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func groupPaymentRow(_ payment: SimplifiedGroupPayment) -> some View {
        let fromName = groupName(for: payment.from)
        let toName = groupName(for: payment.to)
        let fromEmoji = group(payment.from)?.emoji ?? "👥"
        let toEmoji = group(payment.to)?.emoji ?? "👥"

        HStack(spacing: 12) {
            groupAvatar(emoji: fromEmoji)
            Image(systemName: "arrow.right").foregroundStyle(Color.text3)
            groupAvatar(emoji: toEmoji)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(fromName) → \(toName)")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
                Text(CurrencyFormat.usd(payment.amount))
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func avatar(for id: UserID) -> some View {
        let member = members.first { $0.id == id }
        MemberAvatar(member: member, size: 28)
    }

    @ViewBuilder
    private func groupAvatar(emoji: String) -> some View {
        ZStack {
            Circle().fill(Color.brandSoft)
            Text(emoji).font(.system(size: 14))
        }
        .frame(width: 28, height: 28)
    }

    private func name(for id: UserID) -> String {
        members.first { $0.id == id }?.displayName ?? "Someone"
    }

    private func groupName(for id: GroupID) -> String {
        group(id)?.name ?? "A group"
    }

    private func group(_ id: GroupID) -> HouseholdGroup? {
        groups.first { $0.id == id }
    }
}
