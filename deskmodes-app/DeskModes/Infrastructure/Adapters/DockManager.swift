import Foundation
import AppKit

/// Manages macOS Dock configuration - save, restore, and apply per mode.
/// Uses com.apple.dock.plist for persistent Dock items.
final class DockManager {

    // MARK: - Singleton

    static let shared = DockManager()

    // MARK: - Properties

    private let logger = Logger.shared
    private let dockPlistPath: String

    // MARK: - Initialization

    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        dockPlistPath = "\(homeDir)/Library/Preferences/com.apple.dock.plist"
    }

    // MARK: - Public API

    /// Reads the current Dock configuration and returns it as Data (plist format).
    /// Returns nil if unable to read.
    func getCurrentDockConfiguration() -> Data? {
        guard FileManager.default.fileExists(atPath: dockPlistPath) else {
            logger.error("Dock plist not found at: \(dockPlistPath)")
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: dockPlistPath))
            logger.info("Read Dock configuration (\(data.count) bytes)")
            return data
        } catch {
            logger.error("Failed to read Dock plist: \(error.localizedDescription)")
            return nil
        }
    }

    /// Restores a previously saved Dock configuration.
    /// - Parameter configuration: The plist data to restore
    /// - Parameter restartDock: Whether to restart the Dock after applying (default: true)
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func restoreDockConfiguration(_ configuration: Data, restartDock: Bool = true) -> Bool {
        // Create backup of current config (optional, continues even if nil)
        let currentConfig = getCurrentDockConfiguration()
        if currentConfig == nil {
            logger.warning("Could not create backup of current Dock config")
        }

        do {
            // Write the new configuration
            try configuration.write(to: URL(fileURLWithPath: dockPlistPath))
            logger.info("Wrote Dock configuration (\(configuration.count) bytes)")

            if restartDock {
                self.restartDock()
            }

            return true
        } catch {
            logger.error("Failed to write Dock plist: \(error.localizedDescription)")

            // Try to restore backup if we had one
            if let backup = currentConfig {
                try? backup.write(to: URL(fileURLWithPath: dockPlistPath))
            }

            return false
        }
    }

    /// Restarts the Dock to apply configuration changes.
    /// The Dock will briefly disappear and reappear.
    func restartDock() {
        logger.info("Restarting Dock...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]

        do {
            try process.run()
            process.waitUntilExit()
            logger.info("Dock restarted successfully")
        } catch {
            logger.error("Failed to restart Dock: \(error.localizedDescription)")
        }
    }

    /// Gets the list of persistent apps currently in the Dock.
    /// Returns bundle identifiers of apps pinned to the Dock.
    func getPersistentDockApps() -> [String] {
        guard let data = getCurrentDockConfiguration(),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let persistentApps = plist["persistent-apps"] as? [[String: Any]] else {
            return []
        }

        var bundleIds: [String] = []

        for app in persistentApps {
            if let tileData = app["tile-data"] as? [String: Any],
               let bundleId = tileData["bundle-identifier"] as? String {
                bundleIds.append(bundleId)
            }
        }

        return bundleIds
    }

    /// Checks if Dock management is available (file exists and is readable).
    var isDockManagementAvailable: Bool {
        FileManager.default.fileExists(atPath: dockPlistPath) &&
        FileManager.default.isReadableFile(atPath: dockPlistPath) &&
        FileManager.default.isWritableFile(atPath: dockPlistPath)
    }

    // MARK: - Dynamic Dock Management

    /// Sets the Dock to show only the specified apps.
    /// - Parameter apps: The apps to show in the Dock
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func setDockApps(_ apps: [AppIdentifier]) -> Bool {
        logger.info("Setting Dock apps: \(apps.map { $0.displayName }.joined(separator: ", "))")

        // Read current Dock plist
        guard let data = getCurrentDockConfiguration(),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            logger.error("Failed to read Dock plist for modification")
            return false
        }

        // Build new persistent-apps array
        var newPersistentApps: [[String: Any]] = []

        for app in apps {
            if let entry = createDockEntry(for: app) {
                newPersistentApps.append(entry)
            }
        }

        // Update the plist
        plist["persistent-apps"] = newPersistentApps

        // Serialize and write
        do {
            let newData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
            try newData.write(to: URL(fileURLWithPath: dockPlistPath))
            logger.info("Wrote Dock with \(newPersistentApps.count) apps")

            restartDock()
            return true
        } catch {
            logger.error("Failed to write Dock plist: \(error.localizedDescription)")
            return false
        }
    }

    /// Creates a Dock entry dictionary for an app.
    private func createDockEntry(for app: AppIdentifier) -> [String: Any]? {
        // Find the app path
        guard let appPath = findAppPath(for: app.bundleId) else {
            logger.warning("Could not find path for app: \(app.displayName) (\(app.bundleId))")
            return nil
        }

        let fileData: [String: Any] = [
            "_CFURLString": appPath,
            "_CFURLStringType": 15
        ]

        let tileData: [String: Any] = [
            "bundle-identifier": app.bundleId,
            "file-data": fileData,
            "file-label": app.displayName,
            "file-type": 41
        ]

        return [
            "tile-data": tileData,
            "tile-type": "file-tile"
        ]
    }

    /// Finds the application path for a bundle identifier.
    private func findAppPath(for bundleId: String) -> String? {
        // Use NSWorkspace to find the app
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return url.absoluteString
        }

        // Fallback: check common locations
        let possiblePaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for basePath in possiblePaths {
            if let apps = try? FileManager.default.contentsOfDirectory(atPath: basePath) {
                for appName in apps where appName.hasSuffix(".app") {
                    let appPath = "\(basePath)/\(appName)"
                    if let bundle = Bundle(path: appPath),
                       bundle.bundleIdentifier == bundleId {
                        return "file://\(appPath)/"
                    }
                }
            }
        }

        return nil
    }
}
