import SwiftUI

/// Single source of truth for how a member's avatar is rendered anywhere in
/// the app. Falls back image, emoji, initials, in that order.
struct MemberAvatar: View {
    let member: HouseholdMember?
    let size: CGFloat

    var body: some View {
        let palette = member.map { AvatarPalette.pair(for: $0.id) }
            ?? AvatarPalette.Pair(bg: Color.brandSoft, fg: Color.brand2)

        ZStack {
            Circle().fill(palette.bg)

            if let data = member?.avatarImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(.circle)
            } else if let emoji = member?.avatarEmoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.55))
            } else {
                Text(initials(member?.displayName ?? "?"))
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(palette.fg)
            }
        }
        .frame(width: size, height: size)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let result = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return result.isEmpty ? "?" : result
    }
}

/// Same fallback rendering but driven by raw bits, for use during onboarding
/// when no `HouseholdMember` exists yet.
struct AvatarPreview: View {
    let imageData: Data?
    let emoji: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color.brandSoft)

            if let data = imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(.circle)
            } else if !emoji.isEmpty {
                Text(emoji).font(.system(size: size * 0.55))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Color.brand2)
            }
        }
        .frame(width: size, height: size)
    }
}
