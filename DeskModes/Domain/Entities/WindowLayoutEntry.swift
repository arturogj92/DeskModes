import Foundation

/// Represents window frame dimensions and position.
/// Domain layer - uses CGFloat but no AppKit dependencies.
struct WindowFrame: Equatable, Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Defines the desired window layout for a specific app.
/// Domain layer - no dependencies on AppKit or system APIs.
struct WindowLayoutEntry: Equatable {
    /// The app this layout applies to
    let appIdentifier: AppIdentifier

    /// The desired window frame (position and size)
    let frame: WindowFrame

    init(appIdentifier: AppIdentifier, frame: WindowFrame) {
        self.appIdentifier = appIdentifier
        self.frame = frame
    }
}

// MARK: - Factory Methods
extension WindowLayoutEntry {
    /// Creates a layout entry for an app covering the full screen
    /// (placeholder dimensions - actual screen size would be determined at runtime)
    static func fullScreen(for app: AppIdentifier) -> WindowLayoutEntry {
        WindowLayoutEntry(
            appIdentifier: app,
            frame: WindowFrame(x: 0, y: 0, width: 1920, height: 1080)
        )
    }

    /// Creates a layout entry for left half of screen
    static func leftHalf(for app: AppIdentifier) -> WindowLayoutEntry {
        WindowLayoutEntry(
            appIdentifier: app,
            frame: WindowFrame(x: 0, y: 0, width: 960, height: 1080)
        )
    }

    /// Creates a layout entry for right half of screen
    static func rightHalf(for app: AppIdentifier) -> WindowLayoutEntry {
        WindowLayoutEntry(
            appIdentifier: app,
            frame: WindowFrame(x: 960, y: 0, width: 960, height: 1080)
        )
    }
}
