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

    // Dock management
    var manageDock: Bool  // Whether to sync Dock with this mode's apps + Always Open

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        shortcut: String? = nil,
        apps: [AppEntry] = [],
        manageDock: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortcut = shortcut
        self.apps = apps
        self.manageDock = manageDock
    }

    // Custom decoding to handle missing keys for backwards compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        shortcut = try container.decodeIfPresent(String.self, forKey: .shortcut)
        apps = try container.decodeIfPresent([AppEntry].self, forKey: .apps) ?? []
        manageDock = try container.decodeIfPresent(Bool.self, forKey: .manageDock) ?? false
        // Note: dockConfiguration was removed - Dock now syncs automatically with mode apps
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

// MARK: - Mode Switcher Key

/// Which modifier key to double-tap to open the mode switcher
enum ModeSwitcherKey: String, Codable, CaseIterable {
    case option = "option"
    case command = "command"
    case control = "control"
    case shift = "shift"
    case disabled = "disabled"

    var displayName: String {
        switch self {
        case .option: return "Option + Option"
        case .command: return "Command + Command"
        case .control: return "Control + Control"
        case .shift: return "Shift + Shift"
        case .disabled: return "Disabled"
        }
    }

    var symbol: String {
        switch self {
        case .option: return "⌥ + ⌥"
        case .command: return "⌘ + ⌘"
        case .control: return "⌃ + ⌃"
        case .shift: return "⇧ + ⇧"
        case .disabled: return "—"
        }
    }
}

// MARK: - App Config (Root)

struct AppConfig: Codable, Equatable {
    static let currentVersion = 1

    var version: Int
    var globalAllowList: [AppEntry]
    var modes: [ModeConfig]

    // Settings
    var enableReapplyShortcut: Bool
    var forceCloseApps: Bool

    // Auto-reapply
    var enableAutoReapply: Bool
    var autoReapplyInterval: Int  // Minutes

    // Keyboard Shortcuts
    var modeSwitcherKey: ModeSwitcherKey  // Double-tap option
    var modeSwitcherShortcut: KeyboardShortcut?  // Custom shortcut (optional, in addition to double-tap)
    var reapplyShortcut: KeyboardShortcut?

    init(
        version: Int = currentVersion,
        globalAllowList: [AppEntry] = [],
        modes: [ModeConfig] = [],
        enableReapplyShortcut: Bool = false,
        forceCloseApps: Bool = false,
        enableAutoReapply: Bool = false,
        autoReapplyInterval: Int = 15,
        modeSwitcherKey: ModeSwitcherKey = .option,
        modeSwitcherShortcut: KeyboardShortcut? = nil,
        reapplyShortcut: KeyboardShortcut? = .defaultReapply
    ) {
        self.version = version
        self.globalAllowList = globalAllowList
        self.modes = modes
        self.enableReapplyShortcut = enableReapplyShortcut
        self.forceCloseApps = forceCloseApps
        self.enableAutoReapply = enableAutoReapply
        self.autoReapplyInterval = autoReapplyInterval
        self.modeSwitcherKey = modeSwitcherKey
        self.modeSwitcherShortcut = modeSwitcherShortcut
        self.reapplyShortcut = reapplyShortcut
    }

    // Custom decoding to handle missing keys for backwards compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? AppConfig.currentVersion
        globalAllowList = try container.decodeIfPresent([AppEntry].self, forKey: .globalAllowList) ?? []
        modes = try container.decodeIfPresent([ModeConfig].self, forKey: .modes) ?? []
        enableReapplyShortcut = try container.decodeIfPresent(Bool.self, forKey: .enableReapplyShortcut) ?? false
        forceCloseApps = try container.decodeIfPresent(Bool.self, forKey: .forceCloseApps) ?? false
        enableAutoReapply = try container.decodeIfPresent(Bool.self, forKey: .enableAutoReapply) ?? false
        autoReapplyInterval = try container.decodeIfPresent(Int.self, forKey: .autoReapplyInterval) ?? 15
        modeSwitcherKey = try container.decodeIfPresent(ModeSwitcherKey.self, forKey: .modeSwitcherKey) ?? .option
        modeSwitcherShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .modeSwitcherShortcut)
        reapplyShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .reapplyShortcut) ?? .defaultReapply
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
