import SwiftUI
import StoreKit

/// Onboarding paywall shown once, after the assistant consent screen and
/// before MainTabs. Pitches the 7-day free trial on the monthly plan with
/// the full Pro feature list. Skippable — free tier keeps the core app.
///
/// Per Apple's rules the skip path is always visible and the price +
/// renewal terms are stated next to the CTA.
struct ProTrialView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @AppStorage("onboarding.proTrialSeen") private var proTrialSeen: Bool = false

    @State private var showAllPlans = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    CapybaraPlaceholder(size: 140)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Try Splitway Pro free")
                            .font(.serifTitle)
                            .foregroundStyle(Color.text1)
                            .multilineTextAlignment(.center)
                        Text("7 days free, then \(monthlyPriceText) per month. Cancel anytime.")
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                            .multilineTextAlignment(.center)
                    }

                    featureCard

                    Button {
                        showAllPlans = true
                    } label: {
                        Text("See yearly plans")
                            .font(.cardLabel)
                            .foregroundStyle(Color.brand2)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                Button(action: startTrial) {
                    Group {
                        if subscriptions.isWorking {
                            ProgressView().tint(Color.ctaText)
                        } else {
                            Text("Start my free week")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
                }
                .disabled(subscriptions.isWorking || subscriptions.monthlyProduct == nil)

                Button {
                    proTrialSeen = true
                } label: {
                    Text("Continue with the free plan")
                        .font(.cardLabel)
                        .foregroundStyle(Color.text2)
                }

                if let err = subscriptions.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(Color.warn)
                        .multilineTextAlignment(.center)
                }

                if subscriptions.monthlyProduct == nil, let note = subscriptions.productLoadNote {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(Color.text3)
                        .multilineTextAlignment(.center)
                }

                Text("Free keeps unlimited expenses, all split types, settle up, and recurring bills. Subscription renews monthly until cancelled in your Apple ID settings.")
                    .font(.caption2)
                    .foregroundStyle(Color.text3)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 24)
        }
        .background(Color.onboardingBg.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .sheet(isPresented: $showAllPlans) {
            PaywallView(feature: nil)
        }
        .onChange(of: subscriptions.isPro) { _, nowPro in
            // Purchase succeeded (from the CTA or inside the all-plans
            // sheet): continue into the app.
            if nowPro { proTrialSeen = true }
        }
        .task {
            // Already Pro (restored purchase, family share, re-onboarding
            // after reinstall): nothing to sell, skip straight through.
            if subscriptions.isPro { proTrialSeen = true }
        }
    }

    private var monthlyPriceText: String {
        subscriptions.monthlyProduct?.displayPrice ?? "$4.99"
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(icon: "doc.text.viewfinder",
                title: "Smart receipt scanning",
                body: "Point the camera at any receipt. Items, prices, and categories fill in automatically.")
            row(icon: "chart.pie.fill",
                title: "Full reports",
                body: "3 to 12-month trends, category breakdowns, and your personal spending view.")
            row(icon: "target",
                title: "Budgets with alerts",
                body: "Set monthly category budgets and get warned before you overspend.")
            row(icon: "bubble.left.and.bubble.right.fill",
                title: "AI assistant",
                body: "Ask questions about your household spending in plain language.")
            row(icon: "square.and.arrow.up",
                title: "CSV import and export",
                body: "Bring in your expense history and take your data anywhere.")
        }
        .padding(Spacing.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandSoft, in: .rect(cornerRadius: Radius.card))
    }

    private func row(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brand2)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cardLabel.weight(.medium))
                    .foregroundStyle(Color.text1)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.text2)
            }
        }
    }

    private func startTrial() {
        guard let product = subscriptions.monthlyProduct else { return }
        Task {
            await subscriptions.purchase(product)
            // onChange(of: isPro) flips proTrialSeen when it lands.
        }
    }
}

#Preview {
    ProTrialView()
        .environmentObject(SubscriptionService())
}
