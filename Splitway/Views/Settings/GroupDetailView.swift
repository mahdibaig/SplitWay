import SwiftUI

/// Manages a single group: name, emoji, member assignment, delete.
/// Each member can belong to 0 or 1 group (the User Core Data entity has a
/// to-one `group` relationship), so assigning someone here removes them from
/// any other group automatically.
struct GroupDetailView: View {
    let groupID: GroupID

    @EnvironmentObject private var groupService: GroupService
    @EnvironmentObject private var membersService: MembersService
    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String = ""
    @State private var showDeleteConfirm = false
    @State private var pendingMoveMemberID: UserID?
    @State private var pendingMoveFromGroupName: String = ""

    private var group: HouseholdGroup? {
        groupService.groupsList.first { $0.id == groupID }
    }

    var body: some View {
        List {
            if let group {
                Section("Name") {
                    TextField("Group name", text: $editedName)
                        .textInputAutocapitalization(.words)
                        .onSubmit { commitName() }
                        .submitLabel(.done)
                }

                Section {
                    ForEach(membersService.members.filter { !$0.isArchived }) { member in
                        memberRow(member: member, in: group)
                    }
                } header: {
                    Text("Members")
                } footer: {
                    Text("A member can belong to one group at a time. Picking them here moves them out of any other group.")
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete group")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            } else {
                Text("This group is gone.")
                    .foregroundStyle(Color.text2)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle(editedName.isEmpty ? "Group" : editedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { commitName() }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty
                              || editedName == group?.name)
            }
        }
        .task {
            await membersService.refresh()
            await groupService.refresh()
            editedName = group?.name ?? ""
        }
        .confirmationDialog(
            "Delete this group?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await groupService.delete(groupID)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Members stay in the household. They just won't be in any group.")
        }
        .confirmationDialog(
            "Move from \(pendingMoveFromGroupName)?",
            isPresented: movePromptBinding,
            titleVisibility: .visible
        ) {
            Button("Move them") {
                if let memberID = pendingMoveMemberID {
                    Task { try? await groupService.setGroup(groupID, forUser: memberID) }
                }
                pendingMoveMemberID = nil
            }
            Button("Cancel", role: .cancel) { pendingMoveMemberID = nil }
        }
    }

    @ViewBuilder
    private func memberRow(member: HouseholdMember, in group: HouseholdGroup) -> some View {
        let isInThisGroup = (member.groupID == group.id)
        let otherGroupName: String? = {
            guard let gid = member.groupID, gid != group.id else { return nil }
            return groupService.groupsList.first { $0.id == gid }?.name
        }()

        Button {
            handleTap(member: member, isInThisGroup: isInThisGroup, otherGroupName: otherGroupName)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isInThisGroup ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isInThisGroup ? Color.brand : Color.text3)
                MemberAvatar(member: member, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(member.displayName).foregroundStyle(Color.text1)
                    if let otherGroupName {
                        Text("In \(otherGroupName)")
                            .font(.caption)
                            .foregroundStyle(Color.text2)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func handleTap(member: HouseholdMember, isInThisGroup: Bool, otherGroupName: String?) {
        if isInThisGroup {
            // Tap to remove from this group.
            Task { try? await groupService.setGroup(nil, forUser: member.id) }
        } else if let other = otherGroupName {
            // Show a confirmation before yanking them from another group.
            pendingMoveMemberID = member.id
            pendingMoveFromGroupName = other
        } else {
            Task { try? await groupService.setGroup(groupID, forUser: member.id) }
        }
    }

    private var movePromptBinding: Binding<Bool> {
        Binding(
            get: { pendingMoveMemberID != nil },
            set: { if !$0 { pendingMoveMemberID = nil } }
        )
    }

    private func commitName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != group?.name else { return }
        Task { try? await groupService.rename(groupID, to: trimmed) }
    }
}
