import Cocoa

/// Data for displaying mode switch results in the HUD
struct ModeSwitchHUDData {
    let modeName: String
    let modeIcon: String
    let isReapply: Bool
    let closedApps: [AppDisplayInfo]
    let openedApps: [AppDisplayInfo]
    let skippedApps: [AppDisplayInfo]

    struct AppDisplayInfo {
        let name: String
        let bundleId: String
        let icon: NSImage?
    }

    var totalChanges: Int {
        closedApps.count + openedApps.count + skippedApps.count
    }

    /// Title text: "Dev mode activated" or "Work mode reapplied"
    var title: String {
        let action = isReapply ? "reapplied" : "activated"
        return "\(modeName) mode \(action)"
    }

    /// Label for opened apps: "Opened" or "Reopened"
    var openedLabel: String {
        isReapply ? "Reopened" : "Opened"
    }
}

/// A centered HUD window showing mode switch results with app icons.
/// Auto-dismisses after 2 seconds. Press Esc to close immediately.
final class ModeSwitchHUD: NSPanel {

    // MARK: - Singleton

    private static var current: ModeSwitchHUD?

    // MARK: - Constants

    private static let maxIconsPerRow = 8
    private static let iconSize: CGFloat = 40
    private static let badgeSize: CGFloat = 16
    private static let dismissDuration: TimeInterval = 4.0

    // MARK: - Properties

    private let containerView = NSVisualEffectView()
    private let modeIconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let closedSection = AppIconSection(badgeType: .closed)
    private let openedSection = AppIconSection(badgeType: .opened)
    private let skippedSection = AppIconSection(badgeType: .skipped)
    private var dismissTimer: Timer?
    private var localMonitor: Any?

    // MARK: - Initialization

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
        setupEscapeKeyHandler()
    }

    deinit {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
    }

    private func setupContent() {
        guard let contentView = contentView else { return }

        // Enable layer-backed view for smooth animations
        contentView.wantsLayer = true

        // Background with vibrancy
        containerView.material = .hudWindow
        containerView.state = .active
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 16
        containerView.layer?.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        // Mode icon
        modeIconView.translatesAutoresizingMaskIntoConstraints = false
        modeIconView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(modeIconView)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // App icon sections
        let stackView = NSStackView(views: [closedSection, openedSection, skippedSection])
        stackView.orientation = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            modeIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            modeIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            modeIconView.widthAnchor.constraint(equalToConstant: 40),
            modeIconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: modeIconView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    private func setupEscapeKeyHandler() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.dismiss()
                return nil
            }
            return event
        }
    }

    // MARK: - Public API

    /// Shows the HUD with mode switch results
    static func show(data: ModeSwitchHUDData) {
        print("📺 ModeSwitchHUD.show() called")
        print("   totalChanges: \(data.totalChanges)")

        // Always create fresh HUD for simplicity
        let hud = ModeSwitchHUD()

        // Dismiss existing HUD immediately if any
        if let existing = current {
            existing.dismissTimer?.invalidate()
            existing.orderOut(nil)
            current = nil
        }

        hud.configure(with: data)

        // Size window based on content
        hud.sizeToFit(data: data)

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let hudFrame = hud.frame
            let x = screenFrame.midX - hudFrame.width / 2
            let y = screenFrame.midY - hudFrame.height / 2
            hud.setFrameOrigin(NSPoint(x: x, y: y))
            print("   position: (\(x), \(y)), size: \(hudFrame.size)")
        }

        // Show with smooth spring animation
        hud.alphaValue = 0
        hud.orderFrontRegardless()

        guard let layer = hud.contentView?.layer else {
            hud.alphaValue = 1
            current = hud
            return
        }

        // Initial state
        layer.opacity = 0
        layer.transform = CATransform3DMakeScale(0.85, 0.85, 1)

        // Spring-like entrance animation
        let duration: CFTimeInterval = 0.4
        let springTiming = CAMediaTimingFunction(controlPoints: 0.2, 1.0, 0.3, 1.0)

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.0
        opacityAnim.toValue = 1.0
        opacityAnim.duration = duration
        opacityAnim.timingFunction = springTiming
        opacityAnim.fillMode = .forwards
        opacityAnim.isRemovedOnCompletion = false

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.85
        scaleAnim.toValue = 1.0
        scaleAnim.duration = duration
        scaleAnim.timingFunction = springTiming
        scaleAnim.fillMode = .forwards
        scaleAnim.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // Clean up animation state
            layer.opacity = 1
            layer.transform = CATransform3DIdentity
            layer.removeAllAnimations()
        }

        layer.add(opacityAnim, forKey: "showOpacity")
        layer.add(scaleAnim, forKey: "showScale")

        CATransaction.commit()

        hud.alphaValue = 1
        current = hud
        print("   HUD shown!")

        // Auto-dismiss timer
        hud.dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissDuration, repeats: false) { [weak hud] _ in
            hud?.dismiss()
        }
    }

    /// Shows a simple message (fallback for no changes)
    static func showSimple(modeName: String, message: String) {
        // Use the simple ToastWindow for no-change scenarios
        ToastWindow.show(message: "\(modeName) \u{2022} \(message)")
    }

    // MARK: - Configuration

    private func configure(with data: ModeSwitchHUDData) {
        // Load mode icon
        if let iconPath = Bundle.main.path(forResource: data.modeIcon, ofType: "png", inDirectory: "ModeIcons"),
           let icon = NSImage(contentsOfFile: iconPath) {
            modeIconView.image = icon
        }

        // Use "activated" or "reapplied" based on context
        titleLabel.stringValue = data.title

        // Build subtitle with appropriate labels
        var parts: [String] = []
        if !data.openedApps.isEmpty {
            parts.append("\(data.openedApps.count) \(data.isReapply ? "reopened" : "opened")")
        }
        if !data.closedApps.isEmpty {
            parts.append("\(data.closedApps.count) closed")
        }
        if !data.skippedApps.isEmpty {
            parts.append("\(data.skippedApps.count) skipped")
        }
        subtitleLabel.stringValue = parts.joined(separator: " · ")

        // Configure sections with appropriate labels
        closedSection.configure(apps: data.closedApps, label: "Closed")
        openedSection.configure(apps: data.openedApps, label: data.openedLabel)
        skippedSection.configure(apps: data.skippedApps, label: "Skipped")

        // Hide empty sections
        closedSection.isHidden = data.closedApps.isEmpty
        openedSection.isHidden = data.openedApps.isEmpty
        skippedSection.isHidden = data.skippedApps.isEmpty
    }

    private func sizeToFit(data: ModeSwitchHUDData) {
        var height: CGFloat = 130 // Mode icon + Title + subtitle + padding
        var width: CGFloat = 300

        let sections = [
            (data.closedApps, closedSection),
            (data.openedApps, openedSection),
            (data.skippedApps, skippedSection)
        ]

        for (apps, _) in sections where !apps.isEmpty {
            height += 60 // Section height (larger icons)
            let iconsWidth = CGFloat(min(apps.count, Self.maxIconsPerRow)) * 50 + 60
            width = max(width, iconsWidth)
        }

        setContentSize(NSSize(width: width, height: height))
    }

    // MARK: - Dismiss

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let layer = self.contentView?.layer else {
            orderOut(nil)
            if ModeSwitchHUD.current === self {
                ModeSwitchHUD.current = nil
            }
            return
        }

        let duration: CFTimeInterval = 0.4
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)

        // Opacity animation
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = layer.opacity
        opacityAnim.toValue = 0.0
        opacityAnim.duration = duration
        opacityAnim.timingFunction = timingFunction
        opacityAnim.fillMode = .forwards
        opacityAnim.isRemovedOnCompletion = false

        // Scale animation
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 0.96
        scaleAnim.duration = duration
        scaleAnim.timingFunction = timingFunction
        scaleAnim.fillMode = .forwards
        scaleAnim.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.orderOut(nil)
            if ModeSwitchHUD.current === self {
                ModeSwitchHUD.current = nil
            }
        }

        layer.add(opacityAnim, forKey: "dismissOpacity")
        layer.add(scaleAnim, forKey: "dismissScale")

        CATransaction.commit()
    }
}

