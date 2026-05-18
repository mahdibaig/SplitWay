import Foundation

enum RepositoryError: Error, LocalizedError {
    case notFound
    case mappingFailed
    case inviteCodeNotFound

    var errorDescription: String? {
        switch self {
        case .notFound:           return "Couldn't find that record."
        case .mappingFailed:      return "Data on disk is in an unexpected shape."
        case .inviteCodeNotFound: return "That invite code doesn't match any household."
        }
    }
}
