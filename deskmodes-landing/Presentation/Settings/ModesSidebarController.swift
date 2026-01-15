import Cocoa

/// Sidebar controller showing list of modes with Global at top.
final class ModesSidebarController: NSViewController {

    // MARK: - Callbacks

    var onModeSelected: ((ModeConfig?, Bool) -> Void)?
    var onModeAdded: (() -> Void)?

    // MARK: - Properties

    private let headerView = NSView()
    private let modesLabel = NSTextField(labelWithString: "Modes")
    private let headerAddButton = NSButton()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let buttonBar = NSView()
    private let addButton = NSButton()
    private let removeButton = NSButton()

    /// Flag to prevent selection callbacks when restoring selection internally
    private var isRestoringSelection = false

    /// Local key monitor for delete key
    private var keyMonitor: Any?

    private var modes: [ModeConfig] { ConfigStore.shared.config.modes }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupTableView()
        setupButtonBar()
        setupConstraints()
        setupDeleteKeyMonitor()
    }

    deinit {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupDeleteKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Check if delete/backspace key (keyCode 51) is pressed
            if event.keyCode == 51 {
                // Check if our table view is in the responder chain
                if let firstResponder = self.view.window?.firstResponder,
                   firstResponder === self.tableView || self.tableView.isDescendant(of: firstResponder as? NSView ?? NSView()) {
                    let row = self.tableView.selectedRow
                    // Only delete if a mode is selected (not Global or separator)
                    if row > 1 {
                        let modeIndex = row - 2
                        if modeIndex >= 0 && modeIndex < self.modes.count {
                            let mode = self.modes[modeIndex]
                            self.deleteMode(mode, at: row)
                            return nil // Consume the event
                        }
                    }
                }
            }
            return event
        }
    }

    // MARK: - Public API

    func selectMode(at index: Int, isGlobal: Bool) {
        let row = isGlobal ? 0 : index + 2 // +2 for Global row and separator
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification))
    }

    /// Refresh the sidebar to reflect name/icon changes without changing selection
    func refreshModeList() {
        let selectedRow = tableView.selectedRow
        isRestoringSelection = true
        tableView.reloadData()
        if selectedRow >= 0 && selectedRow < tableView.numberOfRows {
            tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
        }
        isRestoringSelection = false
    }

    private func debugLog(_ message: String) {
        let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/deskmodes_debug.log")
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }

    /// Reload the sidebar and select the first mode (or current selection if valid)
    func reloadAndSelectFirstMode() {
        debugLog("reloadAndSelectFirstMode: Starting, modes.count=\(modes.count)")
        for (i, mode) in modes.enumerated() {
            debugLog("  Mode[\(i)]: \(mode.name) with \(mode.apps.count) apps")
        }

        // Save current selection BEFORE reload
        let currentRow = tableView.selectedRow

        // Block callbacks during reload to prevent Global being selected
        isRestoringSelection = true
        tableView.reloadData()

        // Calculate target row
        let targetRow: Int
        if currentRow >= 2 && currentRow < tableView.numberOfRows {
            // Keep current mode selection
            targetRow = currentRow
        } else if !modes.isEmpty {
            // Select first mode (row 2, after Global and separator)
            targetRow = 2
        } else {
            // No modes, select Global
            targetRow = 0
        }

        debugLog("reloadAndSelectFirstMode: currentRow=\(currentRow), targetRow=\(targetRow)")

        // Select the target row (still blocking callbacks)
        tableView.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
        isRestoringSelection = false

        // Directly notify with the correct data (don't rely on tableView.selectedRow timing)
        notifySelectionForRow(targetRow)
    }

    /// Helper to notify selection callback for a specific row
    private func notifySelectionForRow(_ row: Int) {
        removeButton.isEnabled = row > 1

        debugLog("notifySelectionForRow: row=\(row), modes.count=\(modes.count)")

        if isGlobalRow(row) {
            debugLog("notifySelectionForRow: row=\(row) -> GLOBAL")
            onModeSelected?(nil, true)
        } else if !isSeparatorRow(row) {
            let modeIndex = row - 2
            debugLog("notifySelectionForRow: modeIndex=\(modeIndex)")
            if modeIndex >= 0 && modeIndex < modes.count {
                let mode = modes[modeIndex]
                debugLog("notifySelectionForRow: row=\(row) -> mode '\(mode.name)' (id: \(mode.id))")
                onModeSelected?(mode, false)
            } else {
                debugLog("notifySelectionForRow: ERROR - modeIndex \(modeIndex) out of bounds!")
            }
        } else {
            debugLog("notifySelectionForRow: row=\(row) is separator, ignoring")
        }
    }

    // MARK: - Setup

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // "Modes" label
        modesLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        modesLabel.textColor = .secondaryLabelColor
        modesLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(modesLabel)

        // + button in header
        headerAddButton.image = NSImage(systemSymbolName: "plus.circle.fill", accessibilityDescription: "Add Mode")
        headerAddButton.bezelStyle = .inline
        headerAddButton.isBordered = false
        headerAddButton.target = self
        headerAddButton.action = #selector(addModeClicked)
        headerAddButton.translatesAutoresizingMaskIntoConstraints = false
        headerAddButton.contentTintColor = .controlAccentColor
        headerView.addSubview(headerAddButton)

        NSLayoutConstraint.activate([
            modesLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            modesLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            headerAddButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            headerAddButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerAddButton.widthAnchor.constraint(equalToConstant: 20),
            headerAddButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 32
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .sourceList
        tableView.allowsEmptySelection = false

        // Enable right-click menu
        tableView.menu = createContextMenu()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ModeColumn"))
        column.width = 160
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
    }

    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        let deleteItem = NSMenuItem(title: "Delete Mode", action: #selector(deleteFromContextMenu), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        return menu
    }

    @objc private func deleteFromContextMenu() {
        let clickedRow = tableView.clickedRow
        guard clickedRow > 1 else { return } // Can't delete Global or separator

        let modeIndex = clickedRow - 2
        guard modeIndex >= 0 && modeIndex < modes.count else { return }

        let mode = modes[modeIndex]
        deleteMode(mode, at: clickedRow)
    }

    private func deleteMode(_ mode: ModeConfig, at row: Int) {
        // Confirm if mode has apps
        if !mode.apps.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Delete \"\(mode.name)\"?"
            alert.informativeText = "This mode has apps configured. This action cannot be undone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
        }

        let deletedModeIndex = row - 2  // Index in modes array before deletion
        ConfigStore.shared.deleteMode(id: mode.id)

        // Block ALL automatic delegate callbacks during this entire operation
        isRestoringSelection = true
        tableView.reloadData()

        // Determine what to select after deletion
        let modesRemaining = modes.count

        let newRow: Int
        if modesRemaining > 0 {
            // Select previous mode, or first mode if we deleted the first one
            let newModeIndex = max(0, deletedModeIndex - 1)
            newRow = newModeIndex + 2  // +2 for Global and separator
        } else {
            // No modes left, select Global
            newRow = 0
        }

        tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
        isRestoringSelection = false

        // Now notify with the correct row
        notifySelectionForRow(newRow)
    }

    private func setupButtonBar() {
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.wantsLayer = true

        // Add button
        addButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add Mode")
        addButton.bezelStyle = .smallSquare
        addButton.isBordered = false
        addButton.target = self
        addButton.action = #selector(addModeClicked)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        // Remove button
        removeButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove Mode")
        removeButton.bezelStyle = .smallSquare
        removeButton.isBordered = false
        removeButton.target = self
        removeButton.action = #selector(removeModeClicked)
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        buttonBar.addSubview(addButton)
        buttonBar.addSubview(removeButton)
        view.addSubview(buttonBar)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header at top
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 24),

            // Scroll view below header
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonBar.topAnchor),

            // Button bar at bottom (keeping it but less prominent)
            buttonBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonBar.heightAnchor.constraint(equalToConstant: 28),

            addButton.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor, constant: 4),
            addButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24),

            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 2),
            removeButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Actions

    @objc private func addModeClicked() {
        // Rotate through custom icons for new modes
        let customIcons = ["custom_mode_1", "custom_mode_2", "custom_mode_3"]
        let existingModes = ConfigStore.shared.config.modes
        let iconIndex = existingModes.count % customIcons.count

        let newMode = ModeConfig(
            name: "New Mode",
            icon: customIcons[iconIndex]
        )
        ConfigStore.shared.addMode(newMode)
        tableView.reloadData()

        // Ensure UI updates complete before selecting the new mode
        DispatchQueue.main.async { [weak self] in
            self?.onModeAdded?()
        }
    }

    @objc private func removeModeClicked() {
        let row = tableView.selectedRow
        guard row > 1 else { return } // Can't delete Global or separator

        let modeIndex = row - 2
        guard modeIndex >= 0 && modeIndex < modes.count else { return }

        let mode = modes[modeIndex]
        deleteMode(mode, at: row)
    }

    @objc private func configDidChange() {
        // Preserve current selection
        let selectedRow = tableView.selectedRow
        debugLog("configDidChange: selectedRow=\(selectedRow)")

        // Block ALL callbacks during this entire operation
        isRestoringSelection = true

        tableView.reloadData()

        // Restore selection if valid
        if selectedRow >= 0 && selectedRow < tableView.numberOfRows {
            tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
        }

        // Keep blocking until next run loop to catch any delayed events
        DispatchQueue.main.async { [weak self] in
            self?.isRestoringSelection = false
            self?.debugLog("configDidChange: isRestoringSelection reset to false (async)")
        }
    }

    // MARK: - Helper

    private func isSeparatorRow(_ row: Int) -> Bool {
        return row == 1
    }

    private func isGlobalRow(_ row: Int) -> Bool {
        return row == 0
    }
}

