import SwiftUI

struct CreateOrJoinView: View {
    let onCreate: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set up your household")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Start a new one, or join someone who already has.")
                    .foregroundStyle(Color.text2)
            }

            VStack(spacing: 12) {
                bigButton(
                    title: "Create a household",
                    subtitle: "You'll get a link and code to invite others.",
                    filled: true,
                    action: onCreate
                )

                bigButton(
                    title: "Join a household",
                    subtitle: "You'll need an invite link or 6-digit code.",
                    filled: false,
                    action: onJoin
                )
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.onboardingBg.ignoresSafeArea())
    }

    @ViewBuilder
    private func bigButton(title: String, subtitle: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.cardTitle)
                Text(subtitle).font(.cardLabel).opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(filled ? Color.cta : Color.surface,
                        in: .rect(cornerRadius: Radius.card))
            .foregroundStyle(filled ? Color.ctaText : Color.text1)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(filled ? Color.clear : Color.borderSubtle, lineWidth: 1)
            )
        }
    }
}
