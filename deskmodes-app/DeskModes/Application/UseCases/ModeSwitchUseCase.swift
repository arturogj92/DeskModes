import Foundation

/// Result of a mode switch operation
struct ModeSwitchResult {
    let targetMode: Mode
    let closedApps: [AppIdentifier]
    let skippedApps: [(app: AppIdentifier, reason: String)]
    let openedApps: [AppIdentifier]
    let failedToOpen: [(app: AppIdentifier, error: String)]
    let success: Bool
}

/// Protocol for mode switching (for testability)
protocol ModeSwitching {
    func switchTo(mode: Mode) async -> ModeSwitchResult
}

/// Application use case that orchestrates mode switching.
/// Coordinates: AppLister, AppCloser, AppLauncher, GlobalAllowList
final class ModeSwitchUseCase: ModeSwitching {

    // MARK: - Dependencies
    private let appLister: AppListing
    private let appCloser: AppClosing
    private let appLauncher: AppLaunching
    private let modeManager: ModeManaging
    private let logger = Logger.shared

    // MARK: - Initialization
    init(
        appLister: AppListing,
        appCloser: AppClosing,
        appLauncher: AppLaunching,
        modeManager: ModeManaging
    ) {
        self.appLister = appLister
        self.appCloser = appCloser
        self.appLauncher = appLauncher
        self.modeManager = modeManager
    }

    // MARK: - Mode Switch Flow

    /// Switches to the specified mode.
    /// Flow:
    /// 1. List all running user-facing apps
    /// 2. Close apps not in "Always Open" (global) or mode's apps list
    /// 3. Launch mode's apps if not already running
    /// 4. Return summary
    func switchTo(mode: Mode) async -> ModeSwitchResult {
        logger.info("=== Mode switch started: \(mode.name) ===")

        var closedApps: [AppIdentifier] = []
        var skippedApps: [(app: AppIdentifier, reason: String)] = []
        var openedApps: [AppIdentifier] = []
        var failedToOpen: [(app: AppIdentifier, error: String)] = []

        // Step 1: List all running user-facing apps
        let runningApps = appLister.listRunningApps()
        logger.info("Found \(runningApps.count) running apps")

        // Step 2: Close apps not in allow lists
        for app in runningApps {
            // Check global allow list (Always Open apps)
            if modeManager.globalAllowList.isProtected(app.bundleId) {
                logger.debug("Keeping (global Always Open): \(app.displayName)")
                continue
            }

            // Check if app is in this mode's apps list
            if mode.containsApp(app) {
                logger.debug("Keeping (mode app): \(app.displayName)")
                continue
            }

            // App should be closed (respect force close setting)
            let forceClose = ConfigStore.shared.config.forceCloseApps
            let result = appCloser.closeApp(app, forceClose: forceClose)
            switch result {
            case .closed:
                closedApps.append(app)
            case .skipped(let reason):
                skippedApps.append((app: app, reason: reason))
            case .notRunning:
                // Shouldn't happen since we just listed running apps
                break
            case .failed(let error):
                skippedApps.append((app: app, reason: error))
            }
        }

        // Step 3: Open apps in the mode (launch if not already running)
        for app in mode.apps {
            let result = await appLauncher.launchApp(app)
            switch result {
            case .launched:
                openedApps.append(app)
            case .alreadyRunning:
                logger.debug("\(app.displayName) already running")
            case .failed(let error):
                failedToOpen.append((app: app, error: error))
            }
        }

        // Step 4: Open "Always Open" apps from globalAllowList (launch if not already running)
        for app in modeManager.globalAllowList.apps {
            // Skip if already in mode apps (to avoid duplicate launch attempts)
            if mode.containsApp(app) {
                continue
            }
            let result = await appLauncher.launchApp(app)
            switch result {
            case .launched:
                openedApps.append(app)
            case .alreadyRunning:
                logger.debug("\(app.displayName) (Always Open) already running")
            case .failed(let error):
                failedToOpen.append((app: app, error: error))
            }
        }

        // Step 5: Apply Dock configuration if enabled
        applyDockConfiguration(for: mode)

        // Step 6: Log summary
        logSummary(mode: mode, closed: closedApps, skipped: skippedApps, opened: openedApps, failed: failedToOpen)

        // Update current mode
        modeManager.setCurrentMode(mode)

        logger.info("=== Mode switch completed: \(mode.name) ===")

        return ModeSwitchResult(
            targetMode: mode,
            closedApps: closedApps,
            skippedApps: skippedApps,
            openedApps: openedApps,
            failedToOpen: failedToOpen,
            success: failedToOpen.isEmpty
        )
    }

    // MARK: - Dock Management

    private func applyDockConfiguration(for mode: Mode) {
        // Get the mode config to check Dock settings
        guard let modeConfig = ConfigStore.shared.config.modes.first(where: { $0.id == mode.id }) else {
            logger.debug("Mode config not found for Dock check: \(mode.name)")
            return
        }

        // Check if Dock management is enabled for this mode
        guard modeConfig.manageDock else {
            logger.debug("Dock management disabled for mode: \(mode.name)")
            return
        }

        // Build the Dock apps list: mode apps + Always Open apps
        var dockApps: [AppIdentifier] = []

        // Add Always Open apps first (they appear on the left side of Dock)
        for app in modeManager.globalAllowList.apps {
            dockApps.append(app)
        }

        // Add mode apps (excluding duplicates from Always Open)
        for app in mode.apps {
            if !dockApps.contains(where: { $0.bundleId == app.bundleId }) {
                dockApps.append(app)
            }
        }

        logger.info("Setting Dock for mode '\(mode.name)' with \(dockApps.count) apps")

        // Apply the dynamic Dock configuration
        let success = DockManager.shared.setDockApps(dockApps)

        if success {
            logger.info("Dock updated successfully for mode: \(mode.name)")
        } else {
            logger.error("Failed to update Dock for mode: \(mode.name)")
        }
    }

    // MARK: - Logging

    private func logSummary(
        mode: Mode,
        closed: [AppIdentifier],
        skipped: [(app: AppIdentifier, reason: String)],
        opened: [AppIdentifier],
        failed: [(app: AppIdentifier, error: String)]
    ) {
        logger.info("--- Mode Switch Summary ---")
        logger.info("Target mode: \(mode.name)")

        if !closed.isEmpty {
            logger.info("Closed (\(closed.count)):")
            for app in closed {
                logger.info("  - \(app.displayName)")
            }
        }

        if !skipped.isEmpty {
            logger.warning("Skipped (\(skipped.count)):")
            for (app, reason) in skipped {
                logger.warning("  - \(app.displayName): \(reason)")
            }
        }

        if !opened.isEmpty {
            logger.info("Opened (\(opened.count)):")
            for app in opened {
                logger.info("  - \(app.displayName)")
            }
        }

        if !failed.isEmpty {
            logger.error("Failed to open (\(failed.count)):")
            for (app, error) in failed {
                logger.error("  - \(app.displayName): \(error)")
            }
        }

        logger.info("---------------------------")
    }
}
