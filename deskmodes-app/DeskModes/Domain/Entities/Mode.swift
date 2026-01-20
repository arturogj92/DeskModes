import Foundation

/// Represents a work context/mode that defines which apps should be open.
/// Domain layer - no dependencies on AppKit or system APIs.
struct Mode: Identifiable, Equatable {
    /// Unique identifier for the mode
    let id: String

    /// Human-readable name (e.g., "Work", "Dev", "AI")
    let name: String

    /// Icon name for the mode (e.g., "work_mode", "dev_mode")
    let icon: String

    /// Global keyboard shortcut (e.g., "cmd+shift+1")
    let shortcut: String?

    /// Apps that should be open in this mode
    /// - If running: keep open
    /// - If not running: launch them
    let apps: [AppIdentifier]

    /// Optional window layouts for apps (placeholder for future)
    let windowLayouts: [WindowLayoutEntry]?

    /// Optional project path for Dev mode (IDE will open this)
    let projectPath: String?

    init(
        id: String,
        name: String,
        icon: String = "new_mode",
        shortcut: String? = nil,
        apps: [AppIdentifier] = [],
        windowLayouts: [WindowLayoutEntry]? = nil,
        projectPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortcut = shortcut
        self.apps = apps
        self.windowLayouts = windowLayouts
        self.projectPath = projectPath
    }
}

// MARK: - Convenience
extension Mode {
    /// Checks if an app is in this mode's app list (compares by bundleId only)
    func containsApp(_ app: AppIdentifier) -> Bool {
        apps.contains { $0.bundleId.lowercased() == app.bundleId.lowercased() }
    }
}
