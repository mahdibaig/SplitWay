import SwiftUI
import PhotosUI

/// Lets the user change their display name and avatar after onboarding.
struct ProfileEditSheet: View {
    @EnvironmentObject private var householdService: HouseholdService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var emoji: String = "🙂"
    @State private var avatarImageData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var isWorking = false
    @State private var errorMessage: String?

    private let emojiOptions = ["🙂", "😎", "⭐", "🌿", "🐱", "🐶", "🦊", "🐻"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.cardGap) {
                    nameCard
                    avatarCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.cardLabel)
                            .foregroundStyle(Color.warn)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 16)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isWorking { ProgressView() }
                        else { Text("Save").bold() }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
                }
            }
            .onAppear(perform: loadInitial)
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPickedPhoto(newItem) }
            }
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Display name").font(.cardLabel).foregroundStyle(Color.text2)
            TextField("Your name", text: $displayName)
                .textInputAutocapitalization(.words)
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private var avatarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Avatar").font(.cardLabel).foregroundStyle(Color.text2)

            HStack(spacing: 16) {
                AvatarPreview(imageData: avatarImageData, emoji: emoji, size: 72)

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(avatarImageData == nil ? "Use a photo" : "Change photo",
                              systemImage: "photo.on.rectangle")
                            .font(.cardLabel)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brandSoft, in: .capsule)
                            .foregroundStyle(Color.brand2)
                    }
                    if avatarImageData != nil {
                        Button {
                            avatarImageData = nil
                            photoItem = nil
                        } label: {
                            Text("Use emoji instead")
                                .font(.caption)
                                .foregroundStyle(Color.text2)
                        }
                    }
                }
            }

            if avatarImageData == nil {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                    ForEach(emojiOptions, id: \.self) { e in
                        Button { emoji = e } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 56, height: 56)
                                .background(
                                    emoji == e ? Color.brandSoft : Color.surface2,
                                    in: .rect(cornerRadius: Radius.tile)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.tile)
                                        .stroke(emoji == e ? Color.brand : Color.borderSubtle,
                                                lineWidth: emoji == e ? 2 : 1)
                                )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func loadInitial() {
        guard let me = householdService.currentMember else { return }
        displayName = me.displayName
        emoji = me.avatarEmoji ?? "🙂"
        avatarImageData = me.avatarImageData
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let processed = AvatarImage.processed(from: data) {
                avatarImageData = processed
            }
        } catch {
            AppLog.ui.error("Failed to load avatar photo: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() async {
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            try await householdService.updateMyProfile(
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                avatarEmoji: avatarImageData == nil ? emoji : nil,
                avatarImageData: .some(avatarImageData)  // pass through (including nil to clear)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
