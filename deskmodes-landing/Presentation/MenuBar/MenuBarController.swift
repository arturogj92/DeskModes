import Cocoa

/// Controls the menu bar status item and mode selection.
final class MenuBarController {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var currentModeId: String?

    private var modes: [ModeConfig] { ConfigStore.shared.config.modes }

    // Pause state (persisted in UserDefaults)
    private var isPaused: Bool {
        get { UserDefaults.standard.bool(forKey: "DeskModes.isPaused") }
        set { UserDefaults.standard.set(newValue, forKey: "DeskModes.isPaused") }
    }

    // Remember last active mode for resuming
    private var lastActiveModeId: String? {
        get { UserDefaults.standard.string(forKey: "DeskModes.lastActiveModeId") }
        set { UserDefaults.standard.set(newValue, forKey: "DeskModes.lastActiveModeId") }
    }

    // Mode switching
    private lazy var modeSwitchUseCase: ModeSwitchUseCase = {
        ModeSwitchUseCase(
            appLister: AppLister(),
            appCloser: AppCloser(),
            appLauncher: AppLauncher(),
            modeManager: ModeManager.shared
        )
    }()

    // Global hotkey monitors (for modifier double-tap)
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastCommandPressTime: Date?
    private var lastOptionPressTime: Date?

    // Auto-reapply timer
    private var autoReapplyTimer: Timer?

    // MARK: - Initialization

    init() {
        setupStatusItem()
        observeConfigChanges()
        setupGlobalHotkey()
        setupAutoReapplyTimer()
        setupCarbonHotkeys()
        warmUpComponents()
    }

    /// Pre-initialize lazy components to avoid lag on first mode switch
    private func warmUpComponents() {
        // Touch modeSwitchUseCase to trigger lazy initialization
        _ = modeSwitchUseCase
        // Pre-load the system sound
        _ = NSSound(named: "Purr")
    }

