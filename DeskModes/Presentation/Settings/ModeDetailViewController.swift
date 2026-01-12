import Cocoa

/// Detail view controller for editing a mode or global allow list.
final class ModeDetailViewController: NSViewController {

    // MARK: - Properties

    private var currentMode: ModeConfig?
    private var isShowingGlobal = false

    // MARK: - UI Elements

    // Header
    private let iconButton = NSButton()
    private let nameField = NSTextField()
    private let shortcutLabel = NSTextField(labelWithString: "Shortcut:")
    private let shortcutButton = NSButton()

    // Apps section
    private let appsLabel = NSTextField(labelWithString: "Allowed Apps:")
    private let appsHelpLabel = NSTextField(labelWithString: "These apps stay open in this mode (others get closed)")
    private let appsScrollView = NSScrollView()
    private let appsTableView = NSTableView()
    private let addAppButton = NSButton()

    // Apps to open section
    private let openAppsLabel = NSTextField(labelWithString: "Auto-launch:")
    private let openAppsHelpLabel = NSTextField(labelWithString: "These apps open automatically when switching to this mode")
    private let openAppsScrollView = NSScrollView()
    private let openAppsTableView = NSTableView()
    private let addOpenAppButton = NSButton()

    // Data
    private var installedApps: [AppEntry] = []
    private var allowListApps: [AppEntry] = []
    private var appsToOpen: [AppEntry] = []

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 480))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadInstalledApps()
        setupUI()
        setupConstraints()
    }

    // MARK: - Public API

    func showMode(_ mode: ModeConfig) {
        isShowingGlobal = false
        currentMode = mode

        iconButton.title = mode.icon
        iconButton.isHidden = false
        nameField.stringValue = mode.name
        nameField.isEditable = true
        shortcutLabel.isHidden = false
        shortcutButton.isHidden = false
        shortcutButton.title = mode.shortcut ?? "None"

        openAppsLabel.isHidden = false
        openAppsHelpLabel.isHidden = false
        openAppsScrollView.isHidden = false
        addOpenAppButton.isHidden = false

        allowListApps = mode.allowList
        appsToOpen = mode.appsToOpen

        appsLabel.stringValue = "Allowed Apps:"
        appsHelpLabel.stringValue = "These apps stay open in this mode (others get closed)"
        appsHelpLabel.isHidden = false
        appsTableView.reloadData()
        openAppsTableView.reloadData()
    }

    func showGlobalAllowList() {
        isShowingGlobal = true
        currentMode = nil

        iconButton.title = "🌐"
        iconButton.isHidden = true
        nameField.stringValue = "Global Allow List"
        nameField.isEditable = false
        shortcutLabel.isHidden = true
        shortcutButton.isHidden = true

        openAppsLabel.isHidden = true
        openAppsHelpLabel.isHidden = true
        openAppsScrollView.isHidden = true
        addOpenAppButton.isHidden = true

        allowListApps = ConfigStore.shared.config.globalAllowList
        appsToOpen = []

        appsLabel.stringValue = "Protected Apps:"
        appsHelpLabel.stringValue = "These apps NEVER close, regardless of which mode is active"
        appsHelpLabel.isHidden = false
        appsTableView.reloadData()
    }

    // MARK: - Setup

    private func setupUI() {
        // Icon button
        iconButton.title = "📁"
        iconButton.bezelStyle = .regularSquare
        iconButton.font = NSFont.systemFont(ofSize: 24)
        iconButton.target = self
        iconButton.action = #selector(iconClicked)
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconButton)

        // Name field
        nameField.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        nameField.isBordered = true
        nameField.bezelStyle = .roundedBezel
        nameField.delegate = self
        nameField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameField)

        // Shortcut
        shortcutLabel.font = NSFont.systemFont(ofSize: 13)
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shortcutLabel)

        shortcutButton.title = "None"
        shortcutButton.bezelStyle = .rounded
        shortcutButton.target = self
        shortcutButton.action = #selector(shortcutClicked)
        shortcutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shortcutButton)

        // Apps label
        appsLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        appsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsLabel)

        // Apps help label
        appsHelpLabel.font = NSFont.systemFont(ofSize: 11)
        appsHelpLabel.textColor = .secondaryLabelColor
        appsHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsHelpLabel)

        // Apps table
        setupAppsTableView()

        // Add app button
        addAppButton.title = "+ Add App..."
        addAppButton.bezelStyle = .rounded
        addAppButton.target = self
        addAppButton.action = #selector(addAppClicked)
        addAppButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addAppButton)

        // Apps to open section
        openAppsLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        openAppsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openAppsLabel)

        openAppsHelpLabel.font = NSFont.systemFont(ofSize: 11)
        openAppsHelpLabel.textColor = .secondaryLabelColor
        openAppsHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openAppsHelpLabel)

        setupOpenAppsTableView()

        addOpenAppButton.title = "+ Add App..."
        addOpenAppButton.bezelStyle = .rounded
        addOpenAppButton.target = self
        addOpenAppButton.action = #selector(addOpenAppClicked)
        addOpenAppButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addOpenAppButton)
    }

    private func setupAppsTableView() {
        appsTableView.delegate = self
        appsTableView.dataSource = self
        appsTableView.headerView = nil
        appsTableView.rowHeight = 28
        appsTableView.tag = 1

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        nameColumn.width = 300
        appsTableView.addTableColumn(nameColumn)

        let removeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Remove"))
        removeColumn.width = 28
        appsTableView.addTableColumn(removeColumn)

        appsScrollView.documentView = appsTableView
        appsScrollView.hasVerticalScroller = true
        appsScrollView.borderType = .bezelBorder
        appsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsScrollView)
    }

    private func setupOpenAppsTableView() {
        openAppsTableView.delegate = self
        openAppsTableView.dataSource = self
        openAppsTableView.headerView = nil
        openAppsTableView.rowHeight = 28
        openAppsTableView.tag = 2

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        nameColumn.width = 300
        openAppsTableView.addTableColumn(nameColumn)

        let removeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Remove"))
        removeColumn.width = 24
        openAppsTableView.addTableColumn(removeColumn)

        openAppsScrollView.documentView = openAppsTableView
        openAppsScrollView.hasVerticalScroller = true
        openAppsScrollView.borderType = .bezelBorder
        openAppsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openAppsScrollView)
    }

    private func setupConstraints() {
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
            // Icon
            iconButton.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            iconButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            iconButton.widthAnchor.constraint(equalToConstant: 44),
            iconButton.heightAnchor.constraint(equalToConstant: 44),

            // Name
            nameField.centerYAnchor.constraint(equalTo: iconButton.centerYAnchor),
            nameField.leadingAnchor.constraint(equalTo: iconButton.trailingAnchor, constant: 12),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Shortcut
            shortcutLabel.topAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: 16),
            shortcutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            shortcutButton.centerYAnchor.constraint(equalTo: shortcutLabel.centerYAnchor),
            shortcutButton.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 8),

            // Apps label
            appsLabel.topAnchor.constraint(equalTo: shortcutLabel.bottomAnchor, constant: 20),
            appsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Apps help label
            appsHelpLabel.topAnchor.constraint(equalTo: appsLabel.bottomAnchor, constant: 2),
            appsHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            appsHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Apps table - flexible height
            appsScrollView.topAnchor.constraint(equalTo: appsHelpLabel.bottomAnchor, constant: 8),
            appsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            appsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            appsScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            // Add app button
            addAppButton.topAnchor.constraint(equalTo: appsScrollView.bottomAnchor, constant: 8),
            addAppButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Open apps label
            openAppsLabel.topAnchor.constraint(equalTo: addAppButton.bottomAnchor, constant: 20),
            openAppsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Open apps help label
            openAppsHelpLabel.topAnchor.constraint(equalTo: openAppsLabel.bottomAnchor, constant: 2),
            openAppsHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            openAppsHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Open apps table - flexible height
            openAppsScrollView.topAnchor.constraint(equalTo: openAppsHelpLabel.bottomAnchor, constant: 8),
            openAppsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            openAppsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            openAppsScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Add open app button
            addOpenAppButton.topAnchor.constraint(equalTo: openAppsScrollView.bottomAnchor, constant: 8),
            addOpenAppButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            addOpenAppButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -padding)
        ])

        // Make the two tables share remaining space
        appsScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
        openAppsScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    // MARK: - Actions

    @objc private func iconClicked() {
        let picker = EmojiPickerPopover()
        picker.onEmojiSelected = { [weak self] emoji in
            self?.iconButton.title = emoji
            self?.saveCurrentMode()
        }
        picker.show(relativeTo: iconButton.bounds, of: iconButton, preferredEdge: .maxY)
    }

    @objc private func shortcutClicked() {
        let alert = NSAlert()
        alert.messageText = "Shortcuts Coming Soon"
        alert.informativeText = "Keyboard shortcut recording will be available in a future update."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func addAppClicked() {
        showAppPicker { [weak self] app in
            guard let self = self else { return }
            if !self.allowListApps.contains(where: { $0.bundleId == app.bundleId }) {
                self.allowListApps.append(app)
                self.appsTableView.reloadData()
                self.saveCurrentMode()
            }
        }
    }

    @objc private func addOpenAppClicked() {
        showAppPicker { [weak self] app in
            guard let self = self else { return }
            if !self.appsToOpen.contains(where: { $0.bundleId == app.bundleId }) {
                self.appsToOpen.append(app)
                self.openAppsTableView.reloadData()
                self.saveCurrentMode()
            }
        }
    }

    private func showAppPicker(completion: @escaping (AppEntry) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an application"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier,
               let name = bundle.infoDictionary?["CFBundleName"] as? String ?? url.deletingPathExtension().lastPathComponent as String? {
                completion(AppEntry(bundleId: bundleId, name: name))
            }
        }
    }

    // MARK: - Persistence

    private func saveCurrentMode() {
        if isShowingGlobal {
            ConfigStore.shared.updateGlobalAllowList(allowListApps)
        } else if var mode = currentMode {
            mode = ModeConfig(
                id: mode.id,
                name: nameField.stringValue,
                icon: iconButton.title,
                shortcut: mode.shortcut,
                allowList: allowListApps,
                appsToOpen: appsToOpen
            )
            currentMode = mode
            ConfigStore.shared.updateMode(mode)
        }
    }

    // MARK: - Data

    private func loadInstalledApps() {
        let appsPath = "/Applications"
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: appsPath) else { return }

        installedApps = contents
            .filter { $0.hasSuffix(".app") }
            .compactMap { appName -> AppEntry? in
                let url = URL(fileURLWithPath: appsPath).appendingPathComponent(appName)
                guard let bundle = Bundle(url: url),
                      let bundleId = bundle.bundleIdentifier else { return nil }
                let name = bundle.infoDictionary?["CFBundleName"] as? String ?? appName.replacingOccurrences(of: ".app", with: "")
                return AppEntry(bundleId: bundleId, name: name)
            }
            .sorted { $0.name < $1.name }
    }
}

