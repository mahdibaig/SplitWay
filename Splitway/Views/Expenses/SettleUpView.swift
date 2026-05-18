import SwiftUI

struct SettleUpView: View {
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var settlementService: SettlementService
    @EnvironmentObject private var membersService: MembersService

    @Environment(\.dismiss) private var dismiss
    @StateObject private var holder = SettleUpVMHolder()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                if let vm = holder.viewModel {
                    SettleUpContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settle up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if holder.viewModel == nil {
                    holder.viewModel = SettleUpViewModel(
                        expenseService: expenseService,
                        settlementService: settlementService,
                        membersService: membersService
                    )
                }
                await holder.viewModel?.refresh()
            }
        }
    }
}

@MainActor
private final class SettleUpVMHolder: ObservableObject {
    @Published var viewModel: SettleUpViewModel?
}

private struct SettleUpContent: View {
    @ObservedObject var viewModel: SettleUpViewModel
    @EnvironmentObject private var membersService: MembersService

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                if viewModel.payments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.success)
                        Text("Everyone's even.")
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    summaryCard(count: viewModel.payments.count)
                    ForEach(viewModel.payments) { payment in
                        paymentCard(payment)
                    }
                    howItWorksCard
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
    }

    private func summaryCard(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The simplest way")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text(count == 1
                 ? "Just 1 payment to settle everyone up."
                 : "Just \(count) payments to settle everyone up.")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private func paymentCard(_ payment: SimplifiedPayment) -> some View {
        let fromName = name(for: payment.from)
        let toName = name(for: payment.to)

        VStack(spacing: 12) {
            HStack(spacing: 12) {
                avatar(for: payment.from)
                Image(systemName: "arrow.right").foregroundStyle(Color.text3)
                avatar(for: payment.to)
                Spacer()
                Text(CurrencyFormat.usd(payment.amount))
                    .font(.cardTitle)
                    .foregroundStyle(Color.text1)
            }

            Text("\(fromName) pays \(toName)")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    Task { await viewModel.markPaid(payment) }
                } label: {
                    Text("Mark paid")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }

                Button {
                    if let url = URL(string: "zelle://"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Zelle")
                        .font(.cardLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.surface2, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.text1)
                }
            }
            .disabled(viewModel.isWorking)
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How this works")
                .font(.cardLabel)
                .foregroundStyle(Color.success)
            Text("We collapse all pairwise debts into the fewest possible payments. Tap 'Mark paid' once the money is actually moved.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.successSoft, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private func avatar(for id: UserID) -> some View {
        let palette = AvatarPalette.pair(for: id)
        let member = membersService.members.first { $0.id == id }
        ZStack {
            Circle().fill(palette.bg)
            if let emoji = member?.avatarEmoji, !emoji.isEmpty {
                Text(emoji).font(.system(size: 16))
            } else {
                Text(initials(member?.displayName ?? "?"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.fg)
            }
        }
        .frame(width: 32, height: 32)
    }

    private func name(for id: UserID) -> String {
        membersService.members.first { $0.id == id }?.displayName ?? "Someone"
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}