    private func setupCarbonHotkeys() {
        // Setup callbacks for Carbon global hotkeys
        GlobalHotkeyManager.shared.onModeSwitcherTriggered = { [weak self] in
            self?.showModeSelector()
        }
        GlobalHotkeyManager.shared.onReapplyTriggered = { [weak self] in
            self?.reapplyCurrentMode()
        }
        // Register current hotkeys
        GlobalHotkeyManager.shared.updateHotkeys()
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        autoReapplyTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        // Try to load menu bar icon
        if let iconPath = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = false  // Keep original colors
            button.image = icon
        } else {
            // Fallback to text
            button.title = "⚡"
        }
        rebuildMenu()
    }

    private func observeConfigChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: .configDidChange,
            object: nil
        )
    }

    private func setupAutoReapplyTimer() {
        // Invalidate existing timer
        autoReapplyTimer?.invalidate()
        autoReapplyTimer = nil

        let config = ConfigStore.shared.config

        // Only start timer if auto-reapply is enabled
        guard config.enableAutoReapply else {
            print("⏱️ Auto-reapply disabled")
            return
        }

        let intervalSeconds = TimeInterval(config.autoReapplyInterval * 60)
        print("⏱️ Auto-reapply enabled: every \(config.autoReapplyInterval) minutes")

        autoReapplyTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Only auto-reapply if not paused and a mode is active
            guard !self.isPaused, self.currentModeId != nil else {
                print("⏱️ Auto-reapply skipped: paused=\(self.isPaused), currentModeId=\(self.currentModeId ?? "nil")")
                return
            }

            print("⏱️ Auto-reapply triggered")
            DispatchQueue.main.async {
                self.reapplyCurrentMode()
            }
        }
    }

    private func setupGlobalHotkey() {
        // Double-tap modifier key to open Mode Selector
        // Note: Custom shortcuts (like ⌘⇧0) are handled by Carbon in GlobalHotkeyManager
        let doubleTapInterval: TimeInterval = 0.3

        // Monitor flags changed (for modifier double-tap detection)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierDoubleTap(event: event, interval: doubleTapInterval)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierDoubleTap(event: event, interval: doubleTapInterval)
            return event
        }

        print("🔑 Modifier double-tap monitors registered (Carbon handles custom shortcuts)")
    }

    private func logToFile(_ message: String) {
        let logFile = "/tmp/deskmodes_keys.log"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile) {
                if let handle = FileHandle(forWritingAtPath: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logFile, contents: data)
            }
        }
    }

    private func showModeSelector() {
        logToFile("✅ Mode selector triggered!")

        ModeSelectorOverlay.show(
            modes: modes,
            currentModeId: currentModeId
        ) { [weak self] modeId in
            guard let self = self,
                  let modeConfig = self.modes.first(where: { $0.id == modeId }) else { return }

            // If paused, unpause
            if self.isPaused {
                self.isPaused = false
            }

            self.activateMode(modeConfig, isReapply: false)
        }
    }

    private var lastControlPressTime: Date?
    private var lastShiftPressTime: Date?

    private func handleModifierDoubleTap(event: NSEvent, interval: TimeInterval) {
        // Detect Command key release (keyUp for modifier)
        // keyCode 55 = Left Command, 54 = Right Command
        let isCommandKey = event.keyCode == 55 || event.keyCode == 54
        let commandReleased = isCommandKey && !event.modifierFlags.contains(.command)

        // Detect Option key release
        // keyCode 58 = Left Option, 61 = Right Option
        let isOptionKey = event.keyCode == 58 || event.keyCode == 61
        let optionReleased = isOptionKey && !event.modifierFlags.contains(.option)

        // Detect Control key release
        // keyCode 59 = Left Control, 62 = Right Control
        let isControlKey = event.keyCode == 59 || event.keyCode == 62
        let controlReleased = isControlKey && !event.modifierFlags.contains(.control)

        // Detect Shift key release
        // keyCode 56 = Left Shift, 60 = Right Shift
        let isShiftKey = event.keyCode == 56 || event.keyCode == 60
        let shiftReleased = isShiftKey && !event.modifierFlags.contains(.shift)

        let now = Date()
        let modeSwitcherKey = ConfigStore.shared.config.modeSwitcherKey

        // Handle Command double-tap
        if commandReleased {
            if let lastPress = lastCommandPressTime,
               now.timeIntervalSince(lastPress) < interval {
                lastCommandPressTime = nil
                if modeSwitcherKey == .command {
                    DispatchQueue.main.async { [weak self] in
                        self?.showModeSelector()
                    }
                }
            } else {
                lastCommandPressTime = now
            }
        }

        // Handle Option double-tap
        if optionReleased {
            if let lastPress = lastOptionPressTime,
               now.timeIntervalSince(lastPress) < interval {
                lastOptionPressTime = nil
                if modeSwitcherKey == .option {
                    DispatchQueue.main.async { [weak self] in
                        self?.showModeSelector()
                    }
                }
            } else {
                lastOptionPressTime = now
            }
        }

        // Handle Control double-tap
        if controlReleased {
            if let lastPress = lastControlPressTime,
               now.timeIntervalSince(lastPress) < interval {
                lastControlPressTime = nil
                if modeSwitcherKey == .control {
                    DispatchQueue.main.async { [weak self] in
                        self?.showModeSelector()
                    }
                }
            } else {
                lastControlPressTime = now
            }
        }

        // Handle Shift double-tap
        if shiftReleased {
            if let lastPress = lastShiftPressTime,
               now.timeIntervalSince(lastPress) < interval {
                lastShiftPressTime = nil
                if modeSwitcherKey == .shift {
                    DispatchQueue.main.async { [weak self] in
                        self?.showModeSelector()
                    }
                }
            } else {
                lastShiftPressTime = now
            }
        }
    }

    @objc private func configDidChange() {
        rebuildMenu()
        setupAutoReapplyTimer()  // Restart timer with new config
        GlobalHotkeyManager.shared.updateHotkeys()  // Update Carbon hotkeys
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Header with app icon
        let headerItem = NSMenuItem(title: "DeskModes", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            icon.size = NSSize(width: 20, height: 20)
            headerItem.image = icon
        }
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // Mode items
        for mode in modes {
            let item = NSMenuItem(title: mode.name, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.representedObject = mode.id
            item.target = self

            // Load mode icon
            if let icon = loadModeIcon(named: mode.icon) {
                icon.size = NSSize(width: 22, height: 22)
                item.image = icon
            }

            // Show checkmark only if not paused and this is the current mode
            if !isPaused && mode.id == currentModeId {
                item.state = .on
            }

            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Reapply current mode (only if a mode is active)
        if !isPaused, let currentId = currentModeId,
           let currentMode = modes.first(where: { $0.id == currentId }) {
            let reapplyItem = NSMenuItem(
                title: "Reapply \(currentMode.name) Mode",
                action: #selector(reapplyCurrentMode),
                keyEquivalent: "r"
            )
            reapplyItem.keyEquivalentModifierMask = [.command, .shift]
            reapplyItem.target = self
            menu.addItem(reapplyItem)
        }

        // Pause DeskModes toggle
        let pauseItem = NSMenuItem(
            title: "Pause DeskModes",
            action: #selector(togglePause),
            keyEquivalent: ""
        )
        pauseItem.target = self
        pauseItem.state = isPaused ? .on : .off
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit DeskModes", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func togglePause() {
        if isPaused {
            // Unpausing - restore last active mode
            isPaused = false
            rebuildMenu()

            // Restore and activate last mode if available
            if let lastModeId = lastActiveModeId,
               let modeConfig = modes.first(where: { $0.id == lastModeId }) {
                ToastWindow.show(message: "DeskModes resumed")
                activateMode(modeConfig, isReapply: false)
            } else {
                ToastWindow.show(message: "DeskModes resumed")
            }
        } else {
            // Pausing - store current mode
            lastActiveModeId = currentModeId
            currentModeId = nil
            isPaused = true
            rebuildMenu()
            ToastWindow.show(message: "DeskModes paused")
        }
    }

    @objc private func modeSelected(_ sender: NSMenuItem) {
        guard let modeId = sender.representedObject as? String else { return }
        guard let modeConfig = modes.first(where: { $0.id == modeId }) else { return }

        // If paused, unpause and activate this mode
        if isPaused {
            isPaused = false
        }

        activateMode(modeConfig, isReapply: false)
    }

    @objc private func reapplyCurrentMode() {
        guard let currentId = currentModeId,
              let modeConfig = modes.first(where: { $0.id == currentId }) else { return }

        activateMode(modeConfig, isReapply: true)
    }

    private func activateMode(_ modeConfig: ModeConfig, isReapply: Bool) {
        // Play mode switch sound (stop previous first to allow quick re-trigger)
        if let sound = NSSound(named: "Purr") {
            sound.stop()
            sound.play()
        }

        // Update UI immediately (only if not reapplying same mode)
        if !isReapply {
            currentModeId = modeConfig.id
            lastActiveModeId = modeConfig.id
            rebuildMenu()
        }

        // Convert ModeConfig to Mode entity
        let mode = Mode(
            id: modeConfig.id,
            name: modeConfig.name,
            icon: modeConfig.icon,
            shortcut: modeConfig.shortcut,
            apps: modeConfig.apps.map { AppIdentifier(bundleId: $0.bundleId, displayName: $0.name) }
        )

        // Execute mode switch asynchronously
        let reapply = isReapply
        Task {
            let result = await modeSwitchUseCase.switchTo(mode: mode)

            // Show HUD on main thread
            await MainActor.run {
                showModeSwitchHUD(result: result, modeName: mode.name, modeIcon: modeConfig.icon, isReapply: reapply)
            }
        }
    }

    private func showModeSwitchHUD(result: ModeSwitchResult, modeName: String, modeIcon: String, isReapply: Bool) {
        let action = isReapply ? "reapplied" : "activated"
        print("🎯 showModeSwitchHUD called for: \(modeName) (\(action))")
        print("   closedApps: \(result.closedApps.count) - \(result.closedApps.map { $0.displayName })")
        print("   openedApps: \(result.openedApps.count) - \(result.openedApps.map { $0.displayName })")
        print("   skippedApps: \(result.skippedApps.count) - \(result.skippedApps.map { $0.app.displayName })")

        // If no changes, show simple toast with mode icon
        if result.closedApps.isEmpty && result.openedApps.isEmpty && result.skippedApps.isEmpty {
            print("   ➡️ No changes, showing simple toast")
            let message = isReapply ? "\(modeName) mode reapplied" : "\(modeName) mode activated"
            ToastWindow.show(message: message, modeIcon: modeIcon)
            return
        }

        print("   ➡️ Changes detected, showing HUD")
        // Build HUD data with app icons
        let hudData = ModeSwitchHUDData(
            modeName: modeName,
            modeIcon: modeIcon,
            isReapply: isReapply,
            closedApps: result.closedApps.map { appToDisplayInfo($0) },
            openedApps: result.openedApps.map { appToDisplayInfo($0) },
            skippedApps: result.skippedApps.map { appToDisplayInfo($0.app) }
        )

        ModeSwitchHUD.show(data: hudData)
    }

    private func appToDisplayInfo(_ app: AppIdentifier) -> ModeSwitchHUDData.AppDisplayInfo {
        // Get app icon from bundle
        var icon: NSImage?
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
            icon = NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return ModeSwitchHUDData.AppDisplayInfo(
            name: app.displayName,
            bundleId: app.bundleId,
            icon: icon
        )
    }

    @objc private func openPreferences() {
        SettingsWindowController.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    private func loadModeIcon(named name: String) -> NSImage? {
        // Try to load from ModeIcons folder
        if let iconPath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "ModeIcons"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        // Fallback: try without directory
        if let iconPath = Bundle.main.path(forResource: name, ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        return nil
    }
}
