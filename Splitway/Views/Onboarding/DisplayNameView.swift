import SwiftUI
import PhotosUI

struct DisplayNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var photoItem: PhotosPickerItem?

    /// Generic preset emojis. Identity-neutral on purpose: no faces, no flags, no people.
    private let emojiOptions = ["🙂", "😎", "⭐", "🌿", "🐱", "🐶", "🦊", "🐻"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should we call you?")
                        .font(.serifTitle)
                        .foregroundStyle(Color.text1)
                    Text("This is how housemates will see you.")
                        .foregroundStyle(Color.text2)
                }

                TextField("First name", text: $viewModel.displayName)
                    .textInputAutocapitalization(.words)
                    .padding(16)
                    .background(Color.surface, in: .rect(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )

                avatarSection

                Spacer(minLength: 0)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }
                .disabled(!viewModel.canContinueFromName)
                .opacity(viewModel.canContinueFromName ? 1 : 0.5)
                .padding(.top, 8)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 48)
            .padding(.bottom, 24)
        }
        .background(Color.onboardingBg.ignoresSafeArea())
        .onChange(of: photoItem) { _, newItem in
            Task { await loadPickedPhoto(newItem) }
        }
    }

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick an avatar")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)

            HStack(spacing: 16) {
                AvatarPreview(imageData: viewModel.avatarImageData, emoji: viewModel.emoji, size: 72)

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(viewModel.avatarImageData == nil ? "Use a photo" : "Change photo",
                              systemImage: "photo.on.rectangle")
                            .font(.cardLabel)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brandSoft, in: .capsule)
                            .foregroundStyle(Color.brand2)
                    }
                    if viewModel.avatarImageData != nil {
                        Button {
                            viewModel.avatarImageData = nil
                            photoItem = nil
                        } label: {
                            Text("Use emoji instead")
                                .font(.caption)
                                .foregroundStyle(Color.text2)
                        }
                    }
                }
            }

            if viewModel.avatarImageData == nil {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                    ForEach(emojiOptions, id: \.self) { e in
                        Button { viewModel.emoji = e } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 56, height: 56)
                                .background(
                                    viewModel.emoji == e ? Color.brandSoft : Color.surface,
                                    in: .rect(cornerRadius: Radius.tile)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.tile)
                                        .stroke(viewModel.emoji == e ? Color.brand : Color.borderSubtle,
                                                lineWidth: viewModel.emoji == e ? 2 : 1)
                                )
                        }
                    }
                }
            }
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let processed = AvatarImage.processed(from: data) {
                viewModel.avatarImageData = processed
            }
        } catch {
            AppLog.ui.error("Failed to load avatar photo: \(error.localizedDescription, privacy: .public)")
        }
    }
}
