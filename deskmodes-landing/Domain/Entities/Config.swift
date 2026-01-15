import Foundation

// MARK: - App Entry

struct AppEntry: Codable, Equatable, Hashable, Identifiable {
    var id: String { bundleId }
    let bundleId: String
    var name: String

    init(bundleId: String, name: String) {
        self.bundleId = bundleId
        self.name = name
    }

    init(from appIdentifier: AppIdentifier) {
        self.bundleId = appIdentifier.bundleId
        self.name = appIdentifier.displayName
    }

    var asAppIdentifier: AppIdentifier {
        AppIdentifier(bundleId: bundleId, displayName: name)
    }
}

// MARK: - Mode Config

struct ModeConfig: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var icon: String
    var shortcut: String?
    var apps: [AppEntry]  // Single list: apps that should be open in this mode

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        shortcut: String? = nil,
        apps: [AppEntry] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortcut = shortcut
        self.apps = apps
    }

    /// Convert to domain Mode entity
    func toMode() -> Mode {
        Mode(
            id: id,
            name: name,
            icon: icon,
            shortcut: shortcut,
            apps: apps.map { $0.asAppIdentifier }
        )
    }
}

// MARK: - App Config (Root)

struct AppConfig: Codable, Equatable {
    static let currentVersion = 1

    var version: Int
    var globalAllowList: [AppEntry]
    var modes: [ModeConfig]

    init(
        version: Int = currentVersion,
        globalAllowList: [AppEntry] = [],
        modes: [ModeConfig] = []
    ) {
        self.version = version
        self.globalAllowList = globalAllowList
        self.modes = modes
    }

    /// Default configuration for first launch
    static var defaultConfig: AppConfig {
        AppConfig(
            version: currentVersion,
            globalAllowList: [],
            modes: [
                ModeConfig(
                    name: "Work",
                    icon: "work_mode",
                    shortcut: "cmd+shift+1",
                    apps: []
                ),
                ModeConfig(
                    name: "Dev",
                    icon: "dev_mode",
                    shortcut: "cmd+shift+2",
                    apps: []
                ),
                ModeConfig(
                    name: "AI",
                    icon: "ai_mode",
                    shortcut: "cmd+shift+3",
                    apps: []
                )
            ]
        )
    }
}
