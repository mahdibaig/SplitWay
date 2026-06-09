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

    @State private var zelleAlert: String? = nil
    @State private var editingMember: HouseholdMember? = nil

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

            paymentActionsRow(for: payment)
                .disabled(viewModel.isWorking)
        }
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    /// Renders the per-row action buttons. The primary action depends on
    /// whether the recipient has a payment handle saved: with a handle we
    /// show their preferred app as the big button; without one we show
    /// "Mark paid" and a tiny hint to add a handle.
    @ViewBuilder
    private func paymentActionsRow(for payment: SimplifiedPayment) -> some View {
        let recipient = membersService.members.first { $0.id == payment.to }
        let methods = recipient?.availablePaymentMethods ?? []

        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if let primary = methods.first, let recipient {
                    paymentButton(
                        method: primary,
                        recipient: recipient,
                        payment: payment,
                        primary: true
                    )
                }

                Button {
                    Task { await viewModel.markPaid(payment) }
                } label: {
                    Text("Mark paid")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(methods.isEmpty ? Color.cta : Color.surface2,
                                    in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(methods.isEmpty ? Color.ctaText : Color.text1)
                }
            }

            // Additional methods, if any beyond the primary, as smaller chips.
            if methods.count > 1, let recipient {
                HStack(spacing: 8) {
                    ForEach(Array(methods.dropFirst()), id: \.rawValue) { method in
                        paymentButton(
                            method: method,
                            recipient: recipient,
                            payment: payment,
                            primary: false
                        )
                    }
                    Spacer(minLength: 0)
                }
            }

            if methods.isEmpty, let recipient {
                Button {
                    editingMember = recipient
                } label: {
                    Text("Add \(recipient.displayName)'s payment info")
                        .font(.caption)
                        .foregroundStyle(Color.brand)
                }
            }
        }
        .alert("Zelle", isPresented: Binding(
            get: { zelleAlert != nil },
            set: { if !$0 { zelleAlert = nil } }
        )) {
            Button("OK") { zelleAlert = nil }
        } message: {
            Text(zelleAlert ?? "")
        }
        .sheet(item: $editingMember) { member in
            MemberPaymentEditSheet(member: member, onSaved: {})
        }
    }

    @ViewBuilder
    private func paymentButton(
        method: PaymentMethod,
        recipient: HouseholdMember,
        payment: SimplifiedPayment,
        primary: Bool
    ) -> some View {
        Button {
            launchPayment(method: method, recipient: recipient, amount: payment.amount)
        } label: {
            if primary {
                Label(method.displayName, systemImage: method.sfSymbol)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            } else {
                Label(method.displayName, systemImage: method.sfSymbol)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandSoft, in: .capsule)
                    .foregroundStyle(Color.brand2)
            }
        }
    }

    private func launchPayment(method: PaymentMethod, recipient: HouseholdMember, amount: Decimal) {
        let action = PaymentLinkBuilder.action(
            for: method,
            recipient: recipient,
            amount: amount,
            note: "Splitway settle up"
        )
        switch action {
        case .openURL(let url):
            UIApplication.shared.open(url)
        case .copyAndInstruct(let text, let alertBody):
            UIPasteboard.general.string = text
            zelleAlert = alertBody
        case nil:
            break
        }
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
