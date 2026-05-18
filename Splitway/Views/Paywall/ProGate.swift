import SwiftUI

/// Wraps a Pro-only destination. If the user has access, the real content
/// renders. Otherwise a brand-matched upsell screen is shown with an Unlock
/// button that presents the paywall. Used for navigation destinations and
/// the Assistant tab; action-style gates (a button tap) check
/// `subscriptionService.canUse(_:)` inline instead.
struct ProGate<Content: View>: View {
    let feature: FeatureFlag
    @ViewBuilder var content: () -> Content

    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false

    var body: some View {
        Group {
            if subscriptions.canUse(feature) {
                content()
            } else {
                upsell
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(feature: feature)
        }
    }

    private var upsell: some View {
        VStack(spacing: 16) {
            Spacer()
            CapybaraPlaceholder(size: 120)
            VStack(spacing: 8) {
                Text("A Splitway Pro feature")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text(feature.paywallPitch)
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }
            Button {
                showPaywall = true
            } label: {
                Text("See plans")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg.ignoresSafeArea())
    }
}
