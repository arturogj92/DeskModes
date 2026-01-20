import Foundation

/// Apps that should NEVER be closed, regardless of the active mode.
/// Domain layer - no dependencies on AppKit or system APIs.
struct GlobalAllowList: Equatable {
    /// The list of apps that are globally protected
    private(set) var apps: [AppIdentifier]

    init(apps: [AppIdentifier] = []) {
        self.apps = apps
    }

    /// Checks if an app is in the global allow list
    func contains(_ app: AppIdentifier) -> Bool {
        apps.contains(app)
    }

    /// Checks if an app should be protected (never closed)
    func isProtected(_ bundleId: String) -> Bool {
        apps.contains { $0.bundleId == bundleId }
    }
}

// MARK: - Mutating Operations
extension GlobalAllowList {
    /// Adds an app to the global allow list
    mutating func add(_ app: AppIdentifier) {
        guard !contains(app) else { return }
        apps.append(app)
    }

    /// Removes an app from the global allow list
    mutating func remove(_ app: AppIdentifier) {
        apps.removeAll { $0 == app }
    }
}

// MARK: - Default Configuration
extension GlobalAllowList {
    /// Default global allow list for MVP
    /// Apps that users typically want running across all modes
    static let defaultList = GlobalAllowList(apps: [
        AppIdentifier(bundleId: "net.whatsapp.WhatsApp", displayName: "WhatsApp"),
        AppIdentifier(bundleId: "ru.keepcoder.Telegram", displayName: "Telegram"),
        AppIdentifier(bundleId: "com.google.Chrome", displayName: "Chrome")
    ])
}