// MARK: - NSTextFieldDelegate

extension ModeDetailViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        saveCurrentMode()
    }
}

// MARK: - NSTableViewDataSource

extension ModeDetailViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView.tag == 1 {
            return allowListApps.count
        } else {
            return appsToOpen.count
        }
    }
}

// MARK: - NSTableViewDelegate

extension ModeDetailViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let apps = tableView.tag == 1 ? allowListApps : appsToOpen
        guard row < apps.count else { return nil }
        let app = apps[row]

        if tableColumn?.identifier.rawValue == "Name" {
            let cell = NSTextField(labelWithString: app.name)
            cell.lineBreakMode = .byTruncatingTail
            return cell
        } else if tableColumn?.identifier.rawValue == "Remove" {
            let button = NSButton()
            button.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Remove")
            button.bezelStyle = .inline
            button.isBordered = false
            button.tag = row
            button.target = self
            button.action = tableView.tag == 1 ? #selector(removeAppClicked(_:)) : #selector(removeOpenAppClicked(_:))
            return button
        }

        return nil
    }

    @objc private func removeAppClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row < allowListApps.count else { return }
        allowListApps.remove(at: row)
        appsTableView.reloadData()
        saveCurrentMode()
    }

    @objc private func removeOpenAppClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row < appsToOpen.count else { return }
        appsToOpen.remove(at: row)
        openAppsTableView.reloadData()
        saveCurrentMode()
    }

}

