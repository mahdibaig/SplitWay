import Foundation

/// SwiftUI `.sheet(item:)` and `ForEach` want `Identifiable`. UUID is the
/// natural identifier in our domain, so a retroactive conformance is the
/// least-ceremonious option. Marked `@retroactive` since UUID lives in
/// Foundation.
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
