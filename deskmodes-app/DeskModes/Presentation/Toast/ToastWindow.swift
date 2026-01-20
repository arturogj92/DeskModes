import Cocoa

/// A temporary floating HUD window for showing mode switch feedback.
/// Auto-dismisses after the specified duration.
final class ToastWindow: NSPanel {

    // MARK: - Singleton for easy access

    private static var current: ToastWindow?

    // MARK: - Properties

    private let iconView = NSImageView()
    private let messageLabel = NSTextField(labelWithString: "")
    private var dismissTimer: Timer?

    // MARK: - Initialization

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    private func setupWindow() {
        // Window appearance
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false

        // Create rounded background view
        let backgroundView = NSVisualEffectView(frame: contentView!.bounds)
        backgroundView.autoresizingMask = [.width, .height]
        backgroundView.material = .hudWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 12
        backgroundView.layer?.masksToBounds = true
        contentView?.addSubview(backgroundView)
    }

    private func setupContent() {
        guard let contentView = contentView else { return }

        // Icon view (hidden by default)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.isHidden = true
        contentView.addSubview(iconView)

        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = .labelColor
        messageLabel.alignment = .center
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.maximumNumberOfLines = 2
        contentView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            messageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func configureWithIcon(_ icon: NSImage?) {
        if let icon = icon {
            iconView.image = icon
            iconView.isHidden = false
            // Label starts after icon
            messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10).isActive = true
        } else {
            iconView.isHidden = true
            // Label centered
            messageLabel.centerXAnchor.constraint(equalTo: contentView!.centerXAnchor).isActive = true
        }
    }

    // MARK: - Public API

    /// Shows a toast with the mode switch result.
    /// - Parameters:
    ///   - modeName: The name of the activated mode
    ///   - appsOpened: Number of apps that were opened
    ///   - appsClosed: Number of apps that were closed
    ///   - duration: How long to show the toast (default 0.8 seconds)
    static func show(modeName: String, appsOpened: Int, appsClosed: Int, duration: TimeInterval = 0.8) {
        // Build message parts
        var parts: [String] = ["\(modeName) activated"]

        if appsOpened > 0 {
            parts.append("\(appsOpened) app\(appsOpened == 1 ? "" : "s") opened")
        }
        if appsClosed > 0 {
            parts.append("\(appsClosed) app\(appsClosed == 1 ? "" : "s") closed")
        }

        // If no apps changed, say so
        if appsOpened == 0 && appsClosed == 0 {
            parts.append("no changes")
        }

        let message = parts.joined(separator: " \u{2022} ")  // bullet separator
        show(message: message, duration: duration)
    }

    /// Shows a toast with a custom message.
    static func show(message: String, duration: TimeInterval = 0.8) {
        show(message: message, icon: nil, duration: duration)
    }

    /// Shows a toast with a custom message and optional icon.
    static func show(message: String, icon: NSImage?, duration: TimeInterval = 0.8) {
        // Dismiss any existing toast
        current?.dismiss()

        let toast = ToastWindow()
        toast.messageLabel.stringValue = message
        toast.configureWithIcon(icon)

        // Size to fit content
        let size = toast.messageLabel.sizeThatFits(NSSize(width: 500, height: 100))
        let iconSpace: CGFloat = icon != nil ? 44 : 0  // icon + spacing
        let windowWidth = max(size.width + 60 + iconSpace, 200)
        let windowHeight: CGFloat = 60

        // Position at top center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.maxY - windowHeight - 80  // 80px from top
            toast.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        // Show with fade in
        toast.alphaValue = 0
        toast.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            toast.animator().alphaValue = 1
        }

        // Store reference
        current = toast

        // Schedule dismissal
        toast.dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak toast] _ in
            toast?.dismiss()
        }
    }

    /// Shows a toast with mode icon by name.
    static func show(message: String, modeIcon: String, duration: TimeInterval = 0.8) {
        var icon: NSImage?
        if let iconPath = Bundle.main.path(forResource: modeIcon, ofType: "png", inDirectory: "ModeIcons"),
           let loadedIcon = NSImage(contentsOfFile: iconPath) {
            icon = loadedIcon
        }
        show(message: message, icon: icon, duration: duration)
    }

    /// Dismisses the toast with a fade out animation.
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let layer = self.contentView?.layer else {
            orderOut(nil)
            if ToastWindow.current === self {
                ToastWindow.current = nil
            }
            return
        }

        let duration: CFTimeInterval = 0.3
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)

        // Opacity animation
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = layer.opacity
        opacityAnim.toValue = 0.0
        opacityAnim.duration = duration
        opacityAnim.timingFunction = timingFunction
        opacityAnim.fillMode = .forwards
        opacityAnim.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.orderOut(nil)
            if ToastWindow.current === self {
                ToastWindow.current = nil
            }
        }

        layer.add(opacityAnim, forKey: "dismissOpacity")

        CATransaction.commit()
    }
}
