import Cocoa

/// Sidebar controller showing list of modes with Global at top.
final class ModesSidebarController: NSViewController {

    // MARK: - Callbacks

    var onModeSelected: ((ModeConfig?, Bool) -> Void)?
    var onModeAdded: (() -> Void)?

    // MARK: - Properties

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let buttonBar = NSView()
    private let addButton = NSButton()
    private let removeButton = NSButton()

    private var modes: [ModeConfig] { ConfigStore.shared.config.modes }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupButtonBar()
        setupConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: .configDidChange,
            object: nil
        )
    }

    // MARK: - Public API

    func selectMode(at index: Int, isGlobal: Bool) {
        let row = isGlobal ? 0 : index + 2 // +2 for Global row and separator
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification))
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 32
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .sourceList
        tableView.allowsEmptySelection = false

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
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonBar.topAnchor),

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
        let newMode = ModeConfig(
            name: "New Mode",
            icon: "📁"
        )
        ConfigStore.shared.addMode(newMode)
        tableView.reloadData()
        onModeAdded?()
    }

    @objc private func removeModeClicked() {
        let row = tableView.selectedRow
        guard row > 1 else { return } // Can't delete Global or separator

        let modeIndex = row - 2
        guard modeIndex >= 0 && modeIndex < modes.count else { return }

        let mode = modes[modeIndex]

        // Confirm if mode has apps
        if !mode.allowList.isEmpty || !mode.appsToOpen.isEmpty {
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

        ConfigStore.shared.deleteMode(id: mode.id)
        tableView.reloadData()

        // Select previous mode or Global
        let newSelection = max(0, row - 1)
        tableView.selectRowIndexes(IndexSet(integer: newSelection), byExtendingSelection: false)
        tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification))
    }

    @objc private func configDidChange() {
        tableView.reloadData()
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

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20),

                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }

        if isGlobalRow(row) {
            cell?.textField?.stringValue = "Global"
            cell?.imageView?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Global")
        } else {
            let modeIndex = row - 2
            if modeIndex >= 0 && modeIndex < modes.count {
                let mode = modes[modeIndex]
                cell?.textField?.stringValue = mode.name

                // Try to render emoji as image, fallback to folder icon
                if let emojiImage = emojiToImage(mode.icon) {
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
        guard row >= 0 else { return }

        removeButton.isEnabled = row > 1 // Can't delete Global

        if isGlobalRow(row) {
            onModeSelected?(nil, true)
        } else if !isSeparatorRow(row) {
            let modeIndex = row - 2
            if modeIndex >= 0 && modeIndex < modes.count {
                onModeSelected?(modes[modeIndex], false)
            }
        }
    }

    // MARK: - Emoji Helper

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
