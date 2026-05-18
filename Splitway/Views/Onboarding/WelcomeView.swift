import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Hero: the mascot clip fills the entire top region, edge to edge,
            // and holds on its final frame. The clip's own (black) background
            // becomes the top region's backdrop, which blends seamlessly in
            // dark mode (app bg is now black).
            if let url = Bundle.main.url(forResource: "onboarding", withExtension: "mp4") {
                IntroVideoView(url: url, gravity: .resizeAspectFill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            } else {
                CapybaraPlaceholder(size: 260)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Everything else pinned to the bottom.
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

                Button(action: onContinue) {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 20)

                Text("By continuing, you agree to our Privacy Policy")
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(Color.bg)
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
