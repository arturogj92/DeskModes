import Cocoa

// IMPORTANT: Keep appDelegate at module level to prevent deallocation
// (NSApplication.delegate is a weak reference)
private let appDelegate = AppDelegate()

let app = NSApplication.shared
app.delegate = appDelegate
app.run()
