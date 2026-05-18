import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var groupService: GroupService
    @EnvironmentObject private var services: ServiceContainer

    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var workingError: String?
    @State private var showAddGroupSheet = false
    @State private var showResetConfirm = false
    @State private var showProfileSheet = false
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false

    var body: some View {
        NavigationStack {
            List {
                if let household = householdService.currentHousehold {
                    Section("Household") {
                        LabeledContent("Name", value: household.name)
                        Toggle("Groups", isOn: groupsBinding)
                        LabeledContent("Invite code", value: household.inviteCode)
                        Button("Regenerate invite code") {
                            Task {
                                do { _ = try await householdService.regenerateInviteCode() }
                                catch { workingError = error.localizedDescription }
                            }
                        }
                    }
                }

                if let member = householdService.currentMember {
                    Section("You") {
                        Button {
                            showProfileSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                MemberAvatar(member: member, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.displayName)
                                        .foregroundStyle(Color.text1)
                                    Text("Edit profile")
                                        .font(.caption)
                                        .foregroundStyle(Color.text2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.text3)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Money") {
                    NavigationLink("Budgets") {
                        BudgetsView()
                    }
                    NavigationLink("Recurring bills") {
                        RecurringListView()
                    }
                    NavigationLink("Import from Splitwise") {
                        SplitwiseImportView()
                    }
                }

                Section("Preferences") {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    NavigationLink("Notifications") {
                        NotificationsView()
                    }
                    NavigationLink("Assistant") {
                        AssistantSettingsView()
                    }
                }

                if householdService.currentHousehold?.groupsEnabled == true {
                    Section("Groups") {
                        if groupService.groupsList.isEmpty {
                            Text("No groups yet").foregroundStyle(Color.text2)
                        } else {
                            ForEach(groupService.groupsList) { group in
                                NavigationLink {
                                    GroupDetailView(groupID: group.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(group.emoji ?? "👥")
                                            .font(.body)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(group.name)
                                                .foregroundStyle(Color.text1)
                                            Text(memberSummary(for: group))
                                                .font(.caption)
                                                .foregroundStyle(Color.text2)
                                        }
                                    }
                                }
                            }
                        }
                        Button("Add group") { showAddGroupSheet = true }
                    }
                }

                Section("Members") {
                    ForEach(membersService.members) { m in
                        LabeledContent(m.displayName, value: m.isArchived ? "Archived" : "Active")
                    }
                }

                if let workingError {
                    Section { Text(workingError).foregroundStyle(Color.warn) }
                }

                Section("Sync") {
                    LabeledContent("iCloud", value: iCloudStatusLabel)
                    if householdService.iCloudStatus != .available {
                        Text("Sign in to iCloud (Settings → Sign in to your iPhone) to enable household sharing across devices. Local data still works without it.")
                            .font(.caption)
                            .foregroundStyle(Color.text2)
                    }
                }

                Section {
                    LabeledContent("Plan", value: services.subscriptionService.tier.displayName)
                    if services.subscriptionService.isPro {
                        Button("Manage subscription") { showManageSubscriptions = true }
                    } else {
                        Button("Upgrade to Pro") { showPaywall = true }
                    }
                    Button("Restore purchases") {
                        Task { await services.subscriptionService.restore() }
                    }
                    .disabled(services.subscriptionService.isWorking)
                } header: {
                    Text("Splitway Pro")
                } footer: {
                    Text(services.subscriptionService.isPro
                         ? "Thanks for supporting Splitway."
                         : "Free keeps unlimited expenses, all 5 split types, settle up, and recurring bills. Pro adds receipts, full reports, budgets, the assistant, and more.")
                }

                Section("About") {
                    LabeledContent("Version", value: "0.1.0")
                }

                #if DEBUG
                Section {
                    Toggle("Unlock Pro (dev)", isOn: Binding(
                        get: { services.subscriptionService.devUnlockPro },
                        set: { services.subscriptionService.devUnlockPro = $0 }
                    ))
                    Button("Add test member") {
                        Task { await services.addTestMember() }
                    }
                    Button("Reset app data", role: .destructive) {
                        showResetConfirm = true
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Unlock Pro: bypasses StoreKit so every gated feature is testable. Add test member: drops a fake housemate in. Reset app data: deletes everything and returns to onboarding. Dev builds only.")
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await membersService.refresh()
                await groupService.refresh()
            }
            .sheet(isPresented: $showAddGroupSheet) {
                AddGroupSheet(groupService: groupService)
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileEditSheet()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: nil)
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .confirmationDialog(
                "Reset app data?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) {
                    Task { await services.resetAppData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This wipes the household and all expenses on this device, and sends you back to onboarding. There's no undo.")
            }
        }
    }

    private func memberSummary(for group: HouseholdGroup) -> String {
        let names = membersService.members
            .filter { !$0.isArchived && $0.groupID == group.id }
            .map(\.displayName)
        if names.isEmpty { return "No members" }
        if names.count <= 2 { return names.joined(separator: ", ") }
        return "\(names.prefix(2).joined(separator: ", ")) and \(names.count - 2) more"
    }

    private var iCloudStatusLabel: String {
        switch householdService.iCloudStatus {
        case .available:              return "Signed in"
        case .noAccount:              return "Not signed in"
        case .restricted:             return "Restricted"
        case .couldNotDetermine:      return "Unknown"
        case .temporarilyUnavailable: return "Unavailable"
        }
    }

    private var groupsBinding: Binding<Bool> {
        Binding(
            get: { householdService.currentHousehold?.groupsEnabled ?? false },
            set: { newValue in
                Task {
                    do { try await householdService.setGroupsEnabled(newValue) }
                    catch { workingError = error.localizedDescription }
                }
            }
        )
    }
}

private struct AddGroupSheet: View {
    let groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "👥"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Emoji", text: $emoji)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        Task {
                            _ = try? await groupService.create(
                                name: name,
                                emoji: emoji,
                                colorTag: nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
