import Foundation
import Cocoa  // Need AppKit for NSWorkspace

/// Result of attempting to launch an app
enum AppLaunchResult {
    case launched
    case alreadyRunning
    case failed(error: String)
}

/// Protocol for launching applications (for testability)
protocol AppLaunching {
    func launchApp(_ app: AppIdentifier) async -> AppLaunchResult
    func isAppRunning(_ app: AppIdentifier) -> Bool
}

/// Infrastructure adapter that launches applications.
/// Uses NSWorkspace to open applications by bundle identifier.
final class AppLauncher: AppLaunching {

    private let logger = Logger.shared

    /// Checks if an application is currently running
    func isAppRunning(_ app: AppIdentifier) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == app.bundleId }
    }

    /// Launches an application by its bundle identifier.
    /// Uses NSWorkspace.openApplication for modern, async app launching.
    func launchApp(_ app: AppIdentifier) async -> AppLaunchResult {
        logger.info("Attempting to launch: \(app.displayName)")

        // Check if already running
        if isAppRunning(app) {
            logger.debug("\(app.displayName) is already running")
            return .alreadyRunning
        }

        // Get the app URL from bundle ID
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) else {
            let error = "Could not find application with bundle ID: \(app.bundleId)"
            logger.error(error)
            return .failed(error: error)
        }

        do {
            // Launch the application
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false  // Don't steal focus

            _ = try await NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)

            logger.info("Launched app: \(app.displayName)")
            return .launched
        } catch {
            let errorMessage = "Failed to launch \(app.displayName): \(error.localizedDescription)"
            logger.error(errorMessage)
            return .failed(error: errorMessage)
        }
    }

    /// Launches multiple apps, continuing even if some fail.
    func launchApps(_ apps: [AppIdentifier]) async -> [AppIdentifier: AppLaunchResult] {
        var results: [AppIdentifier: AppLaunchResult] = [:]

        for app in apps {
            results[app] = await launchApp(app)
        }

        return results
    }
}
