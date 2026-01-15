import Cocoa

/// Quick mode selector overlay triggered by double-tap Option
/// Shows modes in a grid that can be selected by pressing 1, 2, 3, etc.
final class ModeSelectorOverlay: NSPanel {

    // MARK: - Singleton

    private static var current: ModeSelectorOverlay?

    // MARK: - Properties

    private let containerView = NSVisualEffectView()
    private var modeViews: [ModeGridItem] = []
    private let hintLabel = NSTextField(labelWithString: "")
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var clickMonitor: Any?

    var onModeSelected: ((String) -> Void)?

    // MARK: - Initialization

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    deinit {
        removeMonitors()
    }

    // MARK: - Setup

    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
    }

    override var canBecomeKey: Bool { true }

    private func setupContent() {
        guard let contentView = contentView else { return }

        contentView.wantsLayer = true

        // Background with vibrancy - darker material
        containerView.material = .hudWindow
        containerView.blendingMode = .behindWindow
        containerView.state = .active
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 16
        containerView.layer?.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        // Hint label at bottom
        hintLabel.stringValue = "Press number or click to switch"
        hintLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        hintLabel.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.6)
        hintLabel.alignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            hintLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            hintLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }

    // MARK: - Public API

    static func show(modes: [ModeConfig], currentModeId: String?, onSelect: @escaping (String) -> Void) {
        current?.dismiss()

        let overlay = ModeSelectorOverlay()
        overlay.configure(modes: modes, currentModeId: currentModeId)
        overlay.onModeSelected = onSelect

        // Calculate grid size
        let columns = min(modes.count, 3)
        let rows = (modes.count + 2) / 3
        let itemWidth: CGFloat = 100
        let itemHeight: CGFloat = 110
        let spacing: CGFloat = 10
        let paddingH: CGFloat = 16
        let paddingV: CGFloat = 16
        let hintHeight: CGFloat = 28

        let width = CGFloat(columns) * itemWidth + CGFloat(columns - 1) * spacing + paddingH * 2
        let height = CGFloat(rows) * itemHeight + CGFloat(rows - 1) * spacing + paddingV * 2 + hintHeight

        overlay.setContentSize(NSSize(width: width, height: height))
        overlay.contentView?.layoutSubtreeIfNeeded()
        overlay.layoutModeItems()

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.midY - height / 2
            overlay.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Prepare for animation
        overlay.alphaValue = 0
        if let layer = overlay.contentView?.layer {
            layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
        }

        overlay.orderFrontRegardless()
        overlay.makeKey()

        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1, 0.3, 1)
            overlay.animator().alphaValue = 1
            if let layer = overlay.contentView?.layer {
                layer.transform = CATransform3DIdentity
            }
        }

        overlay.setupMonitors()
        current = overlay
    }

    // MARK: - Configuration

    private func configure(modes: [ModeConfig], currentModeId: String?) {
        modeViews.forEach { $0.removeFromSuperview() }
        modeViews.removeAll()

        for (index, mode) in modes.enumerated() {
            let item = ModeGridItem(
                number: index + 1,
                name: mode.name,
                iconName: mode.icon,
                isCurrentMode: mode.id == currentModeId
            )
            item.modeId = mode.id
            item.target = self
            item.action = #selector(modeItemClicked(_:))

            containerView.addSubview(item)
            modeViews.append(item)
        }
    }

    func layoutModeItems() {
        guard !modeViews.isEmpty else { return }

        let columns = min(modeViews.count, 3)
        let rows = (modeViews.count + 2) / 3
        let itemWidth: CGFloat = 100
        let itemHeight: CGFloat = 110
        let spacing: CGFloat = 10
        let paddingH: CGFloat = 16
        let hintHeight: CGFloat = 28

        let containerWidth = containerView.bounds.width

        let gridWidth = CGFloat(columns) * itemWidth + CGFloat(columns - 1) * spacing
        let startX = (containerWidth - gridWidth) / 2
        let startY = hintHeight + 12

        for (index, item) in modeViews.enumerated() {
            let col = index % 3
            let row = index / 3
            let invertedRow = (rows - 1) - row
            let x = startX + CGFloat(col) * (itemWidth + spacing)
            let y = startY + CGFloat(invertedRow) * (itemHeight + spacing)
            item.frame = NSRect(x: x, y: y, width: itemWidth, height: itemHeight)
        }
    }

    @objc private func modeItemClicked(_ sender: ModeGridItem) {
        if let modeId = sender.modeId {
            selectMode(modeId)
        }
    }

    private func selectMode(_ modeId: String) {
        onModeSelected?(modeId)
        dismiss()
    }

    // MARK: - Monitors

    private func setupMonitors() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyDown(event) == true {
                return nil
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            let screenLocation = NSEvent.mouseLocation
            if !self.frame.contains(screenLocation) {
                self.dismiss()
            }
        }
    }

    @discardableResult
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            dismiss()
            return true
        }

        let numberKeyCodes: [UInt16: Int] = [
            18: 1, 19: 2, 20: 3, 21: 4, 22: 5, 23: 6, 24: 7, 25: 8, 26: 9
        ]

        if let number = numberKeyCodes[event.keyCode] {
            let index = number - 1
            if index < modeViews.count {
                if let modeId = modeViews[index].modeId {
                    let item = modeViews[index]
                    // Flash effect
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.08)
                    item.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.3).cgColor
                    CATransaction.commit()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        self.selectMode(modeId)
                    }
                    return true
                }
            }
        }

        return false
    }

    private func removeMonitors() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        removeMonitors()

        guard let layer = self.contentView?.layer else {
            orderOut(nil)
            if ModeSelectorOverlay.current === self {
                ModeSelectorOverlay.current = nil
            }
            return
        }

        let duration: CFTimeInterval = 0.15
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 1, 1)

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = layer.opacity
        opacityAnim.toValue = 0.0
        opacityAnim.duration = duration
        opacityAnim.timingFunction = timingFunction
        opacityAnim.fillMode = .forwards
        opacityAnim.isRemovedOnCompletion = false

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 0.95
        scaleAnim.duration = duration
        scaleAnim.timingFunction = timingFunction
        scaleAnim.fillMode = .forwards
        scaleAnim.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.orderOut(nil)
            if ModeSelectorOverlay.current === self {
                ModeSelectorOverlay.current = nil
            }
        }

        layer.add(opacityAnim, forKey: "dismissOpacity")
        layer.add(scaleAnim, forKey: "dismissScale")

        CATransaction.commit()
    }
}

