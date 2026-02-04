import Cocoa
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    var menuBarController: MenuBarController!

    // Sparkle updater controller
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

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
