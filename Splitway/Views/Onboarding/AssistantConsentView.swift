import SwiftUI

/// Apple App Review requires consent-at-point-of-use for off-device data
/// transmission. This screen sits between household creation and MainTabs so
/// users see it once before the assistant can ever fire. Default is OFF.
struct AssistantConsentView: View {
    @EnvironmentObject private var preferences: AssistantPreferences
    @AppStorage("onboarding.assistantConsentSeen") private var consentSeen: Bool = false

    /// Local toggle state. Default off per Apple's rules; user must opt in.
    @State private var enableNow: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    CapybaraPlaceholder(size: 140)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Want help from the assistant?")
                            .font(.serifTitle)
                            .foregroundStyle(Color.text1)
                            .multilineTextAlignment(.center)
                        Text("Optional. You can turn this on later in Settings.")
                            .font(.cardLabel)
                            .foregroundStyle(Color.text2)
                            .multilineTextAlignment(.center)
                    }

                    bulletCard

                    Toggle(isOn: $enableNow) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable AI assistant")
                                .font(.cardTitle)
                                .foregroundStyle(Color.text1)
                            Text("Off by default. You're in control.")
                                .font(.caption)
                                .foregroundStyle(Color.text2)
                        }
                    }
                    .tint(Color.brand)
                    .padding(Spacing.cardPad)
                    .background(Color.surface, in: .rect(cornerRadius: Radius.card))
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, 16)
            }

            Button(action: finish) {
                Text(enableNow ? "Continue" : "Skip for now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 24)
        }
        .background(Color.bg.ignoresSafeArea())
    }

    private var bulletCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(icon: "questionmark.bubble",
                title: "Answers your money questions",
                body: "Tap a chip like \"How much did I spend on groceries?\" and get a clear answer.")
            row(icon: "paperplane",
                title: "Sends a household snapshot",
                body: "Your members, balances, this and last month's totals, budgets, and recent expenses go to DeepSeek to generate the reply.")
            row(icon: "lock.shield",
                title: "Never sends",
                body: "Apple IDs, your iCloud account, raw receipts, photos, or anything you didn't ask about.")
            row(icon: "iphone",
                title: "History stays on this device",
                body: "We cap conversation history at 50 messages locally. Nothing is stored on our servers.")
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

    private func finish() {
        preferences.enabled = enableNow
        consentSeen = true
    }
}

#Preview {
    AssistantConsentView()
        .environmentObject(AssistantPreferences())
}
