import Cocoa

/// Controls the menu bar status item and mode selection.
final class MenuBarController {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var currentModeId: String?

    private var modes: [ModeConfig] { ConfigStore.shared.config.modes }

    // MARK: - Initialization

    init() {
        setupStatusItem()
        observeConfigChanges()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        button.title = "[DM]"
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

    @objc private func configDidChange() {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "DeskModes", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // Mode items
        for mode in modes {
            let title = "\(mode.icon) \(mode.name)"
            let item = NSMenuItem(title: title, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.representedObject = mode.id
            item.target = self

            if mode.id == currentModeId {
                item.state = .on
            }

            menu.addItem(item)
        }

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

    @objc private func modeSelected(_ sender: NSMenuItem) {
        guard let modeId = sender.representedObject as? String else { return }
        guard let mode = modes.first(where: { $0.id == modeId }) else { return }

        currentModeId = modeId
        rebuildMenu()

        print("Mode selected: \(mode.name)")
    }

    @objc private func openPreferences() {
        SettingsWindowController.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
