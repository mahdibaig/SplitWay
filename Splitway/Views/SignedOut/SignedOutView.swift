import SwiftUI

struct SignedOutView: View {
    let onRecheck: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "icloud.slash")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.text2)

            VStack(spacing: 12) {
                Text("Please sign in to iCloud")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)

                Text("Splitway syncs your household across devices using iCloud. Open Settings → Sign in, then come back.")
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }

            Spacer()

            Button(action: onRecheck) {
                Text("Check again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg.ignoresSafeArea())
    }
}

#Preview {
    SignedOutView(onRecheck: {})
}