// MARK: - NSTableViewDataSource

extension ModesSidebarController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return modes.count + 2 // Global + separator + modes
    }
}

// MARK: - NSTableViewDelegate

extension ModesSidebarController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if isSeparatorRow(row) {
            let separator = NSBox()
            separator.boxType = .separator
            return separator
        }

        let cellId = NSUserInterfaceItemIdentifier("ModeCell")
        var cell = tableView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellId

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(imageView)
            cell?.imageView = imageView

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            cell?.addSubview(textField)
            cell?.textField = textField

            // Count label for app count (subtle, gray)
            let countLabel = NSTextField(labelWithString: "")
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = NSFont.systemFont(ofSize: 11)
            countLabel.textColor = .tertiaryLabelColor
            countLabel.identifier = NSUserInterfaceItemIdentifier("CountLabel")
            cell?.addSubview(countLabel)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20),

                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),

                countLabel.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 4),
                countLabel.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                countLabel.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])

            // Set compression resistance so count label doesn't get compressed
            countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        // Find count label
        let countLabel = cell?.subviews.first(where: { $0.identifier?.rawValue == "CountLabel" }) as? NSTextField

        if isGlobalRow(row) {
            cell?.textField?.stringValue = "Always Open"
            countLabel?.stringValue = ""
            if let globalIcon = loadModeIcon(named: "global_mode") {
                globalIcon.size = NSSize(width: 20, height: 20)
                cell?.imageView?.image = globalIcon
            } else {
                cell?.imageView?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Always Open")
            }
        } else {
            let modeIndex = row - 2
            if modeIndex >= 0 && modeIndex < modes.count {
                let mode = modes[modeIndex]
                cell?.textField?.stringValue = mode.name

                // Show app count (only mode apps, not Always Open)
                let appCount = mode.apps.count
                countLabel?.stringValue = appCount > 0 ? "(\(appCount))" : ""

                // Try to load mode icon from ModeIcons folder
                if let modeIcon = loadModeIcon(named: mode.icon) {
                    modeIcon.size = NSSize(width: 20, height: 20)
                    cell?.imageView?.image = modeIcon
                } else if let emojiImage = emojiToImage(mode.icon) {
                    // Fallback to emoji for backwards compatibility
                    cell?.imageView?.image = emojiImage
                } else {
                    cell?.imageView?.image = NSImage(systemSymbolName: "folder", accessibilityDescription: mode.name)
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return isSeparatorRow(row) ? 10 : 28
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return !isSeparatorRow(row)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        debugLog("tableViewSelectionDidChange: row=\(row), isRestoringSelection=\(isRestoringSelection)")
        guard row >= 0 else { return }

        removeButton.isEnabled = row > 1 // Can't delete Global

        // Skip callback if we're just restoring selection after config change
        guard !isRestoringSelection else {
            debugLog("tableViewSelectionDidChange: SKIPPED (isRestoringSelection)")
            return
        }

        if isGlobalRow(row) {
            debugLog("tableViewSelectionDidChange: Calling onModeSelected with GLOBAL")
            onModeSelected?(nil, true)
        } else if !isSeparatorRow(row) {
            let modeIndex = row - 2
            if modeIndex >= 0 && modeIndex < modes.count {
                let mode = modes[modeIndex]
                debugLog("tableViewSelectionDidChange: Calling onModeSelected with mode '\(mode.name)' (\(mode.apps.count) apps)")
                onModeSelected?(modes[modeIndex], false)
            }
        }
    }

    // MARK: - Icon Helpers

    private func loadModeIcon(named name: String) -> NSImage? {
        // Try to load from ModeIcons folder
        if let iconPath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "ModeIcons"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        // Fallback: try without directory
        if let iconPath = Bundle.main.path(forResource: name, ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        return nil
    }

    private func emojiToImage(_ emoji: String) -> NSImage? {
        let font = NSFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (emoji as NSString).size(withAttributes: attributes)

        let image = NSImage(size: NSSize(width: 20, height: 20))
        image.lockFocus()

        let rect = NSRect(x: (20 - size.width) / 2, y: (20 - size.height) / 2, width: size.width, height: size.height)
        (emoji as NSString).draw(in: rect, withAttributes: attributes)

        image.unlockFocus()
        return image
    }
}
