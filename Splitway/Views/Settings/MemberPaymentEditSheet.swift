import SwiftUI

/// Edit one household member's payment-app handles. Used both for "your"
/// profile and for filling in housemates' handles on their behalf (so
/// Settle Up can deep-link into the right app).
///
/// Zelle is included even though it has no working deep link — we save
/// the recipient's email/phone so Settle Up can copy "$X to user@email
/// via Zelle" to the clipboard and tell the user to finish in their bank.
struct MemberPaymentEditSheet: View {
    let member: HouseholdMember
    let onSaved: () -> Void

    @EnvironmentObject private var householdService: HouseholdService
    @Environment(\.dismiss) private var dismiss

    @State private var venmo: String = ""
    @State private var cashApp: String = ""
    @State private var paypal: String = ""
    @State private var zelle: String = ""
    @State private var preferred: PaymentMethod? = nil

    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    methodField(.venmo,   text: $venmo)
                    methodField(.cashApp, text: $cashApp)
                    methodField(.paypal,  text: $paypal)
                    methodField(.zelle,   text: $zelle)
                } header: {
                    Text("Payment handles")
                } footer: {
                    Text("Used by Settle Up to deep-link into the right app with the amount prefilled. Zelle copies the details to your clipboard since it has no app-to-app link.")
                }

                Section {
                    Picker("Preferred", selection: $preferred) {
                        Text("Auto (first available)").tag(PaymentMethod?.none)
                        ForEach(availableMethods) { m in
                            Label(m.displayName, systemImage: m.sfSymbol)
                                .tag(PaymentMethod?.some(m))
                        }
                    }
                    .disabled(availableMethods.isEmpty)
                } header: {
                    Text("Preferred for Settle Up")
                } footer: {
                    Text("If set, this method shows as the main button on Settle Up. Otherwise the first handle you've filled in wins.")
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(Color.warn) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle(member.displayName.isEmpty ? "Payment" : "\(member.displayName)'s payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isWorking { ProgressView() }
                        else { Text("Save").bold() }
                    }
                    .disabled(isWorking)
                }
            }
            .onAppear(perform: loadInitial)
        }
    }

    private var availableMethods: [PaymentMethod] {
        var out: [PaymentMethod] = []
        if !venmo.trimmingCharacters(in: .whitespaces).isEmpty   { out.append(.venmo) }
        if !cashApp.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.cashApp) }
        if !paypal.trimmingCharacters(in: .whitespaces).isEmpty  { out.append(.paypal) }
        if !zelle.trimmingCharacters(in: .whitespaces).isEmpty   { out.append(.zelle) }
        return out
    }

    @ViewBuilder
    private func methodField(_ method: PaymentMethod, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: method.sfSymbol)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(method.displayName)
                    .font(.cardLabel.weight(.medium))
                    .foregroundStyle(Color.text1)
                TextField(method.handlePlaceholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
            }
        }
    }

    private func loadInitial() {
        venmo = member.venmoHandle ?? ""
        cashApp = member.cashAppCashtag ?? ""
        paypal = member.paypalMeUsername ?? ""
        zelle = member.zelleContact ?? ""
        preferred = member.preferredPaymentMethod
    }

    private func save() async {
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            // Clear preferred if the user typed away the corresponding
            // handle (preferred can't point at an empty method).
            let effectivePreferred = preferred.flatMap { availableMethods.contains($0) ? $0 : nil }

            try await householdService.updatePaymentInfo(
                userID: member.id,
                venmoHandle: venmo,
                cashAppCashtag: cashApp,
                paypalMeUsername: paypal,
                zelleContact: zelle,
                preferredMethod: effectivePreferred
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
