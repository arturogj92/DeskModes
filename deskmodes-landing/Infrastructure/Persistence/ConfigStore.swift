import Foundation

/// Notification posted when configuration changes
extension Notification.Name {
    static let configDidChange = Notification.Name("DeskModesConfigDidChange")
}

/// Manages persistence of app configuration to JSON file.
final class ConfigStore {

    // MARK: - Singleton

    static let shared = ConfigStore()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let logger = Logger.shared

    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceInterval: TimeInterval = 0.5

    private(set) var config: AppConfig {
        didSet {
            scheduleSave()
            NotificationCenter.default.post(name: .configDidChange, object: self)
        }
    }

    // MARK: - Paths

    private var appSupportURL: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0].appendingPathComponent("DeskModes", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        return appSupport
    }

    private var configFileURL: URL {
        appSupportURL.appendingPathComponent("config.json")
    }

    private var backupFileURL: URL {
        appSupportURL.appendingPathComponent("config.json.bak")
    }

    // MARK: - Initialization

    private init() {
        self.config = AppConfig.defaultConfig
        loadConfig()
    }

    // MARK: - Public API

    /// Reload configuration from disk
    func loadConfig() {
        guard fileManager.fileExists(atPath: configFileURL.path) else {
            logger.info("No config file found, using defaults")
            config = AppConfig.defaultConfig
            saveImmediately()
            return
        }

        do {
            let data = try Data(contentsOf: configFileURL)
            let loadedConfig = try JSONDecoder().decode(AppConfig.self, from: data)
            config = loadedConfig
            logger.info("Config loaded successfully")
        } catch {
            logger.error("Failed to load config: \(error.localizedDescription)")
            tryLoadBackup()
        }
    }

    /// Force immediate save
    func saveImmediately() {
        saveWorkItem?.cancel()
        performSave()
    }

    // MARK: - Mode Operations

    func addMode(_ mode: ModeConfig) {
        var newConfig = config
        newConfig.modes.append(mode)
        config = newConfig
    }

    func updateMode(_ mode: ModeConfig) {
        var newConfig = config
        if let index = newConfig.modes.firstIndex(where: { $0.id == mode.id }) {
            newConfig.modes[index] = mode
            config = newConfig
        }
    }

    func deleteMode(id: String) {
        var newConfig = config
        newConfig.modes.removeAll { $0.id == id }
        config = newConfig
    }

    func reorderModes(from: Int, to: Int) {
        var newConfig = config
        let mode = newConfig.modes.remove(at: from)
        newConfig.modes.insert(mode, at: to)
        config = newConfig
    }

    // MARK: - Global Allow List Operations

    func addToGlobalAllowList(_ app: AppEntry) {
        guard !config.globalAllowList.contains(where: { $0.bundleId == app.bundleId }) else { return }
        var newConfig = config
        newConfig.globalAllowList.append(app)
        config = newConfig
    }

    func removeFromGlobalAllowList(bundleId: String) {
        var newConfig = config
        newConfig.globalAllowList.removeAll { $0.bundleId == bundleId }
        config = newConfig
    }

    func updateGlobalAllowList(_ apps: [AppEntry]) {
        var newConfig = config
        newConfig.globalAllowList = apps
        config = newConfig
    }

    // MARK: - Private Methods

    private func scheduleSave() {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }

        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
    }

    private func performSave() {
        // Create backup first
        if fileManager.fileExists(atPath: configFileURL.path) {
            try? fileManager.removeItem(at: backupFileURL)
            try? fileManager.copyItem(at: configFileURL, to: backupFileURL)
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFileURL, options: .atomic)
            logger.debug("Config saved to \(configFileURL.path)")
        } catch {
            logger.error("Failed to save config: \(error.localizedDescription)")
        }
    }

    private func tryLoadBackup() {
        guard fileManager.fileExists(atPath: backupFileURL.path) else {
            logger.warning("No backup found, using defaults")
            config = AppConfig.defaultConfig
            saveImmediately()
            return
        }

        do {
            let data = try Data(contentsOf: backupFileURL)
            let loadedConfig = try JSONDecoder().decode(AppConfig.self, from: data)
            config = loadedConfig
            logger.info("Config loaded from backup")
            saveImmediately() // Save to main file
        } catch {
            logger.error("Failed to load backup: \(error.localizedDescription)")
            config = AppConfig.defaultConfig
            saveImmediately()
        }
    }
}
