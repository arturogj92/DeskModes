import Cocoa

/// Window controller for the Settings/Preferences window.
final class SettingsWindowController: NSWindowController {

    // MARK: - Singleton

    private static var shared: SettingsWindowController?

    static func showSettings() {
        if shared == nil {
            shared = SettingsWindowController()
        }
        shared?.showWindow(nil)
        shared?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Properties

    private let settingsViewController = SettingsViewController()

    // MARK: - Initialization

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "DeskModes Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = settingsViewController

        // Set minimum and maximum size
        window.minSize = NSSize(width: 600, height: 400)
        window.maxSize = NSSize(width: 1200, height: 800)

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Window Delegate

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self
    }
}

// MARK: - NSWindowDelegate

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Save any pending changes
        ConfigStore.shared.saveImmediately()
    }
}
