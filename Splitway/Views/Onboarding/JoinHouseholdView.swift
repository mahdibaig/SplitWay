import SwiftUI

/// Onboarding "join" screen. Splitway households are shared via a CloudKit
/// invite link (not a typed code — that lookup isn't built yet), so this screen
/// explains how to join: the host sends a link, you open it, and the
/// share-acceptance flow drops you into their household.
struct JoinHouseholdView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Join with an invite link")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Splitway households are shared by link. Ask whoever set up your household to send you the invite.")
                    .foregroundStyle(Color.text2)
            }

            VStack(alignment: .leading, spacing: 16) {
                step(1, "On their iPhone, they open Settings → Share household → Invite housemates.")
                step(2, "They send you the link — Messages, email, AirDrop, anything.")
                step(3, "You open that link on this iPhone. Splitway brings you straight into the household.")
            }

            Spacer()

            Button(action: onBack) {
                Text("Back")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.onboardingBg.ignoresSafeArea())
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(Color.ctaText)
                .frame(width: 28, height: 28)
                .background(Color.brand, in: .circle)
            Text(text)
                .font(.cardLabel)
                .foregroundStyle(Color.text1)
        }
    }
}
