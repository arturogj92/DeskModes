import Foundation
import Cocoa  // Need AppKit for NSRunningApplication

/// Result of attempting to close an app
enum AppCloseResult {
    case closed
    case skipped(reason: String)
    case notRunning
    case failed(error: String)
}

/// Protocol for closing applications (for testability)
protocol AppClosing {
    func closeApp(_ app: AppIdentifier, forceClose: Bool) -> AppCloseResult
}

/// Infrastructure adapter that safely closes applications.
/// Uses NSRunningApplication.terminate() for safe quit (respects unsaved changes).
final class AppCloser: AppClosing {

    private let logger = Logger.shared

    /// Attempts to close an application.
    /// Uses terminate() which is equivalent to Cmd+Q (safe quit).
    /// If forceClose is true, uses forceTerminate() which kills the app immediately.
    func closeApp(_ app: AppIdentifier, forceClose: Bool = false) -> AppCloseResult {
        logger.info("Attempting to close: \(app.displayName) (force: \(forceClose))")

        // Find the running application by bundle ID
        let runningApps = NSWorkspace.shared.runningApplications
        guard let runningApp = runningApps.first(where: { $0.bundleIdentifier == app.bundleId }) else {
            logger.debug("\(app.displayName) is not running")
            return .notRunning
        }

        let terminated: Bool
        if forceClose {
            // Force terminate - kills immediately, may lose unsaved data
            terminated = runningApp.forceTerminate()
        } else {
            // Safe quit - respects unsaved changes, app may show dialog
            terminated = runningApp.terminate()
        }

        if terminated {
            logger.info("Closed app: \(app.displayName)")
            return .closed
        } else {
            // App refused to terminate (likely has unsaved changes)
            let reason = "App may have unsaved changes or refused to quit"
            logger.warning("Skipped app: \(app.displayName) (\(reason))")
            return .skipped(reason: reason)
        }
    }

    /// Closes multiple apps, continuing even if some fail.
    /// Returns a summary of results.
    func closeApps(_ apps: [AppIdentifier]) -> [AppIdentifier: AppCloseResult] {
        var results: [AppIdentifier: AppCloseResult] = [:]

        for app in apps {
            results[app] = closeApp(app)
        }

        return results
    }
}
