import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Onboarding hero: plays the mascot clip once then holds on the
            // final frame. Falls back to the static mascot image if the
            // bundled clip is somehow missing.
            if let url = Bundle.main.url(forResource: "onboarding", withExtension: "mp4") {
                IntroVideoView(url: url)
                    .frame(height: 300)
                    .accessibilityHidden(true)
            } else {
                CapybaraPlaceholder(size: 220)
            }

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color.brand)
                Text("Splitway")
                    .font(.system(size: 40, weight: .medium, design: .serif))
                    .foregroundStyle(Color.text1)
                    .kerning(-0.5)
                Text("Track and split expenses with the people you live with, peacefully.")
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, 12)
            }
            .padding(.top, 24)

            Spacer()

            VStack(spacing: 8) {
                Button(action: onContinue) {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }
                Text("By continuing, you agree to our Privacy Policy")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg.ignoresSafeArea())
    }
}

/// The app mascot. Renders the commissioned PNG from the asset catalog
/// (`CapybaraMascot`). Kept the original type name so existing call sites
/// (Assistant tab, consent screen) don't need to change. `size` is the
/// square edge length in points.
struct CapybaraPlaceholder: View {
    let size: CGFloat

    var body: some View {
        Image("CapybaraMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
