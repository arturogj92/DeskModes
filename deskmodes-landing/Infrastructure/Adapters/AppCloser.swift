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
    func closeApp(_ app: AppIdentifier) -> AppCloseResult
}

/// Infrastructure adapter that safely closes applications.
/// Uses NSRunningApplication.terminate() for safe quit (respects unsaved changes).
final class AppCloser: AppClosing {

    private let logger = Logger.shared

    /// Attempts to safely close an application.
    /// Uses terminate() which is equivalent to Cmd+Q.
    /// If the app has unsaved changes, it will show a dialog and may refuse to quit.
    func closeApp(_ app: AppIdentifier) -> AppCloseResult {
        logger.info("Attempting to close: \(app.displayName)")

        // Find the running application by bundle ID
        let runningApps = NSWorkspace.shared.runningApplications
        guard let runningApp = runningApps.first(where: { $0.bundleIdentifier == app.bundleId }) else {
            logger.debug("\(app.displayName) is not running")
            return .notRunning
        }

        // Attempt safe quit using terminate()
        // terminate() sends a quit event - respects unsaved changes
        // The app may show a save dialog and refuse to quit
        let terminated = runningApp.terminate()

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
