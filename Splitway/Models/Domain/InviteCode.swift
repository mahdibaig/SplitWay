import Foundation

/// 6-character uppercase invite code. Excludes visually ambiguous chars
/// (0/O, 1/I/L) so users typing from a screen don't trip on them.
enum InviteCode {
    private static let alphabet: [Character] = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
    static let length = 6

    static func generate() -> String {
        String((0..<length).map { _ in alphabet.randomElement()! })
    }

    static func isWellFormed(_ raw: String) -> Bool {
        let s = raw.uppercased()
        guard s.count == length else { return false }
        return s.allSatisfy { alphabet.contains($0) }
    }

    static func normalize(_ raw: String) -> String {
        raw.uppercased().filter { alphabet.contains($0) }
    }
}
