import Foundation

/// Represents a work context/mode that defines which apps should be open.
/// Domain layer - no dependencies on AppKit or system APIs.
struct Mode: Identifiable, Equatable {
    /// Unique identifier for the mode
    let id: String

    /// Human-readable name (e.g., "Work", "Dev", "AI")
    let name: String

    /// Icon/emoji for the mode (e.g., "💼", "💻", "🤖")
    let icon: String

    /// Global keyboard shortcut (e.g., "cmd+shift+1")
    let shortcut: String?

    /// Apps that should remain open when switching to this mode
    let allowList: [AppIdentifier]

    /// Apps that must be opened if not running when switching to this mode
    let appsToOpen: [AppIdentifier]

    /// Optional window layouts for apps (placeholder for future)
    let windowLayouts: [WindowLayoutEntry]?

    /// Optional project path for Dev mode (IDE will open this)
    let projectPath: String?

    init(
        id: String,
        name: String,
        icon: String = "📁",
        shortcut: String? = nil,
        allowList: [AppIdentifier] = [],
        appsToOpen: [AppIdentifier] = [],
        windowLayouts: [WindowLayoutEntry]? = nil,
        projectPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortcut = shortcut
        self.allowList = allowList
        self.appsToOpen = appsToOpen
        self.windowLayouts = windowLayouts
        self.projectPath = projectPath
    }
}

// MARK: - Convenience
extension Mode {
    /// Checks if an app is in this mode's allow list
    func isAppAllowed(_ app: AppIdentifier) -> Bool {
        allowList.contains(app)
    }

    /// Checks if an app should be opened for this mode
    func shouldOpenApp(_ app: AppIdentifier) -> Bool {
        appsToOpen.contains(app)
    }
}
