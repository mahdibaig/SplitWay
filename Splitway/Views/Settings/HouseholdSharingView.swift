import SwiftUI
import CloudKit

/// Settings screen for inviting housemates into the household via CloudKit
/// sharing. The owner prepares a CKShare and hands it to the system share
/// sheet (`UICloudSharingController`), which generates the invite link and
/// manages participants and permissions.
///
/// Free tier covers a 2-person household (you + one). Inviting a third person
/// is a Pro feature (`cloudShare3Plus`).
struct HouseholdSharingView: View {
    @EnvironmentObject private var sharing: CloudKitSharingService
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var householdService: HouseholdService

    @State private var presentation: SharePresentation?
    @State private var showPaywall = false
    @State private var isPreparing = false
    @State private var errorMessage: String?

    /// Identifiable wrapper so the share can drive `.sheet(item:)`.
    private struct SharePresentation: Identifiable {
        let id = UUID()
        let share: CKShare
        let container: CKContainer
    }

    private var iCloudAvailable: Bool { householdService.iCloudStatus == .available }
    private var participantCount: Int { sharing.participantCount() }
    private var isShared: Bool { participantCount > 1 }

    var body: some View {
        List {
            if !iCloudAvailable {
                Section {
                    Label("Sign in to iCloud to share your household across devices and with the people you live with.", systemImage: "icloud.slash")
                        .font(.cardLabel)
                        .foregroundStyle(Color.text2)
                }
            } else {
                statusSection
                inviteSection
                howItWorks
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(Color.warn) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Share household")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentation) { p in
            CloudSharingControllerView(
                share: p.share,
                container: p.container,
                title: householdService.currentHousehold?.name ?? "Splitway household",
                onDidSave: { Task { await householdService.refresh() } },
                onDidStop: { Task { await householdService.refresh() } }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(feature: .cloudShare3Plus)
        }
        .task { await householdService.refreshAccountStatus() }
    }

    private var statusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: isShared ? "person.2.fill" : "person.fill")
                    .foregroundStyle(Color.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isShared
                         ? "Shared with \(participantCount) people"
                         : "Not shared yet")
                        .font(.cardTitle)
                        .foregroundStyle(Color.text1)
                    Text(isShared
                         ? "Manage who has access from the invite sheet."
                         : "Invite the people you split with so everyone sees the same expenses.")
                        .font(.caption)
                        .foregroundStyle(Color.text2)
                }
            }
        }
    }

    private var inviteSection: some View {
        Section {
            Button(action: invite) {
                HStack {
                    if isPreparing {
                        ProgressView()
                    } else {
                        Label(isShared ? "Manage sharing" : "Invite housemates",
                              systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                }
            }
            .disabled(isPreparing)
        } footer: {
            Text("Free, Individual, and Duo cover a 2-person household. Household covers up to 6.")
        }
    }

    private var howItWorks: some View {
        Section("How it works") {
            bullet("You'll get a link to send however you like — Messages, email, AirDrop.")
            bullet("Whoever opens it on their iPhone joins your household and sees the same expenses, balances, and settle-up.")
            bullet("Everyone needs to be signed in to iCloud.")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.success)
            Text(text).font(.caption).foregroundStyle(Color.text2)
        }
    }

    private func invite() {
        errorMessage = nil

        // Seat-cap gate: the household's plan sets how many people can join.
        // Free, Individual, and Duo top out at 2; Household allows 6. At the cap,
        // either upsell to a roomier plan or, if already on Household, ask them
        // to remove a member.
        if participantCount >= subscriptions.participationCap {
            if subscriptions.effectivePlanTier == .household {
                errorMessage = "Your household is at its 6-person limit. Remove a member from the invite sheet to add someone new."
            } else {
                showPaywall = true
            }
            return
        }

        isPreparing = true
        Task {
            do {
                let share = try await sharing.prepareShare()
                presentation = SharePresentation(share: share, container: sharing.cloudContainer)
            } catch {
                errorMessage = error.localizedDescription
            }
            isPreparing = false
        }
    }
}
