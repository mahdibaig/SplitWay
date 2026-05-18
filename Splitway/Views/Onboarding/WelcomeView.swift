import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            CapybaraPlaceholder(size: 220)

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

/// Capybara mascot, ported from the design system SVG at
/// `Design/project/chrome.jsx:157` (the `Capybara` component). SVG viewBox is
/// 200x220, so every SwiftUI coordinate is the SVG coordinate scaled by `size/200`.
struct CapybaraPlaceholder: View {
    /// Width in points. Rendered height is `size * 1.1`.
    let size: CGFloat

    private var s: CGFloat { size / 200 }
    private var w: CGFloat { 200 * s }
    private var h: CGFloat { 220 * s }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Body
            Ellipse()
                .fill(bodyGradient)
                .frame(width: 136 * s, height: 96 * s)
                .position(x: 100 * s, y: 160 * s)

            // Belly hint
            Ellipse()
                .fill(Color(hex: 0xd4a878).opacity(0.45))
                .frame(width: 80 * s, height: 36 * s)
                .position(x: 100 * s, y: 180 * s)

            // Feet
            Ellipse()
                .fill(Color(hex: 0xa07854))
                .frame(width: 28 * s, height: 14 * s)
                .position(x: 62 * s, y: 200 * s)
            Ellipse()
                .fill(Color(hex: 0xa07854))
                .frame(width: 28 * s, height: 14 * s)
                .position(x: 138 * s, y: 200 * s)

            // Head
            Ellipse()
                .fill(headGradient)
                .frame(width: 112 * s, height: 100 * s)
                .position(x: 100 * s, y: 90 * s)

            // Cheek highlight
            Ellipse()
                .fill(Color(hex: 0xd4a584).opacity(0.4))
                .frame(width: 44 * s, height: 32 * s)
                .position(x: 78 * s, y: 80 * s)

            // Ears, outer
            Ellipse()
                .fill(Color(hex: 0xa07854))
                .frame(width: 24 * s, height: 20 * s)
                .position(x: 58 * s, y: 58 * s)
            Ellipse()
                .fill(Color(hex: 0xa07854))
                .frame(width: 24 * s, height: 20 * s)
                .position(x: 142 * s, y: 58 * s)

            // Ears, inner pink
            Ellipse()
                .fill(Color(hex: 0xe5b8a8))
                .frame(width: 12 * s, height: 10 * s)
                .position(x: 58 * s, y: 59 * s)
            Ellipse()
                .fill(Color(hex: 0xe5b8a8))
                .frame(width: 12 * s, height: 10 * s)
                .position(x: 142 * s, y: 59 * s)

            // Eyes
            Ellipse()
                .fill(Color(hex: 0x2a1d14))
                .frame(width: 9 * s, height: 10.4 * s)
                .position(x: 81 * s, y: 89 * s)
            Ellipse()
                .fill(Color(hex: 0x2a1d14))
                .frame(width: 9 * s, height: 10.4 * s)
                .position(x: 119 * s, y: 89 * s)

            // Eye highlights
            Circle()
                .fill(.white)
                .frame(width: 2.6 * s)
                .position(x: 82.5 * s, y: 87 * s)
            Circle()
                .fill(.white)
                .frame(width: 2.6 * s)
                .position(x: 120.5 * s, y: 87 * s)

            // Muzzle
            Ellipse()
                .fill(noseGradient)
                .frame(width: 26 * s, height: 16 * s)
                .position(x: 100 * s, y: 110 * s)

            // Nostrils
            Circle()
                .fill(Color(hex: 0x2a1d14))
                .frame(width: 2.8 * s)
                .position(x: 96 * s, y: 108 * s)
            Circle()
                .fill(Color(hex: 0x2a1d14))
                .frame(width: 2.8 * s)
                .position(x: 104 * s, y: 108 * s)

            // Subtle smile (matches design system)
            Path { p in
                p.move(to: CGPoint(x: 96 * s, y: 115 * s))
                p.addQuadCurve(
                    to: CGPoint(x: 104 * s, y: 115 * s),
                    control: CGPoint(x: 100 * s, y: 118 * s)
                )
            }
            .stroke(Color(hex: 0x5a3d28),
                    style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))

            // Orange ground shadow
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: 18 * s, height: 6 * s)
                .position(x: 103 * s, y: 38 * s)

            // Orange
            Circle()
                .fill(orangeGradient)
                .frame(width: 30 * s)
                .position(x: 100 * s, y: 30 * s)

            // Orange shine
            Ellipse()
                .fill(Color(hex: 0xffc183).opacity(0.55))
                .frame(width: 12 * s, height: 8 * s)
                .position(x: 95 * s, y: 26 * s)

            // Leaf
            Ellipse()
                .fill(Color(hex: 0x7ca85e))
                .frame(width: 12 * s, height: 6 * s)
                .rotationEffect(.degrees(-25))
                .position(x: 92 * s, y: 15 * s)

            // Leaf stem
            Path { p in
                p.move(to: CGPoint(x: 98 * s, y: 17 * s))
                p.addLine(to: CGPoint(x: 95 * s, y: 13 * s))
            }
            .stroke(Color(hex: 0x5a7d3e),
                    style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))

            // Leaf shine
            Ellipse()
                .fill(Color(hex: 0x9bc480).opacity(0.7))
                .frame(width: 6 * s, height: 2 * s)
                .rotationEffect(.degrees(-25))
                .position(x: 91 * s, y: 14 * s)
        }
        .frame(width: w, height: h)
    }

    // Gradients lifted verbatim from chrome.jsx, hex codes match.

    private var bodyGradient: RadialGradient {
        RadialGradient(
            colors: [Color(hex: 0xc89868), Color(hex: 0xa87a4e)],
            center: UnitPoint(x: 0.5, y: 0.35),
            startRadius: 0,
            endRadius: 75 * s
        )
    }

    private var headGradient: RadialGradient {
        RadialGradient(
            colors: [Color(hex: 0xcaa07a), Color(hex: 0xb88a5e)],
            center: UnitPoint(x: 0.5, y: 0.4),
            startRadius: 0,
            endRadius: 65 * s
        )
    }

    private var noseGradient: RadialGradient {
        RadialGradient(
            colors: [Color(hex: 0x8a6248), Color(hex: 0x6a4830)],
            center: UnitPoint(x: 0.5, y: 0.3),
            startRadius: 0,
            endRadius: 16 * s
        )
    }

    private var orangeGradient: RadialGradient {
        RadialGradient(
            colors: [Color(hex: 0xffaf6c), Color(hex: 0xe88a3a)],
            center: UnitPoint(x: 0.35, y: 0.35),
            startRadius: 0,
            endRadius: 18 * s
        )
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
