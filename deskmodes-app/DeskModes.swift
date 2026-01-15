import Cocoa

// MARK: - Domain

struct AppIdentifier: Equatable, Hashable {
    let bundleId: String
    let displayName: String
}

struct Mode {
    let id: String
    let name: String
    let allowList: [AppIdentifier]
    let appsToOpen: [AppIdentifier]
}

// MARK: - Global Allow List

let globalAllowList: [String] = [
    "net.whatsapp.WhatsApp",
    "ru.keepcoder.Telegram",
    "com.google.Chrome"
]

// MARK: - Modes Configuration

let modes: [Mode] = [
    Mode(
        id: "work",
        name: "Work",
        allowList: [
            AppIdentifier(bundleId: "com.apple.Safari", displayName: "Safari"),
            AppIdentifier(bundleId: "com.apple.Notes", displayName: "Notes"),
            AppIdentifier(bundleId: "com.apple.reminders", displayName: "Reminders")
        ],
        appsToOpen: [
            AppIdentifier(bundleId: "com.apple.Safari", displayName: "Safari")
        ]
    ),
    Mode(
        id: "dev",
        name: "Dev",
        allowList: [
            AppIdentifier(bundleId: "com.todesktop.230313mzl4w4u92", displayName: "Cursor"),
            AppIdentifier(bundleId: "com.microsoft.VSCode", displayName: "VS Code"),
            AppIdentifier(bundleId: "com.apple.Terminal", displayName: "Terminal")
        ],
        appsToOpen: [
            AppIdentifier(bundleId: "com.todesktop.230313mzl4w4u92", displayName: "Cursor")
        ]
    ),
    Mode(
        id: "ai",
        name: "AI",
        allowList: [
            AppIdentifier(bundleId: "com.openai.chat", displayName: "ChatGPT"),
            AppIdentifier(bundleId: "com.anthropic.claudefordesktop", displayName: "Claude")
        ],
        appsToOpen: [
            AppIdentifier(bundleId: "com.anthropic.claudefordesktop", displayName: "Claude")
        ]
    )
]

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var currentMode: Mode?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        print("[DeskModes] Started")
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "DM"
        }

        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        // Modes
        for mode in modes {
            let item = NSMenuItem(title: mode.name, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.id
            if mode.id == currentMode?.id {
                item.state = .on
            }
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Reapply current mode (only if a mode is active)
        if let current = currentMode {
            let reapplyItem = NSMenuItem(
                title: "Reapply \(current.name) Mode",
                action: #selector(reapplyCurrentMode),
                keyEquivalent: ""
            )
            reapplyItem.target = self
            menu.addItem(reapplyItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Quit
        let quit = NSMenuItem(title: "Quit DeskModes", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc func modeSelected(_ sender: NSMenuItem) {
        guard let modeId = sender.representedObject as? String,
              let mode = modes.first(where: { $0.id == modeId }) else {
            return
        }

        let isReapply = mode.id == currentMode?.id
        if isReapply {
            print("[DeskModes] Reapplying mode: \(mode.name)")
        } else {
            print("[DeskModes] Switching to mode: \(mode.name)")
        }
        switchToMode(mode, isReapply: isReapply)
    }

    @objc func reapplyCurrentMode() {
        guard let mode = currentMode else { return }
        print("[DeskModes] Reapplying mode: \(mode.name)")
        switchToMode(mode, isReapply: true)
    }

    func switchToMode(_ mode: Mode, isReapply: Bool = false) {
        let action = isReapply ? "reapply" : "switch"
        print("[DeskModes] === Mode \(action) started: \(mode.name) ===")

        // Get running apps
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular &&
            $0.bundleIdentifier != Bundle.main.bundleIdentifier
        }

        var closed: [String] = []
        var skipped: [String] = []

        // Close apps not in allow lists
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }
            let name = app.localizedName ?? bundleId

            // Check global allow list
            if globalAllowList.contains(bundleId) {
                print("[DeskModes] Keeping (global): \(name)")
                continue
            }

            // Check mode allow list
            if mode.allowList.contains(where: { $0.bundleId == bundleId }) {
                print("[DeskModes] Keeping (mode): \(name)")
                continue
            }

            // Close app
            if app.terminate() {
                print("[DeskModes] Closed: \(name)")
                closed.append(name)
            } else {
                print("[DeskModes] Skipped: \(name) (refused to quit)")
                skipped.append(name)
            }
        }

        // Open required apps
        var opened: [String] = []
        for appToOpen in mode.appsToOpen {
            let isRunning = NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == appToOpen.bundleId
            }

            if !isRunning {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appToOpen.bundleId) {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = false
                    NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
                    print("[DeskModes] Opened: \(appToOpen.displayName)")
                    opened.append(appToOpen.displayName)
                }
            }
        }

        // Summary
        print("[DeskModes] --- Summary ---")
        if isReapply {
            print("[DeskModes] \(mode.name) mode reapplied • \(opened.count) apps reopened • \(closed.count) closed")
        } else {
            print("[DeskModes] \(mode.name) mode activated • \(opened.count) apps opened • \(closed.count) closed")
        }
        print("[DeskModes] Closed: \(closed.isEmpty ? "none" : closed.joined(separator: ", "))")
        print("[DeskModes] Skipped: \(skipped.isEmpty ? "none" : skipped.joined(separator: ", "))")
        print("[DeskModes] Opened: \(opened.isEmpty ? "none" : opened.joined(separator: ", "))")
        print("[DeskModes] === Mode \(isReapply ? "reapply" : "switch") completed ===")

        currentMode = mode
        rebuildMenu()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
