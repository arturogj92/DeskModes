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
    var allowList: [AppEntry]
    var appsToOpen: [AppEntry]

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        shortcut: String? = nil,
        allowList: [AppEntry] = [],
        appsToOpen: [AppEntry] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortcut = shortcut
        self.allowList = allowList
        self.appsToOpen = appsToOpen
    }

    /// Convert to domain Mode entity
    func toMode() -> Mode {
        Mode(
            id: id,
            name: name,
            icon: icon,
            shortcut: shortcut,
            allowList: allowList.map { $0.asAppIdentifier },
            appsToOpen: appsToOpen.map { $0.asAppIdentifier }
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
            globalAllowList: [
                AppEntry(bundleId: "net.whatsapp.WhatsApp", name: "WhatsApp"),
                AppEntry(bundleId: "ru.keepcoder.Telegram", name: "Telegram"),
                AppEntry(bundleId: "com.google.Chrome", name: "Chrome")
            ],
            modes: [
                ModeConfig(
                    name: "Work",
                    icon: "💼",
                    shortcut: "cmd+shift+1",
                    allowList: [
                        AppEntry(bundleId: "com.apple.Safari", name: "Safari"),
                        AppEntry(bundleId: "com.apple.Notes", name: "Notes"),
                        AppEntry(bundleId: "com.apple.reminders", name: "Reminders")
                    ],
                    appsToOpen: [
                        AppEntry(bundleId: "com.apple.Safari", name: "Safari")
                    ]
                ),
                ModeConfig(
                    name: "Dev",
                    icon: "💻",
                    shortcut: "cmd+shift+2",
                    allowList: [
                        AppEntry(bundleId: "com.todesktop.230313mzl4w4u92", name: "Cursor"),
                        AppEntry(bundleId: "com.microsoft.VSCode", name: "VS Code"),
                        AppEntry(bundleId: "com.apple.Terminal", name: "Terminal")
                    ],
                    appsToOpen: [
                        AppEntry(bundleId: "com.todesktop.230313mzl4w4u92", name: "Cursor")
                    ]
                ),
                ModeConfig(
                    name: "AI",
                    icon: "🤖",
                    shortcut: "cmd+shift+3",
                    allowList: [
                        AppEntry(bundleId: "com.openai.chat", name: "ChatGPT"),
                        AppEntry(bundleId: "com.anthropic.claudefordesktop", name: "Claude")
                    ],
                    appsToOpen: [
                        AppEntry(bundleId: "com.anthropic.claudefordesktop", name: "Claude")
                    ]
                )
            ]
        )
    }
}
