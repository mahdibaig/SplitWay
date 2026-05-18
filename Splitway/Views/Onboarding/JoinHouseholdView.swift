import SwiftUI

struct JoinHouseholdView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void

    @State private var code: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your invite code")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Ask a housemate for the 6-character code, or tap the share link they sent you.")
                    .foregroundStyle(Color.text2)
            }

            TextField("ABCDEF", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(Color.surface, in: .rect(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.cardLabel)
                    .foregroundStyle(Color.warn)
            }

            Text("Phase 1 note: invite-code lookup ships in Phase 2 once the public CloudKit mapping is in place. For now, both housemates create their household on their own device.")
                .font(.cardLabel)
                .foregroundStyle(Color.text3)

            Spacer()

            Button {
                Task { await viewModel.joinHousehold(inviteCode: code) }
            } label: {
                Group {
                    if viewModel.isWorking {
                        ProgressView().tint(Color.ctaText)
                    } else {
                        Text("Join").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                .foregroundStyle(Color.ctaText)
            }
            .disabled(code.count < InviteCode.length || viewModel.isWorking)
            .opacity(code.count < InviteCode.length ? 0.5 : 1)

            Button("Back", action: onBack)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color.text2)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.bg.ignoresSafeArea())
    }
}
