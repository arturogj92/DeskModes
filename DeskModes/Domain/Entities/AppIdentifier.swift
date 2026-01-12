import Foundation

/// Value object representing a unique application identifier.
/// Domain layer - no dependencies on AppKit or system APIs.
struct AppIdentifier: Equatable, Hashable {
    /// The bundle identifier (e.g., "com.apple.Safari")
    let bundleId: String

    /// Human-readable display name (e.g., "Safari")
    let displayName: String
}

// MARK: - Factory Methods
extension AppIdentifier {
    /// Creates an AppIdentifier with just a bundle ID.
    /// Display name defaults to the last component of the bundle ID.
    static func fromBundleId(_ bundleId: String) -> AppIdentifier {
        let displayName = bundleId.components(separatedBy: ".").last ?? bundleId
        return AppIdentifier(bundleId: bundleId, displayName: displayName)
    }
}

// MARK: - CustomStringConvertible
extension AppIdentifier: CustomStringConvertible {
    var description: String {
        "\(displayName) (\(bundleId))"
    }
}