// MARK: - Mode Grid Item

private class ModeGridItem: NSButton {

    var modeId: String?
    private var isCurrentMode: Bool = false

    init(number: Int, name: String, iconName: String, isCurrentMode: Bool) {
        self.isCurrentMode = isCurrentMode
        super.init(frame: .zero)

        title = ""
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 12

        // Background styling
        if isCurrentMode {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            layer?.borderWidth = 1.5
            layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
        } else {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.03).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        }

        // Icon container with subtle background
        let iconContainer = NSView()
        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = 12
        iconContainer.layer?.backgroundColor = NSColor.clear.cgColor
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconContainer)

        // Icon
        let iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        if let iconPath = Bundle.main.path(forResource: iconName, ofType: "png", inDirectory: "ModeIcons"),
           let icon = NSImage(contentsOfFile: iconPath) {
            iconView.image = icon
        } else if let iconPath = Bundle.main.path(forResource: iconName, ofType: "png"),
                  let icon = NSImage(contentsOfFile: iconPath) {
            iconView.image = icon
        }

        iconContainer.addSubview(iconView)

        // Name label
        let nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: isCurrentMode ? .semibold : .medium)
        nameLabel.textColor = isCurrentMode ? .controlAccentColor : .labelColor
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Number label (subtle, below name)
        let numberLabel = NSTextField(labelWithString: "\(number)")
        numberLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        numberLabel.textColor = NSColor.tertiaryLabelColor
        numberLabel.alignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)

        NSLayoutConstraint.activate([
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 46),
            iconView.heightAnchor.constraint(equalToConstant: 46),

            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),

            numberLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            numberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        if isCurrentMode {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        } else {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
            layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        }
        CATransaction.commit()
    }

    override func mouseExited(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        if isCurrentMode {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
        } else {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.03).cgColor
            layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        }
        CATransaction.commit()
    }
}
