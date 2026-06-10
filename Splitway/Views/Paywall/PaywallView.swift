import SwiftUI
import StoreKit

/// Brand-matched paywall. Presented as a sheet when a free user taps a
/// Pro-gated feature. Lists the subscription SKUs (monthly, individual
/// yearly, family yearly), highlights Family as most popular, includes the
/// 7-day trial line and a restore button.
struct PaywallView: View {
    /// The feature the user tapped, so the headline can be contextual.
    let feature: FeatureFlag?

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.cardGap) {
                    header
                    if subscriptions.products.isEmpty {
                        unavailableCard
                    } else {
                        ForEach(subscriptions.products, id: \.id) { product in
                            productCard(product)
                        }
                    }
                    legalLine
                    if let err = subscriptions.lastError {
                        Text(err)
                            .font(.cardLabel)
                            .foregroundStyle(Color.warn)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Splitway Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Not now") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task {
                            await subscriptions.restore()
                            if subscriptions.isPro { dismiss() }
                        }
                    }
                    .disabled(subscriptions.isWorking)
                }
            }
            .onChange(of: subscriptions.isPro) { _, nowPro in
                if nowPro { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            CapybaraPlaceholder(size: 96)
            Text("Unlock Splitway Pro")
                .font(.serifTitle)
                .foregroundStyle(Color.text1)
            Text(feature?.paywallPitch
                 ?? "Smart receipts, full reports, budgets, and the assistant.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
            Text("Free always keeps unlimited expenses, all 5 split types, settle up, and recurring bills. No daily caps, ever.")
                .font(.caption)
                .foregroundStyle(Color.text3)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func productCard(_ product: Product) -> some View {
        let highlighted = product.id == ProductID.familyYearly
        Button {
            Task { await subscriptions.purchase(product) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                        if product.id == ProductID.familyYearly {
                            tag("Most popular")
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.cardTitle)
                        .foregroundStyle(Color.text1)
                    Text(periodLabel(for: product.id))
                        .font(.caption2)
                        .foregroundStyle(Color.text2)
                }
            }
            .padding(Spacing.cardPad)
            .background(
                highlighted ? Color.brandSoft : Color.surface,
                in: .rect(cornerRadius: Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(highlighted ? Color.brand : Color.borderSubtle,
                            lineWidth: highlighted ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(subscriptions.isWorking)
    }

    private func periodLabel(for productID: String) -> String {
        switch productID {
        case ProductID.individualMonthly: return "per month"
        default:                          return "per year"
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.brand, in: .capsule)
            .foregroundStyle(Color.ctaText)
    }

    private var unavailableCard: some View {
        VStack(spacing: 6) {
            if subscriptions.isWorking {
                ProgressView()
            }
            Text("Plans aren't available right now.")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text("This usually means the app isn't signed in to the App Store, or products are still propagating. Try Restore, or check back shortly.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var legalLine: some View {
        Text("7-day free trial on the subscriptions. Cancel anytime in your Apple ID settings. Subscriptions renew automatically until cancelled.")
            .font(.caption2)
            .foregroundStyle(Color.text3)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}
