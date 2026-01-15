import Foundation

/// Protocol for mode storage and retrieval (for testability)
protocol ModeManaging {
    var availableModes: [Mode] { get }
    var currentMode: Mode? { get }
    var globalAllowList: GlobalAllowList { get }

    func getMode(byId id: String) -> Mode?
    func setCurrentMode(_ mode: Mode)
    func switchToMode(id: String)
}

/// Application service that manages modes.
/// Loads modes from ConfigStore for persistence.
final class ModeManager: ModeManaging {

    // MARK: - Singleton

    static let shared = ModeManager()

    // MARK: - Properties

    private(set) var availableModes: [Mode] = []
    private(set) var currentMode: Mode?
    private(set) var globalAllowList: GlobalAllowList

    private let logger = Logger.shared

    // MARK: - Initialization

    private init() {
        self.globalAllowList = GlobalAllowList(apps: [])
        self.availableModes = []
        loadFromConfigStore()
        observeConfigChanges()
        logger.info("ModeManager initialized with \(availableModes.count) modes")
    }

    // MARK: - Config Observation

    private func observeConfigChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: .configDidChange,
            object: nil
        )
    }

    @objc private func configDidChange() {
        loadFromConfigStore()
    }

    private func loadFromConfigStore() {
        let config = ConfigStore.shared.config

        // Convert ModeConfig to Mode entities
        availableModes = config.modes.map { modeConfig in
            Mode(
                id: modeConfig.id,
                name: modeConfig.name,
                icon: modeConfig.icon,
                shortcut: modeConfig.shortcut,
                apps: modeConfig.apps.map { AppIdentifier(bundleId: $0.bundleId, displayName: $0.name) }
            )
        }

        // Convert global allow list (Always Open apps)
        globalAllowList = GlobalAllowList(
            apps: config.globalAllowList.map { AppIdentifier(bundleId: $0.bundleId, displayName: $0.name) }
        )

        logger.debug("Loaded \(availableModes.count) modes from ConfigStore")
    }

    // MARK: - Mode Access

    func getMode(byId id: String) -> Mode? {
        availableModes.first { $0.id == id }
    }

    func setCurrentMode(_ mode: Mode) {
        currentMode = mode
        logger.info("Current mode set to: \(mode.name)")
    }

    func switchToMode(id: String) {
        guard let mode = getMode(byId: id) else {
            logger.warning("Mode not found: \(id)")
            return
        }

        setCurrentMode(mode)
        logger.info("Switching to mode: \(mode.name)")

        // TODO: Implement actual mode switching logic
        // 1. Close apps not in allowList (respecting globalAllowList)
        // 2. Open apps in appsToOpen
    }
}
