import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    var menuBarController: MenuBarController!

    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set as accessory app (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize the menu bar controller
        menuBarController = MenuBarController()

        Logger.shared.info("DeskModes started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("DeskModes terminating")
    }
}