// MARK: - App Icon Section

/// A horizontal row of app icons with a badge overlay
private class AppIconSection: NSView {

    enum BadgeType {
        case closed   // Gray X
        case opened   // Green checkmark
        case skipped  // Yellow !

        var color: NSColor {
            switch self {
            case .closed: return .systemGray
            case .opened: return .systemGreen
            case .skipped: return .systemYellow
            }
        }

        var symbol: String {
            switch self {
            case .closed: return "xmark"
            case .opened: return "checkmark"
            case .skipped: return "exclamationmark"
            }
        }
    }

    private let badgeType: BadgeType
    private let stackView = NSStackView()
    private let overflowLabel = NSTextField(labelWithString: "")

    init(badgeType: BadgeType) {
        self.badgeType = badgeType
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        overflowLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        overflowLabel.textColor = .secondaryLabelColor
        overflowLabel.translatesAutoresizingMaskIntoConstraints = false
        overflowLabel.isHidden = true
        addSubview(overflowLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),

            overflowLabel.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 4),
            overflowLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            overflowLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    func configure(apps: [ModeSwitchHUDData.AppDisplayInfo], label: String) {
        // Clear existing icons
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let maxIcons = 8
        let displayApps = Array(apps.prefix(maxIcons))

        for app in displayApps {
            let iconView = createIconView(for: app)
            stackView.addArrangedSubview(iconView)
        }

        // Show overflow if needed
        let overflow = apps.count - maxIcons
        if overflow > 0 {
            overflowLabel.stringValue = "+\(overflow)"
            overflowLabel.isHidden = false
        } else {
            overflowLabel.isHidden = true
        }
    }

    private func createIconView(for app: ModeSwitchHUDData.AppDisplayInfo) -> NSView {
        let iconSize: CGFloat = 40
        let containerWidth: CGFloat = 46
        let containerHeight: CGFloat = 48

        let container = NSView(frame: NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight))

        // App icon
        let imageView = NSImageView(frame: NSRect(x: 3, y: 6, width: iconSize, height: iconSize))
        let icon = app.icon ?? NSWorkspace.shared.icon(forFile: "/Applications/\(app.name).app")
        icon.size = NSSize(width: iconSize, height: iconSize)
        imageView.image = icon
        container.addSubview(imageView)

        // Badge overlay
        let badgeSize: CGFloat = 16
        let badge = NSView(frame: NSRect(x: containerWidth - badgeSize - 2, y: 4, width: badgeSize, height: badgeSize))
        badge.wantsLayer = true
        badge.layer?.cornerRadius = badgeSize / 2
        badge.layer?.backgroundColor = badgeType.color.cgColor

        // Badge symbol
        if let symbolImage = NSImage(systemSymbolName: badgeType.symbol, accessibilityDescription: nil) {
            let symbolView = NSImageView(frame: badge.bounds.insetBy(dx: 2, dy: 2))
            symbolView.image = symbolImage
            symbolView.contentTintColor = .white
            badge.addSubview(symbolView)
        }

        container.addSubview(badge)

        // Tooltip
        container.toolTip = app.name

        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: containerWidth),
            container.heightAnchor.constraint(equalToConstant: containerHeight)
        ])

        return container
    }
}