// MARK: - Emoji Picker

final class EmojiPickerPopover: NSPopover {

    var onEmojiSelected: ((String) -> Void)?

    private let emojis = ["📁", "💼", "💻", "🤖", "🎨", "📚", "🎮", "🎵", "📧", "🔧", "🚀", "⭐️", "🌙", "☀️", "🔥", "💡"]

    override init() {
        super.init()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        let gridView = NSGridView()
        gridView.rowSpacing = 4
        gridView.columnSpacing = 4

        var buttons: [[NSView]] = []
        var currentRow: [NSView] = []

        for (index, emoji) in emojis.enumerated() {
            let button = NSButton(title: emoji, target: self, action: #selector(emojiSelected(_:)))
            button.bezelStyle = .inline
            button.font = NSFont.systemFont(ofSize: 20)
            button.tag = index

            currentRow.append(button)

            if currentRow.count == 4 {
                buttons.append(currentRow)
                currentRow = []
            }
        }

        if !currentRow.isEmpty {
            buttons.append(currentRow)
        }

        for row in buttons {
            gridView.addRow(with: row)
        }

        let viewController = NSViewController()
        viewController.view = gridView
        viewController.view.setFrameSize(NSSize(width: 160, height: 160))

        contentViewController = viewController
        behavior = .transient
    }

    @objc private func emojiSelected(_ sender: NSButton) {
        let emoji = emojis[sender.tag]
        onEmojiSelected?(emoji)
        close()
    }
}
