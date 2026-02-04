import Cocoa

/// Preferences section for keyboard shortcuts configuration
final class ShortcutsViewController: NSViewController {

    // MARK: - Properties

    // Mode Switcher - all on one line
    private let switcherOpenLabel = NSTextField(labelWithString: "Open with")
    private let switcherKeyPopup = NSPopUpButton()
    private let switcherOrLabel = NSTextField(labelWithString: "or")
    private let switcherShortcutRecorder = ShortcutRecorderButton()
    private let switcherClearButton = NSButton()
    private let switcherHelpLabel = NSTextField(wrappingLabelWithString: "")

    // Reapply section
    private let reapplyShortcutLabel = NSTextField(labelWithString: "Reapply shortcut")
    private let reapplyShortcutRecorder = ShortcutRecorderButton()
    private let reapplyClearButton = NSButton()
    private let reapplyHelpLabel = NSTextField(wrappingLabelWithString: "")

    // Auto-reapply section
    private let autoReapplyCheckbox = NSButton(checkboxWithTitle: "Auto-reapply every", target: nil, action: nil)
    private let autoReapplyIntervalPopup = NSPopUpButton()
    private let autoReapplyHelpLabel = NSTextField(wrappingLabelWithString: "")

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }

    // MARK: - Setup

    private func setupUI() {
        let padding: CGFloat = 20

        // Header
        let headerLabel = NSTextField(labelWithString: "Shortcuts")
        headerLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        // === MODE SWITCHER SECTION ===
        let switcherHeader = NSTextField(labelWithString: "Mode Switcher")
        switcherHeader.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        switcherHeader.textColor = .secondaryLabelColor
        switcherHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherHeader)

        // "Open with [popup] or [shortcut]" - single line
        switcherOpenLabel.font = NSFont.systemFont(ofSize: 13)
        switcherOpenLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherOpenLabel)

        switcherKeyPopup.removeAllItems()
        for key in ModeSwitcherKey.allCases {
            switcherKeyPopup.addItem(withTitle: key.symbol)
            switcherKeyPopup.lastItem?.representedObject = key
        }
        switcherKeyPopup.target = self
        switcherKeyPopup.action = #selector(switcherKeyChanged)
        switcherKeyPopup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherKeyPopup)

        switcherOrLabel.font = NSFont.systemFont(ofSize: 13)
        switcherOrLabel.textColor = .secondaryLabelColor
        switcherOrLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherOrLabel)

        switcherShortcutRecorder.translatesAutoresizingMaskIntoConstraints = false
        switcherShortcutRecorder.onShortcutChanged = { [weak self] shortcut in
            ConfigStore.shared.setModeSwitcherShortcut(shortcut)
            // If custom shortcut is set, disable double-tap (right takes precedence)
            if shortcut != nil {
                ConfigStore.shared.setModeSwitcherKey(.disabled)
                self?.switcherKeyPopup.selectItem(at: self?.switcherKeyPopup.itemArray.firstIndex(where: {
                    ($0.representedObject as? ModeSwitcherKey) == .disabled
                }) ?? 0)
            }
            self?.updateClearButtonVisibility()
        }
        view.addSubview(switcherShortcutRecorder)

        // Clear button for mode switcher shortcut
        switcherClearButton.bezelStyle = .inline
        switcherClearButton.isBordered = false
        switcherClearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear shortcut")
        switcherClearButton.imageScaling = .scaleProportionallyDown
        switcherClearButton.contentTintColor = .tertiaryLabelColor
        switcherClearButton.target = self
        switcherClearButton.action = #selector(clearSwitcherShortcut)
        switcherClearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherClearButton)

        switcherHelpLabel.stringValue = "Press 1-9 while open to quick-switch modes."
        switcherHelpLabel.font = NSFont.systemFont(ofSize: 11)
        switcherHelpLabel.textColor = .tertiaryLabelColor
        switcherHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherHelpLabel)

        // Separator 1
        let separator1 = NSBox()
        separator1.boxType = .separator
        separator1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator1)

        // === REAPPLY SECTION ===
        let reapplyHeader = NSTextField(labelWithString: "Reapply Mode")
        reapplyHeader.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        reapplyHeader.textColor = .secondaryLabelColor
        reapplyHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reapplyHeader)

        // "Reapply shortcut [recorder]" - single line
        reapplyShortcutLabel.font = NSFont.systemFont(ofSize: 13)
        reapplyShortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reapplyShortcutLabel)

        reapplyShortcutRecorder.translatesAutoresizingMaskIntoConstraints = false
        reapplyShortcutRecorder.onShortcutChanged = { [weak self] shortcut in
            ConfigStore.shared.setReapplyShortcut(shortcut)
            self?.updateClearButtonVisibility()
        }
        view.addSubview(reapplyShortcutRecorder)

        // Clear button for reapply shortcut
        reapplyClearButton.bezelStyle = .inline
        reapplyClearButton.isBordered = false
        reapplyClearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear shortcut")
        reapplyClearButton.imageScaling = .scaleProportionallyDown
        reapplyClearButton.contentTintColor = .tertiaryLabelColor
        reapplyClearButton.target = self
        reapplyClearButton.action = #selector(clearReapplyShortcut)
        reapplyClearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reapplyClearButton)

        reapplyHelpLabel.stringValue = "Re-closes unwanted apps and reopens mode apps."
        reapplyHelpLabel.font = NSFont.systemFont(ofSize: 11)
        reapplyHelpLabel.textColor = .tertiaryLabelColor
        reapplyHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reapplyHelpLabel)

        // Auto-reapply: "Auto-reapply every [popup]" - single line
        autoReapplyCheckbox.target = self
        autoReapplyCheckbox.action = #selector(autoReapplyCheckboxChanged)
        autoReapplyCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoReapplyCheckbox)

        autoReapplyIntervalPopup.removeAllItems()
        let intervals = [5, 10, 15, 30, 60]
        for interval in intervals {
            let title = interval == 60 ? "1 hour" : "\(interval) min"
            autoReapplyIntervalPopup.addItem(withTitle: title)
            autoReapplyIntervalPopup.lastItem?.representedObject = interval
        }
        autoReapplyIntervalPopup.target = self
        autoReapplyIntervalPopup.action = #selector(autoReapplyIntervalChanged)
        autoReapplyIntervalPopup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoReapplyIntervalPopup)

        autoReapplyHelpLabel.stringValue = "Keep your workspace clean automatically."
        autoReapplyHelpLabel.font = NSFont.systemFont(ofSize: 11)
        autoReapplyHelpLabel.textColor = .tertiaryLabelColor
        autoReapplyHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoReapplyHelpLabel)

        // === CONSTRAINTS ===
        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Mode Switcher section
            switcherHeader.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            switcherHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Single line: "Open with [popup] or [shortcut]"
            switcherOpenLabel.topAnchor.constraint(equalTo: switcherHeader.bottomAnchor, constant: 12),
            switcherOpenLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            switcherKeyPopup.centerYAnchor.constraint(equalTo: switcherOpenLabel.centerYAnchor),
            switcherKeyPopup.leadingAnchor.constraint(equalTo: switcherOpenLabel.trailingAnchor, constant: 8),

            switcherOrLabel.centerYAnchor.constraint(equalTo: switcherOpenLabel.centerYAnchor),
            switcherOrLabel.leadingAnchor.constraint(equalTo: switcherKeyPopup.trailingAnchor, constant: 8),

            switcherShortcutRecorder.centerYAnchor.constraint(equalTo: switcherOpenLabel.centerYAnchor),
            switcherShortcutRecorder.leadingAnchor.constraint(equalTo: switcherOrLabel.trailingAnchor, constant: 8),
            switcherShortcutRecorder.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            switcherClearButton.centerYAnchor.constraint(equalTo: switcherShortcutRecorder.centerYAnchor),
            switcherClearButton.leadingAnchor.constraint(equalTo: switcherShortcutRecorder.trailingAnchor, constant: 4),
            switcherClearButton.widthAnchor.constraint(equalToConstant: 16),
            switcherClearButton.heightAnchor.constraint(equalToConstant: 16),

            switcherHelpLabel.topAnchor.constraint(equalTo: switcherOpenLabel.bottomAnchor, constant: 6),
            switcherHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            switcherHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Separator
            separator1.topAnchor.constraint(equalTo: switcherHelpLabel.bottomAnchor, constant: 16),
            separator1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            separator1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Reapply section
            reapplyHeader.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 16),
            reapplyHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Single line: "Reapply shortcut [recorder]"
            reapplyShortcutLabel.topAnchor.constraint(equalTo: reapplyHeader.bottomAnchor, constant: 12),
            reapplyShortcutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            reapplyShortcutRecorder.centerYAnchor.constraint(equalTo: reapplyShortcutLabel.centerYAnchor),
            reapplyShortcutRecorder.leadingAnchor.constraint(equalTo: reapplyShortcutLabel.trailingAnchor, constant: 8),
            reapplyShortcutRecorder.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            reapplyClearButton.centerYAnchor.constraint(equalTo: reapplyShortcutRecorder.centerYAnchor),
            reapplyClearButton.leadingAnchor.constraint(equalTo: reapplyShortcutRecorder.trailingAnchor, constant: 4),
            reapplyClearButton.widthAnchor.constraint(equalToConstant: 16),
            reapplyClearButton.heightAnchor.constraint(equalToConstant: 16),

            reapplyHelpLabel.topAnchor.constraint(equalTo: reapplyShortcutLabel.bottomAnchor, constant: 6),
            reapplyHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            reapplyHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Auto-reapply: "Auto-reapply every [popup]"
            autoReapplyCheckbox.topAnchor.constraint(equalTo: reapplyHelpLabel.bottomAnchor, constant: 12),
            autoReapplyCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            autoReapplyIntervalPopup.centerYAnchor.constraint(equalTo: autoReapplyCheckbox.centerYAnchor),
            autoReapplyIntervalPopup.leadingAnchor.constraint(equalTo: autoReapplyCheckbox.trailingAnchor, constant: 4),

            autoReapplyHelpLabel.topAnchor.constraint(equalTo: autoReapplyCheckbox.bottomAnchor, constant: 6),
            autoReapplyHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding + 20),
            autoReapplyHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])

        updateUI()
    }

    private func loadSettings() {
        let config = ConfigStore.shared.config

        // Mode switcher key popup
        for (index, item) in switcherKeyPopup.itemArray.enumerated() {
            if let key = item.representedObject as? ModeSwitcherKey, key == config.modeSwitcherKey {
                switcherKeyPopup.selectItem(at: index)
                break
            }
        }

        // Custom mode switcher shortcut
        switcherShortcutRecorder.setShortcut(config.modeSwitcherShortcut)

        // Reapply shortcut
        reapplyShortcutRecorder.setShortcut(config.reapplyShortcut)

        // Auto-reapply
        autoReapplyCheckbox.state = config.enableAutoReapply ? .on : .off
        for (index, item) in autoReapplyIntervalPopup.itemArray.enumerated() {
            if let interval = item.representedObject as? Int, interval == config.autoReapplyInterval {
                autoReapplyIntervalPopup.selectItem(at: index)
                break
            }
        }

        updateUI()
    }

    private func updateUI() {
        let autoEnabled = autoReapplyCheckbox.state == .on
        autoReapplyIntervalPopup.isEnabled = autoEnabled
        autoReapplyHelpLabel.textColor = autoEnabled ? .tertiaryLabelColor : .quaternaryLabelColor
        updateClearButtonVisibility()
    }

    private func updateClearButtonVisibility() {
        // Show clear button only if shortcut is set
        switcherClearButton.isHidden = switcherShortcutRecorder.getShortcut() == nil
        reapplyClearButton.isHidden = reapplyShortcutRecorder.getShortcut() == nil
    }

    // MARK: - Actions

    @objc private func switcherKeyChanged() {
        guard let selectedKey = switcherKeyPopup.selectedItem?.representedObject as? ModeSwitcherKey else { return }
        ConfigStore.shared.setModeSwitcherKey(selectedKey)
    }

    @objc private func autoReapplyCheckboxChanged() {
        ConfigStore.shared.setEnableAutoReapply(autoReapplyCheckbox.state == .on)
        updateUI()
    }

    @objc private func autoReapplyIntervalChanged() {
        guard let interval = autoReapplyIntervalPopup.selectedItem?.representedObject as? Int else { return }
        ConfigStore.shared.setAutoReapplyInterval(interval)
    }

    @objc private func clearSwitcherShortcut() {
        switcherShortcutRecorder.setShortcut(nil)
        ConfigStore.shared.setModeSwitcherShortcut(nil)
        updateClearButtonVisibility()
    }

    @objc private func clearReapplyShortcut() {
        reapplyShortcutRecorder.setShortcut(nil)
        ConfigStore.shared.setReapplyShortcut(nil)
        updateClearButtonVisibility()
    }
}
