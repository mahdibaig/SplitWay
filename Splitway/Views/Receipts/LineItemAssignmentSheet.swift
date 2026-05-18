import SwiftUI

/// Bottom sheet for assigning a single receipt line item.
/// Three "remember" options, contextual to the current assignment:
///  - Just this time (default; saves nothing)
///  - Always shared       (only when "Shared by everyone" is picked)
///  - Always [Name]'s     (only when exactly one person is picked)
struct LineItemAssignmentSheet: View {
    let itemName: String
    let members: [HouseholdMember]
    @State var assignedIDs: Set<UUID>
    @State var rememberChoice: RememberChoice
    let onSave: (Set<UUID>, RememberChoice) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        itemName: String,
        members: [HouseholdMember],
        assignedIDs: Set<UUID>,
        rememberChoice: RememberChoice,
        onSave: @escaping (Set<UUID>, RememberChoice) -> Void
    ) {
        self.itemName = itemName
        self.members = members
        self._assignedIDs = State(initialValue: assignedIDs)
        self._rememberChoice = State(initialValue: rememberChoice)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !itemName.isEmpty {
                        Text(itemName)
                            .font(.cardTitle)
                            .foregroundStyle(Color.text1)
                    }
                }

                Section {
                    Button {
                        assignedIDs.removeAll()
                        adjustRememberChoice()
                    } label: {
                        HStack {
                            Image(systemName: assignedIDs.isEmpty ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(assignedIDs.isEmpty ? Color.brand : Color.text3)
                            Text("Shared by everyone").foregroundStyle(Color.text1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Default")
                } footer: {
                    Text("Splits this item equally among all members of the expense.")
                }

                Section("Or assign to specific people") {
                    ForEach(members) { member in
                        Button {
                            toggle(member.id.raw)
                            adjustRememberChoice()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: assignedIDs.contains(member.id.raw) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(assignedIDs.contains(member.id.raw) ? Color.brand : Color.text3)
                                MemberAvatar(member: member, size: 32)
                                Text(member.displayName).foregroundStyle(Color.text1)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Picker("Remember", selection: $rememberChoice) {
                        Text("Just this time").tag(RememberChoice.justThisTime)
                        if assignedIDs.isEmpty {
                            Text("Always shared").tag(RememberChoice.alwaysShared)
                        }
                        if assignedIDs.count == 1,
                           let uid = assignedIDs.first,
                           let member = members.first(where: { $0.id.raw == uid }) {
                            Text("Always \(member.displayName)'s").tag(RememberChoice.alwaysAssignedTo(userID: uid))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Remember next time?")
                } footer: {
                    Text("Picking \"Always…\" saves a rule so future scans of this item pre-fill the assignment.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Assign item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onSave(assignedIDs, rememberChoice) }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ id: UUID) {
        if assignedIDs.contains(id) {
            assignedIDs.remove(id)
        } else {
            assignedIDs.insert(id)
        }
    }

    /// Reset the picker when the assignment shape changes so we don't keep a
    /// "Always [Bob]'s" selection after the user picked multiple people.
    private func adjustRememberChoice() {
        switch rememberChoice {
        case .justThisTime:
            return
        case .alwaysShared:
            if !assignedIDs.isEmpty {
                rememberChoice = .justThisTime
            }
        case .alwaysAssignedTo(let uid):
            if assignedIDs.count != 1 || assignedIDs.first != uid {
                rememberChoice = .justThisTime
            }
        }
    }
}
