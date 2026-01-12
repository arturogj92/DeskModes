import Foundation
import Cocoa  // Need AppKit for NSWorkspace

/// Protocol for listing running applications (for testability)
protocol AppListing {
    func listRunningApps() -> [AppIdentifier]
}

/// Infrastructure adapter that lists running user-facing applications.
/// Uses NSWorkspace to get the list of running applications.
final class AppLister: AppListing {

    private let logger = Logger.shared

    /// Lists all running user-facing applications.
    /// Filters out background agents and system processes.
    func listRunningApps() -> [AppIdentifier] {
        let runningApps = NSWorkspace.shared.runningApplications

        var userApps: [AppIdentifier] = []

        for app in runningApps {
            // Skip apps without bundle identifiers (system processes)
            guard let bundleId = app.bundleIdentifier else {
                continue
            }

            // Only include regular applications (not background agents)
            // activationPolicy == .regular means it appears in Dock/Cmd+Tab
            guard app.activationPolicy == .regular else {
                continue
            }

            // Skip our own app
            guard bundleId != Bundle.main.bundleIdentifier else {
                continue
            }

            let displayName = app.localizedName ?? bundleId.components(separatedBy: ".").last ?? bundleId
            let appIdentifier = AppIdentifier(bundleId: bundleId, displayName: displayName)
            userApps.append(appIdentifier)
        }

        logger.debug("Found \(userApps.count) running user apps")
        return userApps
    }
}
