import Cocoa
import ApplicationServices

/// Detail view controller for editing a mode or global allow list.
final class ModeDetailViewController: NSViewController {

    // MARK: - Callbacks

    /// Called when mode name or icon changes (for sidebar refresh)
    var onModeChanged: (() -> Void)?

    // MARK: - Properties

    private var currentMode: ModeConfig?
    private var isShowingGlobal = false
    private var isSwitchingModes = false  // Prevents infinite recursion during saves

    // MARK: - UI Elements

    // Header (for modes)
    private let iconButton = NSButton()
    private let nameField = NSTextField()
    private let shortcutLabel = NSTextField(labelWithString: "Shortcut:")
    private let shortcutButton = NSButton()

    // Global header (for global section)
    private let globalHeaderView = NSView()
    private let globalIconView = NSImageView()
    private let globalTitleLabel = NSTextField(labelWithString: "Always Open Apps")
    private let globalDescLabel = NSTextField(wrappingLabelWithString: "")

    // Dynamic constraints (switch between global and mode views)
    private var scrollViewTopToHelpLabel: NSLayoutConstraint!
    private var scrollViewTopToGlobalHeader: NSLayoutConstraint!

    // Apps section (single unified list)
    private let appsLabel = NSTextField(labelWithString: "Apps in this mode:")
    private let appsHelpLabel = NSTextField(labelWithString: "Apps that should be running while this mode is active.")
    private let appsWarningLabel = NSTextField(labelWithString: "Apps not listed here may be closed unless marked as Always Open.")
    private let appsScrollView = NSScrollView()
    private let appsTableView = NSTableView()
    private let addAppButton = NSButton()
    private let addRunningAppsButton = NSButton()

    // Empty state
    private let emptyStateLabel = NSTextField(wrappingLabelWithString: "Add the apps you want automatically available when this mode is active.")

    // Data
    private var installedApps: [AppEntry] = []
    private var modeApps: [AppEntry] = []  // Single unified list

    // Dock drag detection using CGEventTap
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var dragStartLocation: NSPoint?
    private var lastHoveredTable: NSTableView?
    private var isDragging = false
    private static weak var currentInstance: ModeDetailViewController?

    // Delete key monitor for apps
    private var deleteKeyMonitor: Any?

    // Clipboard for copy/paste apps between modes
    private static var copiedApps: [AppEntry] = []

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 480))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadInstalledApps()
        setupUI()
        setupConstraints()
        setupDeleteKeyMonitor()

        // Defer dock drag monitor setup to avoid issues with modal alerts during viewDidLoad
        DispatchQueue.main.async { [weak self] in
            self?.setupDockDragMonitor()
        }
    }

    private func setupDeleteKeyMonitor() {
        deleteKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Check if apps table view is the first responder
            let isAppsTableFocused: Bool = {
                guard let firstResponder = self.view.window?.firstResponder else { return false }
                return firstResponder === self.appsTableView || (firstResponder as? NSView)?.isDescendant(of: self.appsTableView) == true
            }()

            // Cmd+C - Copy selected apps
            if event.modifierFlags.contains(.command) && event.keyCode == 8 { // 8 = C key
                if isAppsTableFocused {
                    self.copySelectedApps()
                    return nil
                }
            }

            // Cmd+V - Paste apps
            if event.modifierFlags.contains(.command) && event.keyCode == 9 { // 9 = V key
                if isAppsTableFocused {
                    self.pasteApps()
                    return nil
                }
            }

            // Delete/backspace key (keyCode 51) - Delete selected apps
            if event.keyCode == 51 {
                if isAppsTableFocused {
                    self.deleteSelectedApps()
                    return nil
                }
            }
            return event
        }
    }

    private func copySelectedApps() {
        let selectedRows = appsTableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        var appsToCopy: [AppEntry] = []
        for row in selectedRows {
            if row < modeApps.count {
                appsToCopy.append(modeApps[row])
            }
        }

        ModeDetailViewController.copiedApps = appsToCopy
        print("📋 Copied \(appsToCopy.count) apps: \(appsToCopy.map { $0.name }.joined(separator: ", "))")

        // Visual feedback - brief flash
        ToastWindow.show(message: "Copied \(appsToCopy.count) app\(appsToCopy.count == 1 ? "" : "s")")
    }

    private func pasteApps() {
        let appsToPaste = ModeDetailViewController.copiedApps
        guard !appsToPaste.isEmpty else {
            print("📋 Nothing to paste")
            return
        }

        var addedCount = 0
        for app in appsToPaste {
            if !modeApps.contains(where: { $0.bundleId == app.bundleId }) {
                modeApps.append(app)
                addedCount += 1
            }
        }

        if addedCount > 0 {
            appsTableView.reloadData()
            updateEmptyState()
            saveCurrentMode()
            print("📋 Pasted \(addedCount) apps")
            ToastWindow.show(message: "Pasted \(addedCount) app\(addedCount == 1 ? "" : "s")")
        } else {
            print("📋 All apps already in mode")
            ToastWindow.show(message: "Apps already in this mode")
        }
    }

    private func deleteSelectedApps() {
        let selectedRows = appsTableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        // Animate fade-out for all selected rows
        var rowViews: [NSTableRowView] = []
        for row in selectedRows {
            if let rowView = appsTableView.rowView(atRow: row, makeIfNecessary: false) {
                rowView.wantsLayer = true
                rowViews.append(rowView)
            }
        }

        if !rowViews.isEmpty {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                for rowView in rowViews {
                    rowView.animator().alphaValue = 0
                }
            }) { [weak self] in
                guard let self = self else { return }
                // Remove in reverse order after animation
                for row in selectedRows.reversed() {
                    if row < self.modeApps.count {
                        self.modeApps.remove(at: row)
                    }
                }
                self.appsTableView.reloadData()
                self.updateEmptyState()
                self.saveCurrentMode()
            }
        } else {
            // Fallback: remove immediately
            for row in selectedRows.reversed() {
                if row < modeApps.count {
                    modeApps.remove(at: row)
                }
            }
            appsTableView.reloadData()
            updateEmptyState()
            saveCurrentMode()
        }
    }

    deinit {
        ModeDetailViewController.currentInstance = nil
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let monitor = deleteKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func debugLog(_ message: String) {
        let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/deskmodes_debug.log")
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] DETAIL: \(message)\n"
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

    // MARK: - Public API

    /// Focus the name field and select all text for immediate editing
    func focusNameField() {
        guard !isShowingGlobal else { return }
        view.window?.makeFirstResponder(nameField)
        nameField.selectText(nil)
    }

    func showMode(_ mode: ModeConfig) {
        debugLog("showMode: Called with '\(mode.name)' (id: \(mode.id)) containing \(mode.apps.count) apps: \(mode.apps.map { $0.name }.joined(separator: ", "))")
        print("🟢 showMode: Called with '\(mode.name)' (id: \(mode.id))")

        // Prevent recursive saves during mode switching
        guard !isSwitchingModes else {
            debugLog("showMode: BLOCKED by isSwitchingModes guard")
            print("🔴 showMode: BLOCKED by isSwitchingModes guard!")
            return
        }
        isSwitchingModes = true
        print("🟢 showMode: isSwitchingModes set to true")

        debugLog("showMode: Current state - currentMode: \(currentMode?.name ?? "nil"), modeApps count: \(modeApps.count)")

        // Save current mode before switching (only if we have something to save)
        if isShowingGlobal || currentMode != nil {
            debugLog("showMode: Will save current mode before switching")
            saveCurrentMode()
        } else {
            debugLog("showMode: No previous mode to save (first load)")
        }

        isShowingGlobal = false
        currentMode = mode

        // Hide global header, show mode-specific UI
        globalHeaderView.isHidden = true
        updateIconButton(with: mode.icon)
        iconButton.isHidden = false
        nameField.isHidden = false
        nameField.stringValue = mode.name
        nameField.isEditable = true
        shortcutLabel.isHidden = false
        shortcutButton.isHidden = false
        shortcutButton.title = mode.shortcut ?? "None"
        appsLabel.isHidden = false
        appsHelpLabel.isHidden = false

        appsLabel.stringValue = "Apps in this mode:"
        appsHelpLabel.stringValue = "Apps that should be running while this mode is active."
        appsWarningLabel.isHidden = false
        addRunningAppsButton.isHidden = false

        // Switch constraints: table below help label
        scrollViewTopToGlobalHeader.isActive = false
        scrollViewTopToHelpLabel.isActive = true

        // Update data and reload
        modeApps = mode.apps
        debugLog("showMode: Set modeApps to \(modeApps.count) apps from mode.apps")

        // Update empty state visibility
        updateEmptyState()

        // Debug: Print frame info BEFORE reload
        print("📐 BEFORE reload:")
        print("📐   ScrollView frame: \(appsScrollView.frame)")
        print("📐   ScrollView documentVisibleRect: \(appsScrollView.documentVisibleRect)")
        print("📐   TableView frame: \(appsTableView.frame)")
        print("📐   TableView enclosingScrollView: \(String(describing: appsTableView.enclosingScrollView))")

        // Force layout first
        view.layoutSubtreeIfNeeded()
        appsScrollView.layoutSubtreeIfNeeded()

        // Notify table of row count change and reload
        appsTableView.noteNumberOfRowsChanged()
        appsTableView.reloadData()

        // Debug: Print frame info AFTER reload
        print("📐 AFTER reload:")
        print("📐   TableView numberOfRows: \(appsTableView.numberOfRows)")
        print("📐   TableView frame: \(appsTableView.frame)")
        print("📐   ScrollView documentVisibleRect: \(appsScrollView.documentVisibleRect)")

        // Force the scroll view to update its content
        if let clipView = appsScrollView.contentView as? NSClipView {
            clipView.scroll(to: .zero)
            appsScrollView.reflectScrolledClipView(clipView)
        }

        print("🔄 showMode: Table now has \(appsTableView.numberOfRows) rows, modeApps has \(modeApps.count) apps")

        // Allow next mode switch only after run loop processes table reload
        // This prevents race condition where another showMode overwrites modeApps before cells render
        DispatchQueue.main.async { [weak self] in
            self?.isSwitchingModes = false
            self?.debugLog("showMode: isSwitchingModes reset to false (async)")
        }
    }

    func showGlobalAllowList() {
        print("🔵 showGlobalAllowList: Called!")
        // Prevent recursive saves during mode switching
        guard !isSwitchingModes else {
            print("🔴 showGlobalAllowList: BLOCKED by isSwitchingModes guard!")
            return
        }
        isSwitchingModes = true
        print("🔵 showGlobalAllowList: Processing...")

        // Save current mode before switching (only if we have something to save)
        if isShowingGlobal || currentMode != nil {
            saveCurrentMode()
        }

        isShowingGlobal = true
        currentMode = nil

        // Show global header, hide mode-specific UI
        globalHeaderView.isHidden = false
        iconButton.isHidden = true
        nameField.isHidden = true
        shortcutLabel.isHidden = true
        shortcutButton.isHidden = true
        appsLabel.isHidden = true
        appsHelpLabel.isHidden = true
        appsWarningLabel.isHidden = true
        emptyStateLabel.isHidden = true
        addRunningAppsButton.isHidden = true

        // Switch constraints: table below global header
        scrollViewTopToHelpLabel.isActive = false
        scrollViewTopToGlobalHeader.isActive = true

        // TWO-PHASE reload
        let globalApps = ConfigStore.shared.config.globalAllowList
        print("🔄 showGlobalAllowList: Two-phase reload - clearing table, then adding \(globalApps.count) apps")

        modeApps = []
        appsTableView.reloadData()

        modeApps = globalApps
        appsTableView.reloadData()

        appsTableView.needsDisplay = true
        appsScrollView.needsDisplay = true

        print("🔄 showGlobalAllowList: Table now has \(appsTableView.numberOfRows) rows")

        // Allow next mode switch only after run loop processes table reload
        DispatchQueue.main.async { [weak self] in
            self?.isSwitchingModes = false
        }
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

        // Global header (hidden by default, shown only for Global section)
        setupGlobalHeader()

        // Apps label
        appsLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        appsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsLabel)

        // Apps help label (reduced visual weight)
        appsHelpLabel.font = NSFont.systemFont(ofSize: 10)
        appsHelpLabel.textColor = .tertiaryLabelColor
        appsHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsHelpLabel)

        // Apps warning label (subtle)
        appsWarningLabel.font = NSFont.systemFont(ofSize: 10)
        appsWarningLabel.textColor = .tertiaryLabelColor
        appsWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsWarningLabel)

        // Apps table
        setupAppsTableView()

        // Empty state label (hidden by default)
        emptyStateLabel.font = NSFont.systemFont(ofSize: 13)
        emptyStateLabel.textColor = .secondaryLabelColor
        emptyStateLabel.alignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)

        // Add app button
        addAppButton.title = "+ Add App..."
        addAppButton.bezelStyle = .rounded
        addAppButton.target = self
        addAppButton.action = #selector(addAppClicked)
        addAppButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addAppButton)

        // Add running apps button (secondary)
        addRunningAppsButton.title = "Add running apps..."
        addRunningAppsButton.bezelStyle = .rounded
        addRunningAppsButton.target = self
        addRunningAppsButton.action = #selector(addRunningAppsClicked)
        addRunningAppsButton.translatesAutoresizingMaskIntoConstraints = false
        addRunningAppsButton.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(addRunningAppsButton)
    }

    private func setupGlobalHeader() {
        globalHeaderView.translatesAutoresizingMaskIntoConstraints = false
        globalHeaderView.wantsLayer = true
        globalHeaderView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        globalHeaderView.layer?.cornerRadius = 12
        globalHeaderView.isHidden = true  // Hidden by default
        view.addSubview(globalHeaderView)

        // Global icon (use existing icon from ModeIcons)
        globalIconView.translatesAutoresizingMaskIntoConstraints = false
        globalIconView.imageScaling = .scaleProportionallyUpOrDown
        if let iconPath = Bundle.main.path(forResource: "global_mode", ofType: "png", inDirectory: "ModeIcons"),
           let icon = NSImage(contentsOfFile: iconPath) {
            icon.size = NSSize(width: 40, height: 40)
            globalIconView.image = icon
        }
        globalHeaderView.addSubview(globalIconView)

        // Title
        globalTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        globalTitleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        globalTitleLabel.textColor = .labelColor
        globalTitleLabel.stringValue = "Always Open Apps"
        globalHeaderView.addSubview(globalTitleLabel)

        // Description
        globalDescLabel.translatesAutoresizingMaskIntoConstraints = false
        globalDescLabel.font = NSFont.systemFont(ofSize: 12)
        globalDescLabel.textColor = .secondaryLabelColor
        globalDescLabel.stringValue = "Apps that remain open across all modes."
        globalDescLabel.maximumNumberOfLines = 3
        globalDescLabel.lineBreakMode = .byWordWrapping
        globalHeaderView.addSubview(globalDescLabel)

        // Constraints for global header contents
        NSLayoutConstraint.activate([
            globalIconView.leadingAnchor.constraint(equalTo: globalHeaderView.leadingAnchor, constant: 16),
            globalIconView.topAnchor.constraint(equalTo: globalHeaderView.topAnchor, constant: 16),
            globalIconView.widthAnchor.constraint(equalToConstant: 40),
            globalIconView.heightAnchor.constraint(equalToConstant: 40),

            globalTitleLabel.leadingAnchor.constraint(equalTo: globalIconView.trailingAnchor, constant: 12),
            globalTitleLabel.topAnchor.constraint(equalTo: globalHeaderView.topAnchor, constant: 16),
            globalTitleLabel.trailingAnchor.constraint(equalTo: globalHeaderView.trailingAnchor, constant: -16),

            globalDescLabel.leadingAnchor.constraint(equalTo: globalIconView.trailingAnchor, constant: 12),
            globalDescLabel.topAnchor.constraint(equalTo: globalTitleLabel.bottomAnchor, constant: 4),
            globalDescLabel.trailingAnchor.constraint(equalTo: globalHeaderView.trailingAnchor, constant: -16),
            globalDescLabel.bottomAnchor.constraint(equalTo: globalHeaderView.bottomAnchor, constant: -16)
        ])
    }

    private func setupAppsTableView() {
        appsTableView.delegate = self
        appsTableView.dataSource = self
        appsTableView.headerView = nil
        appsTableView.rowHeight = 32
        appsTableView.tag = 1
        appsTableView.allowsMultipleSelection = true  // Enable Shift+click multi-select

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        nameColumn.width = 280
        appsTableView.addTableColumn(nameColumn)

        let removeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Remove"))
        removeColumn.width = 44
        appsTableView.addTableColumn(removeColumn)

        // Register for drag & drop - multiple types for different sources
        appsTableView.registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.icns"),
            NSPasteboard.PasteboardType("public.url"),
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("dyn.ah62d4rv4gu8y")
        ])
        appsTableView.setDraggingSourceOperationMask(.copy, forLocal: false)

        appsScrollView.documentView = appsTableView
        appsScrollView.hasVerticalScroller = true
        appsScrollView.borderType = .bezelBorder
        appsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appsScrollView)
    }

    private func setupConstraints() {
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
            // Global header (for global section)
            globalHeaderView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            globalHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            globalHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Icon (for modes)
            iconButton.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            iconButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            iconButton.widthAnchor.constraint(equalToConstant: 44),
            iconButton.heightAnchor.constraint(equalToConstant: 44),

            // Name (next to icon)
            nameField.centerYAnchor.constraint(equalTo: iconButton.centerYAnchor),
            nameField.leadingAnchor.constraint(equalTo: iconButton.trailingAnchor, constant: 12),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Apps label (below name - REORDERED: apps before shortcut)
            appsLabel.topAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: 20),
            appsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Apps help label
            appsHelpLabel.topAnchor.constraint(equalTo: appsLabel.bottomAnchor, constant: 2),
            appsHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            appsHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Apps warning label
            appsWarningLabel.topAnchor.constraint(equalTo: appsHelpLabel.bottomAnchor, constant: 2),
            appsWarningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            appsWarningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Apps table - leading, trailing (top is dynamic, bottom above shortcut)
            appsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            appsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            appsScrollView.bottomAnchor.constraint(equalTo: addAppButton.topAnchor, constant: -8),

            // Empty state label (centered in scroll view area)
            emptyStateLabel.centerXAnchor.constraint(equalTo: appsScrollView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: appsScrollView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: appsScrollView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: appsScrollView.trailingAnchor, constant: -20),

            // Add app button
            addAppButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            addAppButton.bottomAnchor.constraint(equalTo: shortcutLabel.topAnchor, constant: -16),

            // Add running apps button (next to add app button)
            addRunningAppsButton.leadingAnchor.constraint(equalTo: addAppButton.trailingAnchor, constant: 8),
            addRunningAppsButton.centerYAnchor.constraint(equalTo: addAppButton.centerYAnchor),

            // Shortcut (REORDERED: now at bottom, secondary information)
            shortcutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            shortcutLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),

            shortcutButton.centerYAnchor.constraint(equalTo: shortcutLabel.centerYAnchor),
            shortcutButton.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 8)
        ])

        // Dynamic constraints for scrollView top (switch between mode and global views)
        scrollViewTopToHelpLabel = appsScrollView.topAnchor.constraint(equalTo: appsWarningLabel.bottomAnchor, constant: 8)
        scrollViewTopToGlobalHeader = appsScrollView.topAnchor.constraint(equalTo: globalHeaderView.bottomAnchor, constant: 16)

        // Default: mode view (not global)
        scrollViewTopToHelpLabel.isActive = true
        scrollViewTopToGlobalHeader.isActive = false
    }

    // MARK: - Actions

    @objc private func iconClicked() {
        let picker = IconPickerPopover()
        picker.onIconSelected = { [weak self] iconName in
            self?.updateIconButton(with: iconName)
            self?.saveCurrentMode()
        }
        picker.show(relativeTo: iconButton.bounds, of: iconButton, preferredEdge: .maxY)
    }

    private func updateIconButton(with iconName: String) {
        if let icon = IconPickerPopover.loadIcon(named: iconName) {
            icon.size = NSSize(width: 32, height: 32)
            iconButton.image = icon
            iconButton.title = ""
            iconButton.imagePosition = .imageOnly
        }
        // Store the icon name for saving
        iconButton.identifier = NSUserInterfaceItemIdentifier(iconName)
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
        showAppPicker(relativeTo: addAppButton) { [weak self] app in
            guard let self = self else { return }
            self.addAppWithAnimation(app)
        }
    }

    @objc private func addRunningAppsClicked() {
        let popover = RunningAppsPopover()

        // Build disabled apps list (already in mode or in Always Open)
        var disabled: [String: String] = [:]
        for app in modeApps {
            disabled[app.bundleId] = "already added"
        }
        if !isShowingGlobal {
            let globalApps = ConfigStore.shared.config.globalAllowList
            for app in globalApps {
                if disabled[app.bundleId] == nil {
                    disabled[app.bundleId] = "in Always Open"
                }
            }
        }
        popover.disabledApps = disabled

        popover.onAppsSelected = { [weak self] apps in
            guard let self = self else { return }
            for app in apps {
                self.addAppWithAnimation(app)
            }
        }

        popover.show(relativeTo: addRunningAppsButton.bounds, of: addRunningAppsButton, preferredEdge: .maxY)
    }

    /// Add an app with subtle animation feedback
    private func addAppWithAnimation(_ app: AppEntry) {
        guard !modeApps.contains(where: { $0.bundleId == app.bundleId }) else { return }

        modeApps.append(app)
        appsTableView.reloadData()
        updateEmptyState()
        saveCurrentMode()

        // Animate the newly added row (subtle highlight)
        let newRow = modeApps.count - 1

        // Scroll to make the row visible first
        appsTableView.scrollRowToVisible(newRow)

        // Delay animation slightly to ensure row is rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            if let rowView = self.appsTableView.rowView(atRow: newRow, makeIfNecessary: true) {
                rowView.wantsLayer = true

                // Create highlight layer for animation
                let highlightLayer = CALayer()
                highlightLayer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
                highlightLayer.frame = rowView.bounds
                rowView.layer?.addSublayer(highlightLayer)

                // Fade out animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.4)
                    CATransaction.setCompletionBlock {
                        highlightLayer.removeFromSuperlayer()
                    }
                    highlightLayer.opacity = 0
                    CATransaction.commit()
                }
            }
        }
    }

    private func showAppPicker(relativeTo button: NSButton, completion: @escaping (AppEntry) -> Void) {
        let picker = AppSearchPopover()

        // Build disabled apps list
        var disabled: [String: String] = [:]

        // Apps already in this mode
        for app in modeApps {
            disabled[app.bundleId] = "already added"
        }

        // Apps in Global Always Open (only when editing a mode, not global itself)
        if !isShowingGlobal {
            let globalApps = ConfigStore.shared.config.globalAllowList
            for app in globalApps {
                if disabled[app.bundleId] == nil {
                    disabled[app.bundleId] = "in Always Open"
                }
            }
        }

        picker.disabledApps = disabled
        picker.onAppSelected = completion
        picker.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

    // MARK: - Empty State

    private func updateEmptyState() {
        // Only show empty state for modes, not for Global
        if isShowingGlobal {
            emptyStateLabel.isHidden = true
            return
        }
        emptyStateLabel.isHidden = !modeApps.isEmpty
    }

    // MARK: - Persistence

    private func saveCurrentMode() {
        // Don't save if nothing is loaded yet
        guard isShowingGlobal || currentMode != nil else {
            print("🔴 saveCurrentMode: SKIPPED (nothing loaded)")
            return
        }

        if isShowingGlobal {
            print("🟡 saveCurrentMode: Saving GLOBAL with \(modeApps.count) apps")
            ConfigStore.shared.updateGlobalAllowList(modeApps)
            ConfigStore.shared.saveImmediately()
        } else if var mode = currentMode {
            // Check if mode still exists (might have been deleted)
            guard ConfigStore.shared.config.modes.contains(where: { $0.id == mode.id }) else {
                print("🔴 saveCurrentMode: SKIPPED (mode '\(mode.name)' was deleted)")
                currentMode = nil
                return
            }
            print("🟢 saveCurrentMode: Saving mode '\(mode.name)' (id: \(mode.id)) with \(modeApps.count) apps: \(modeApps.map { $0.name }.joined(separator: ", "))")
            let iconName = iconButton.identifier?.rawValue ?? mode.icon
            mode = ModeConfig(
                id: mode.id,
                name: nameField.stringValue,
                icon: iconName,
                shortcut: mode.shortcut,
                apps: modeApps
            )
            currentMode = mode
            ConfigStore.shared.updateMode(mode)
            ConfigStore.shared.saveImmediately() // <<--- FUERZA EL GUARDADO AQUÍ

            // Verify save
            if let savedMode = ConfigStore.shared.config.modes.first(where: { $0.id == mode.id }) {
                print("🔵 saveCurrentMode: VERIFIED - ConfigStore now has '\(savedMode.name)' with \(savedMode.apps.count) apps: \(savedMode.apps.map { $0.name }.joined(separator: ", "))")
            } else {
                print("🔴 saveCurrentMode: ERROR - Mode not found in ConfigStore after save!")
            }

            // Notify sidebar to refresh (name/icon changes)
            onModeChanged?()
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
    func controlTextDidChange(_ obj: Notification) {
        // Update sidebar in realtime as user types
        guard !isSwitchingModes else { return }
        guard !isShowingGlobal, var mode = currentMode else { return }

        // Update the mode with new name
        let iconName = iconButton.identifier?.rawValue ?? mode.icon
        mode = ModeConfig(
            id: mode.id,
            name: nameField.stringValue,
            icon: iconName,
            shortcut: mode.shortcut,
            apps: modeApps
        )
        currentMode = mode
        ConfigStore.shared.updateMode(mode)

        // Refresh sidebar to show updated name
        onModeChanged?()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        // Save to disk when editing ends
        guard !isSwitchingModes else { return }
        ConfigStore.shared.saveImmediately()
    }
}

// MARK: - NSTableViewDataSource

extension ModeDetailViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("📊 numberOfRows called - modeApps.count: \(modeApps.count), tableView tag: \(tableView.tag)")
        return modeApps.count
    }
}

// MARK: - NSTableViewDelegate

extension ModeDetailViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("🎨 viewFor row \(row), column: \(tableColumn?.identifier.rawValue ?? "nil"), modeApps.count: \(modeApps.count), tableView.tag: \(tableView.tag)")
        guard row < modeApps.count else {
            print("🎨 viewFor row \(row) - RETURNING NIL (out of bounds)")
            return nil
        }
        let app = modeApps[row]
        print("🎨 viewFor row \(row) - Creating view for app: \(app.name)")

        if tableColumn?.identifier.rawValue == "Name" {
            // Create container view with icon and label
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false

            // App icon
            let iconView = NSImageView()
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.imageScaling = .scaleProportionallyUpOrDown
            iconView.image = iconForApp(bundleId: app.bundleId)
            container.addSubview(iconView)

            // App name
            let label = NSTextField(labelWithString: app.name)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.lineBreakMode = .byTruncatingTail
            container.addSubview(label)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
                iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),

                label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            return container
        } else if tableColumn?.identifier.rawValue == "Remove" {
            // Container to add padding from scrollbar
            let container = NSView()

            let button = NSButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Remove")
            button.bezelStyle = .inline
            button.isBordered = false
            button.tag = row
            button.target = self
            button.action = #selector(removeAppClicked(_:))
            container.addSubview(button)

            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
                button.widthAnchor.constraint(equalToConstant: 20),
                button.heightAnchor.constraint(equalToConstant: 20)
            ])

            return container
        }

        return nil
    }

    private func iconForApp(bundleId: String) -> NSImage? {
        // Try NSWorkspace first (fastest)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        // Search in common locations
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications",
            "/Applications/Utilities"
        ]

        for searchPath in searchPaths {
            if let found = findAppIcon(bundleId: bundleId, in: searchPath) {
                return found
            }
        }

        return NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App")
    }

    private func findAppIcon(bundleId: String, in directory: String) -> NSImage? {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return nil
        }

        for item in contents where item.hasSuffix(".app") {
            let appPath = (directory as NSString).appendingPathComponent(item)
            if let bundle = Bundle(path: appPath),
               bundle.bundleIdentifier == bundleId {
                return NSWorkspace.shared.icon(forFile: appPath)
            }
        }
        return nil
    }

    // MARK: - Drag & Drop

    private func getAppURLsFromPasteboard(_ pasteboard: NSPasteboard) -> [URL] {
        var urls: [URL] = []

        // Try modern NSURL approach first
        if let urlObjects = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            urls.append(contentsOf: urlObjects)
        }

        // Also try legacy filenames approach (used by Dock)
        if let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            for filename in filenames {
                urls.append(URL(fileURLWithPath: filename))
            }
        }

        return urls.filter { $0.pathExtension == "app" }
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        // Accept drops on the whole table (not between rows)
        if dropOperation == .on {
            return []
        }

        // Debug: log all pasteboard types
        let types = info.draggingPasteboard.types ?? []
        print("🔍 Pasteboard types: \(types.map { $0.rawValue })")
        for type in types {
            if let data = info.draggingPasteboard.data(forType: type) {
                print("  - \(type.rawValue): \(data.count) bytes")
                if let str = String(data: data, encoding: .utf8), str.count < 500 {
                    print("    Content: \(str)")
                }
            }
            if let plist = info.draggingPasteboard.propertyList(forType: type) {
                print("    PList: \(plist)")
            }
        }

        // Temporarily accept all drags for debugging
        if !types.isEmpty {
            return .copy
        }

        let appURLs = getAppURLsFromPasteboard(info.draggingPasteboard)
        return appURLs.isEmpty ? [] : .copy
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let appURLs = getAppURLsFromPasteboard(info.draggingPasteboard)
        guard !appURLs.isEmpty else { return false }

        var added = false
        for url in appURLs {
            guard let bundle = Bundle(url: url),
                  let bundleId = bundle.bundleIdentifier else { continue }

            let name = bundle.infoDictionary?["CFBundleName"] as? String
                ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                ?? url.deletingPathExtension().lastPathComponent

            let app = AppEntry(bundleId: bundleId, name: name)

            if !modeApps.contains(where: { $0.bundleId == bundleId }) {
                modeApps.append(app)
                added = true
            }
        }

        if added {
            tableView.reloadData()
            updateEmptyState()
            saveCurrentMode()
        }

        return added
    }

    @objc private func removeAppClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row < modeApps.count else { return }

        // Animate row fade-out before removing
        if let rowView = appsTableView.rowView(atRow: row, makeIfNecessary: false) {
            rowView.wantsLayer = true

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                rowView.animator().alphaValue = 0
            }) { [weak self] in
                guard let self = self else { return }
                // Remove after animation completes
                if row < self.modeApps.count {
                    self.modeApps.remove(at: row)
                    self.appsTableView.reloadData()
                    self.updateEmptyState()
                    self.saveCurrentMode()
                }
            }
        } else {
            // Fallback: remove immediately if row view not available
            modeApps.remove(at: row)
            appsTableView.reloadData()
            updateEmptyState()
            saveCurrentMode()
        }
    }

    // MARK: - Dock Drag Detection

    private func setupDockDragMonitor() {
        print("🚀 DeskModes: Setting up Dock drag monitor with CGEventTap...")
        ModeDetailViewController.currentInstance = self

        // Create event tap for mouse events
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseDragged.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                ModeDetailViewController.handleCGEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            print("❌ DeskModes: Failed to create event tap. Make sure Accessibility permissions are granted.")
            print("💡 DeskModes: Go to System Settings > Privacy & Security > Accessibility and add DeskModes")
            // Show alert to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "To enable drag from Dock, please add DeskModes to:\nSystem Settings > Privacy & Security > Accessibility"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Later")

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("✅ DeskModes: CGEventTap setup complete and enabled")
        } else {
            print("❌ DeskModes: Failed to create run loop source")
        }
    }

    private static func handleCGEvent(type: CGEventType, event: CGEvent) {
        guard let instance = currentInstance else { return }

        let location = event.location
        // Convert from CG coordinates (top-left origin) to NS coordinates (bottom-left origin)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let nsLocation = NSPoint(x: location.x, y: screenHeight - location.y)

        switch type {
        case .leftMouseDown:
            instance.isDragging = false
            instance.dragStartLocation = nsLocation
            // Only log if starting near Dock area (bottom 100px) to reduce noise
            if nsLocation.y < 100 {
                print("🖱️ DeskModes: Mouse down near Dock at: %.0f, %.0f", nsLocation.x, nsLocation.y)
            }

        case .leftMouseDragged:
            if !instance.isDragging {
                instance.isDragging = true
                if let start = instance.dragStartLocation, start.y < 100 {
                    print("🖱️ DeskModes: Drag started from Dock area: %.0f, %.0f", start.x, start.y)
                }
            }
            instance.updateHoveredTable(at: nsLocation)

        case .leftMouseUp:
            if instance.isDragging, let start = instance.dragStartLocation, start.y < 100 {
                print("🖱️ DeskModes: Mouse up at: %.0f, %.0f", nsLocation.x, nsLocation.y)
            }
            if instance.isDragging {
                instance.handleDragEnd(endLocation: nsLocation)
            }
            instance.isDragging = false
            instance.dragStartLocation = nil
            instance.lastHoveredTable = nil

        default:
            break
        }
    }

    private func handleDragEnd(endLocation: NSPoint) {
        guard let startLocation = dragStartLocation else {
            return  // Silent - no drag start
        }

        guard let targetTable = lastHoveredTable else {
            if startLocation.y < 100 {
                print("❌ DeskModes: Drag from Dock ended but not over a table")
            }
            return
        }

        print("✅ DeskModes: Drag from (%.0f, %.0f) to table tag: %d", startLocation.x, startLocation.y, targetTable.tag)

        // Check if drag started from Dock area (bottom 80 pixels of screen)
        if let screen = NSScreen.main {
            let dockHeight: CGFloat = 80
            let dockArea = NSRect(x: 0, y: 0, width: screen.frame.width, height: dockHeight)

            if dockArea.contains(startLocation) {
                print("🎯 DeskModes: Drag came from Dock area!")
                // macOS blocks Accessibility API for Dock (error -25211)
                // Show popup menu for reliable app selection
                DispatchQueue.main.async { [weak self] in
                    self?.showDockAppPicker(for: targetTable)
                }
            }
        }
    }

    private func getDockItemAtPosition(_ position: NSPoint) -> AppEntry? {
        // Use AXUIElementCopyElementAtPosition to get element under cursor
        // Then get PID to identify the app

        // Convert from Cocoa coordinates (origin bottom-left) to AX/CG coordinates (origin top-left)
        guard let screen = NSScreen.main else { return nil }
        let screenHeight = screen.frame.height
        let axY = screenHeight - position.y

        print("🔍 DeskModes: Checking element at Cocoa pos (%.0f, %.0f) -> AX pos (%.0f, %.0f)",
              position.x, position.y, position.x, axY)

        let systemWide = AXUIElementCreateSystemWide()

        var element: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(systemWide, Float(position.x), Float(axY), &element)

        guard err == .success, let el = element else {
            print("⚠️ DeskModes: AXUIElementCopyElementAtPosition failed: %d", err.rawValue)
            return nil
        }

        // Get PID of the app that owns this element
        var pid: pid_t = 0
        AXUIElementGetPid(el, &pid)

        print("🔍 DeskModes: Element PID: %d", pid)

        // Get the running application from PID
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            print("⚠️ DeskModes: No app found for PID %d", pid)
            return nil
        }

        // Check if it's the Dock - if so, try to get the specific dock item info
        if app.bundleIdentifier == "com.apple.dock" {
            print("🔍 DeskModes: Element belongs to Dock, checking AXTitle...")

            // Try to get the title of the dock item
            var titleValue: CFTypeRef?
            AXUIElementCopyAttributeValue(el, kAXTitleAttribute as CFString, &titleValue)

            if let title = titleValue as? String, !title.isEmpty {
                print("✅ DeskModes: Dock item title: %@", title)

                // Try to find the app by name
                if let foundApp = findAppByName(title) {
                    return foundApp
                }

                // Try to get URL attribute for bundle path
                var urlValue: CFTypeRef?
                AXUIElementCopyAttributeValue(el, kAXURLAttribute as CFString, &urlValue)

                if let url = urlValue as? URL {
                    let path = url.path
                    if let bundle = Bundle(path: path), let bundleId = bundle.bundleIdentifier {
                        return AppEntry(bundleId: bundleId, name: title)
                    }
                } else if let urlString = urlValue as? String, let url = URL(string: urlString) {
                    let path = url.path
                    if let bundle = Bundle(path: path), let bundleId = bundle.bundleIdentifier {
                        return AppEntry(bundleId: bundleId, name: title)
                    }
                }

                // Search for app by name
                return findAppByName(title)
            }

            return nil
        }

        // It's a regular app (not dock) - return its info
        if let bundleId = app.bundleIdentifier, let name = app.localizedName {
            print("✅ DeskModes: Found app: %@ (%@)", name, bundleId)
            return AppEntry(bundleId: bundleId, name: name)
        }

        return nil
    }

    private func getDockAppAtPosition(_ position: NSPoint) -> AppEntry? {
        // Build dock order: Finder + persistent apps + running non-persistent apps
        var dockApps: [AppEntry] = []

        // 1. Finder is always first
        dockApps.append(AppEntry(bundleId: "com.apple.finder", name: "Finder"))

        // 2. Get persistent apps from dock plist
        let dockPlistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist"
        var persistentBundleIds = Set<String>()

        if let dockPrefs = NSDictionary(contentsOfFile: dockPlistPath),
           let persistentApps = dockPrefs["persistent-apps"] as? [[String: Any]] {
            for appDict in persistentApps {
                if let tileData = appDict["tile-data"] as? [String: Any],
                   let bundleId = tileData["bundle-identifier"] as? String {
                    persistentBundleIds.insert(bundleId)
                    // Get app info
                    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
                        if let name = app.localizedName {
                            dockApps.append(AppEntry(bundleId: bundleId, name: name))
                        }
                    } else if let filePath = tileData["file-data"] as? [String: Any],
                              let path = filePath["_CFURLString"] as? String {
                        // App not running, get name from path
                        let url = URL(string: path) ?? URL(fileURLWithPath: path)
                        let appName = url.deletingPathExtension().lastPathComponent
                        dockApps.append(AppEntry(bundleId: bundleId, name: appName))
                    }
                }
            }
        }

        // 3. Add running apps that are NOT in persistent (these appear after persistent)
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                app.bundleIdentifier != nil &&
                app.bundleIdentifier != "com.apple.finder" &&
                !persistentBundleIds.contains(app.bundleIdentifier!)
            }
            .sorted { ($0.launchDate ?? Date.distantPast) < ($1.launchDate ?? Date.distantPast) }

        for app in runningApps {
            if let bundleId = app.bundleIdentifier, let name = app.localizedName {
                dockApps.append(AppEntry(bundleId: bundleId, name: name))
            }
        }

        // Get tile size for position calculation
        let tileSize: CGFloat
        if let dockPrefs = NSDictionary(contentsOfFile: dockPlistPath),
           let size = dockPrefs["tilesize"] as? CGFloat {
            tileSize = size
        } else {
            tileSize = 48.0
        }

        // Calculate which icon was clicked
        let dockLeftPadding: CGFloat = 4.0
        let iconSpacing: CGFloat = 4.0
        let iconTotalSize = tileSize + iconSpacing

        let clickX = position.x
        let relativeX = clickX - dockLeftPadding
        let iconIndex = max(0, Int(relativeX / iconTotalSize))

        print("🔍 DeskModes: Dock has %d apps, tileSize=%.0f, clickX=%.0f, iconIndex=%d",
              dockApps.count, tileSize, clickX, iconIndex)

        // Log dock order for debugging
        for (i, app) in dockApps.prefix(10).enumerated() {
            print("🔍 DeskModes: Dock[%d] = %@ (%@)", i, app.name, app.bundleId)
        }

        if iconIndex < dockApps.count {
            let app = dockApps[iconIndex]
            print("✅ DeskModes: Matched dock app at index %d: %@ (%@)", iconIndex, app.name, app.bundleId)
            return app
        }

        print("❌ DeskModes: Index %d out of range (dock has %d apps)", iconIndex, dockApps.count)
        return nil
    }

    private func findAppByName(_ name: String) -> AppEntry? {
        // First check running apps
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.localizedName == name || $0.bundleIdentifier?.contains(name.lowercased()) == true
        }) {
            if let bundleId = app.bundleIdentifier, let appName = app.localizedName {
                return AppEntry(bundleId: bundleId, name: appName)
            }
        }

        // Check for Finder specifically
        if name == "Finder" {
            return AppEntry(bundleId: "com.apple.finder", name: "Finder")
        }

        // Check for Trash
        if name == "Trash" || name == "Papelera" {
            return nil // Skip trash
        }

        // Try to find in installed apps
        if let app = installedApps.first(where: { $0.name == name }) {
            return app
        }

        // Search in application directories
        let searchPaths = ["/Applications", "/System/Applications", "/Applications/Utilities", NSHomeDirectory() + "/Applications"]

        for searchPath in searchPaths {
            // Try exact path first
            let exactPath = (searchPath as NSString).appendingPathComponent("\(name).app")
            if let bundle = Bundle(path: exactPath), let bundleId = bundle.bundleIdentifier {
                let displayName = bundle.infoDictionary?["CFBundleName"] as? String ?? name
                return AppEntry(bundleId: bundleId, name: displayName)
            }

            // Search for partial matches
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: searchPath) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let appName = item.replacingOccurrences(of: ".app", with: "")
                if appName.lowercased() == name.lowercased() ||
                   appName.lowercased().contains(name.lowercased()) ||
                   name.lowercased().contains(appName.lowercased()) {
                    let appPath = (searchPath as NSString).appendingPathComponent(item)
                    if let bundle = Bundle(path: appPath),
                       let bundleId = bundle.bundleIdentifier {
                        let displayName = bundle.infoDictionary?["CFBundleName"] as? String ?? appName
                        return AppEntry(bundleId: bundleId, name: displayName)
                    }
                }
            }
        }

        return nil
    }

    private func showDockAppPicker(for targetTable: NSTableView) {
        // Get running apps (these are the ones visible in Dock)
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }

        // Create popup menu
        let menu = NSMenu(title: "Select App from Dock")

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let name = app.localizedName else { continue }

            let item = NSMenuItem(title: name, action: #selector(dockAppSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ["bundleId": bundleId, "name": name, "tableTag": targetTable.tag]
            if let icon = app.icon {
                icon.size = NSSize(width: 16, height: 16)
                item.image = icon
            }
            menu.addItem(item)
        }

        // Add separator and installed apps option
        menu.addItem(NSMenuItem.separator())
        let moreItem = NSMenuItem(title: "More Apps...", action: #selector(showMoreApps(_:)), keyEquivalent: "")
        moreItem.target = self
        moreItem.representedObject = targetTable.tag
        menu.addItem(moreItem)

        // Show popup at mouse location
        let mouseLocation = NSEvent.mouseLocation
        if let window = view.window {
            let windowPoint = window.convertPoint(fromScreen: mouseLocation)
            menu.popUp(positioning: nil, at: windowPoint, in: view)
        }
    }

    @objc private func dockAppSelected(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any],
              let bundleId = info["bundleId"] as? String,
              let name = info["name"] as? String else { return }

        let app = AppEntry(bundleId: bundleId, name: name)

        if !modeApps.contains(where: { $0.bundleId == app.bundleId }) {
            modeApps.append(app)
            appsTableView.reloadData()
            updateEmptyState()
            saveCurrentMode()
            print("✅ DeskModes: Added %@ to mode apps", name)
        }
    }

    @objc private func showMoreApps(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an application to add"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier {
                let name = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent

                let app = AppEntry(bundleId: bundleId, name: name)

                if !modeApps.contains(where: { $0.bundleId == app.bundleId }) {
                    modeApps.append(app)
                    appsTableView.reloadData()
                    updateEmptyState()
                    saveCurrentMode()
                }
            }
        }
    }

    private func updateHoveredTable(at screenLocation: NSPoint) {
        guard let window = view.window else { return }

        let windowPoint = window.convertPoint(fromScreen: screenLocation)
        let viewPoint = view.convert(windowPoint, from: nil)

        // Check if over apps table
        let appsFrame = appsScrollView.frame
        if appsFrame.contains(viewPoint) {
            lastHoveredTable = appsTableView
            return
        }

        lastHoveredTable = nil
    }

    private func getAppFromDockPosition(_ position: NSPoint) -> AppEntry? {
        print("🔍 DeskModes: Getting app from Dock position (%.0f, %.0f)", position.x, position.y)

        // Try system-wide element first
        let systemWide = AXUIElementCreateSystemWide()
        var elementAtSystemPosition: AXUIElement?

        // Convert to screen coordinates (CGFloat to Float)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgY = Float(screenHeight - position.y)  // Convert back to CG coordinates

        let systemResult = AXUIElementCopyElementAtPosition(systemWide, Float(position.x), cgY, &elementAtSystemPosition)
        print("🔍 DeskModes: SystemWide query result: %d", systemResult.rawValue)

        if systemResult == .success, let element = elementAtSystemPosition {
            if let appEntry = extractAppFromElement(element) {
                return appEntry
            }
        }

        // Fallback: Find the Dock application and query it directly
        var dockApp: AXUIElement?
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps where app.bundleIdentifier == "com.apple.dock" {
            dockApp = AXUIElementCreateApplication(app.processIdentifier)
            print("🔍 DeskModes: Found Dock app with PID: %d", app.processIdentifier)
            break
        }

        guard let dock = dockApp else {
            print("❌ DeskModes: Could not find Dock app")
            return nil
        }

        // Try to get the list of Dock items
        var childrenValue: CFTypeRef?
        let childResult = AXUIElementCopyAttributeValue(dock, kAXChildrenAttribute as CFString, &childrenValue)
        print("🔍 DeskModes: Dock children query result: %d", childResult.rawValue)

        if childResult == .success, let children = childrenValue as? [AXUIElement] {
            print("🔍 DeskModes: Dock has %d children", children.count)

            for child in children {
                var roleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleValue)
                let role = roleValue as? String ?? "unknown"

                // Look for the persistent Dock (apps list)
                if role == "AXList" {
                    var listChildren: CFTypeRef?
                    AXUIElementCopyAttributeValue(child, kAXChildrenAttribute as CFString, &listChildren)

                    if let dockItems = listChildren as? [AXUIElement] {
                        print("🔍 DeskModes: Found Dock item list with %d items", dockItems.count)

                        for item in dockItems {
                            var posValue: CFTypeRef?
                            AXUIElementCopyAttributeValue(item, kAXPositionAttribute as CFString, &posValue)

                            if let posValue = posValue {
                                var point = CGPoint.zero
                                AXValueGetValue(posValue as! AXValue, .cgPoint, &point)

                                var sizeValue: CFTypeRef?
                                AXUIElementCopyAttributeValue(item, kAXSizeAttribute as CFString, &sizeValue)
                                var size = CGSize.zero
                                if let sizeValue = sizeValue {
                                    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                                }

                                // Check if position is within this item's bounds
                                let itemRect = CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
                                // Convert our position to CG coordinates for comparison
                                let cgPosition = CGPoint(x: position.x, y: screenHeight - position.y)

                                if itemRect.contains(cgPosition) {
                                    print("🎯 DeskModes: Found item at position!")
                                    if let appEntry = extractAppFromElement(item) {
                                        return appEntry
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        print("❌ DeskModes: No app found at Dock position")
        return nil
    }

    private func extractAppFromElement(_ element: AXUIElement) -> AppEntry? {
        var urlValue: CFTypeRef?
        var titleValue: CFTypeRef?
        var descValue: CFTypeRef?

        AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &urlValue)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)

        let title = titleValue as? String
        let desc = descValue as? String

        print("🔍 DeskModes: Element - title: %@, desc: %@", title ?? "nil", desc ?? "nil")

        // Try URL first
        if let url = urlValue as? URL ?? (urlValue as? String).flatMap({ URL(fileURLWithPath: $0) }) {
            if url.pathExtension == "app" {
                if let bundle = Bundle(url: url),
                   let bundleId = bundle.bundleIdentifier {
                    let name = bundle.infoDictionary?["CFBundleName"] as? String
                        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? url.deletingPathExtension().lastPathComponent
                    print("✅ DeskModes: Found app from URL: %@ (%@)", name, bundleId)
                    return AppEntry(bundleId: bundleId, name: name)
                }
            }
        }

        // Try title
        if let title = title, !title.isEmpty {
            print("🔍 DeskModes: Trying to find app by title: %@", title)
            return findAppByName(title)
        }

        // Try description
        if let desc = desc, !desc.isEmpty {
            print("🔍 DeskModes: Trying to find app by description: %@", desc)
            return findAppByName(desc)
        }

        return nil
    }

    private func addAppFromDock(_ app: AppEntry, to tableView: NSTableView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.modeApps.contains(where: { $0.bundleId == app.bundleId }) {
                self.modeApps.append(app)
                self.appsTableView.reloadData()
                self.saveCurrentMode()
                print("✅ Added \(app.name) to mode apps from Dock drag!")
            }
        }
    }

}

// MARK: - Icon Picker

final class IconPickerPopover: NSPopover {

    var onIconSelected: ((String) -> Void)?

    // Available mode icons (PNG files in ModeIcons folder)
    static let availableIcons = ["work_mode", "dev_mode", "ai_mode", "new_mode", "custom_mode_1", "custom_mode_2", "custom_mode_3"]

    override init() {
        super.init()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        let gridView = NSGridView()
        gridView.rowSpacing = 12
        gridView.columnSpacing = 12

        var buttons: [[NSView]] = []
        var currentRow: [NSView] = []

        for (index, iconName) in Self.availableIcons.enumerated() {
            let button = NSButton()
            button.bezelStyle = .regularSquare
            button.isBordered = false
            button.tag = index
            button.target = self
            button.action = #selector(iconSelected(_:))

            // Load icon from bundle
            if let iconPath = Bundle.main.path(forResource: iconName, ofType: "png", inDirectory: "ModeIcons"),
               let icon = NSImage(contentsOfFile: iconPath) {
                icon.size = NSSize(width: 40, height: 40)
                button.image = icon
            }

            button.setFrameSize(NSSize(width: 48, height: 48))

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

        // Container with padding
        let containerView = NSView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gridView)

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            gridView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            gridView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gridView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        let viewController = NSViewController()
        viewController.view = containerView
        // 4 buttons * 48 + 3 gaps * 12 + 32 padding = 192 + 36 + 32 = 260
        // 2 rows * 48 + 1 gap * 12 + 32 padding = 96 + 12 + 32 = 140
        viewController.view.setFrameSize(NSSize(width: 260, height: 144))

        contentViewController = viewController
        behavior = .transient
    }

    @objc private func iconSelected(_ sender: NSButton) {
        let iconName = Self.availableIcons[sender.tag]
        onIconSelected?(iconName)
        close()
    }

    // Helper to load mode icon image
    static func loadIcon(named name: String) -> NSImage? {
        // First try to load from ModeIcons folder
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

    // Helper to get default icon for a mode name
    static func defaultIconName(for modeName: String) -> String {
        let lowercased = modeName.lowercased()
        if lowercased.contains("dev") || lowercased.contains("code") || lowercased.contains("programming") {
            return "dev_mode"
        } else if lowercased.contains("ai") || lowercased.contains("claude") || lowercased.contains("chat") {
            return "ai_mode"
        } else if lowercased.contains("work") || lowercased.contains("office") || lowercased.contains("business") {
            return "work_mode"
        } else {
            return "new_mode"
        }
    }
}

// MARK: - App Search Popover

final class AppSearchPopover: NSPopover, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {

    var onAppSelected: ((AppEntry) -> Void)?

    /// Apps that should be shown as disabled with a reason
    var disabledApps: [String: String] = [:]  // bundleId -> reason

    private let searchField = NSTextField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()

    private var allApps: [AppEntry] = []
    private var filteredApps: [AppEntry] = []

    override init() {
        super.init()
        loadInstalledApps()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadInstalledApps() {
        // Load from all app directories including system apps
        let appsPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ]

        // Also add specific system apps that users might want
        let specificApps = [
            "/System/Library/CoreServices/Finder.app"
        ]

        // Load specific apps first
        for appPath in specificApps {
            if let bundle = Bundle(path: appPath),
               let bundleId = bundle.bundleIdentifier {
                let name = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                allApps.append(AppEntry(bundleId: bundleId, name: name))
            }
        }

        for appsPath in appsPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: appsPath) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let fullPath = (appsPath as NSString).appendingPathComponent(item)
                if let bundle = Bundle(path: fullPath),
                   let bundleId = bundle.bundleIdentifier {

                    // Skip LSUIElement apps (background/helper apps without UI)
                    if let isUIElement = bundle.infoDictionary?["LSUIElement"] as? Bool, isUIElement {
                        continue
                    }
                    // Also check for string "1" or "YES"
                    if let isUIElement = bundle.infoDictionary?["LSUIElement"] as? String,
                       isUIElement == "1" || isUIElement.lowercased() == "yes" {
                        continue
                    }

                    // Skip apps without a proper name (likely helpers)
                    let name = bundle.infoDictionary?["CFBundleName"] as? String
                        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? item.replacingOccurrences(of: ".app", with: "")

                    // Skip if name starts with . (hidden apps)
                    if name.hasPrefix(".") {
                        continue
                    }

                    allApps.append(AppEntry(bundleId: bundleId, name: name))
                }
            }
        }

        // Sort alphabetically and remove duplicates
        allApps = Array(Set(allApps)).sorted { $0.name.lowercased() < $1.name.lowercased() }
        filteredApps = allApps
    }

    private func setupContent() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 350))

        // Search field
        searchField.placeholderString = "Search apps..."
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(searchField)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 28
        tableView.target = self
        tableView.action = #selector(tableViewClicked)
        tableView.doubleAction = #selector(tableViewDoubleClicked)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("App"))
        column.width = 280
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        let viewController = NSViewController()
        viewController.view = containerView
        contentViewController = viewController
        behavior = .transient

        // Select first row when popover opens
        DispatchQueue.main.async { [weak self] in
            self?.selectFirstAvailableRow()
        }
    }

    @objc private func tableViewClicked() {
        // Single click just selects, don't confirm
    }

    @objc private func tableViewDoubleClicked() {
        confirmSelection()
    }

    private func selectFirstAvailableRow() {
        for row in 0..<filteredApps.count {
            let app = filteredApps[row]
            if disabledApps[app.bundleId] == nil {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                tableView.scrollRowToVisible(row)
                break
            }
        }
    }

    private func confirmSelection() {
        let row = tableView.selectedRow
        guard row >= 0 && row < filteredApps.count else { return }

        let app = filteredApps[row]
        guard disabledApps[app.bundleId] == nil else { return }

        onAppSelected?(app)
        close()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        let query = searchField.stringValue.lowercased()
        if query.isEmpty {
            filteredApps = allApps
        } else {
            filteredApps = allApps.filter { $0.name.lowercased().contains(query) }
        }
        tableView.reloadData()

        // Re-select first available row after filtering
        selectFirstAvailableRow()
    }

    /// Handle keyboard navigation: arrows + enter
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Arrow up - select previous row
            let currentRow = tableView.selectedRow
            var newRow = currentRow - 1

            // Skip disabled apps
            while newRow >= 0 {
                let app = filteredApps[newRow]
                if disabledApps[app.bundleId] == nil {
                    break
                }
                newRow -= 1
            }

            if newRow >= 0 {
                tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
                tableView.scrollRowToVisible(newRow)
            }
            return true
        }

        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Arrow down - select next row
            let currentRow = tableView.selectedRow
            var newRow = currentRow + 1

            // Skip disabled apps
            while newRow < filteredApps.count {
                let app = filteredApps[newRow]
                if disabledApps[app.bundleId] == nil {
                    break
                }
                newRow += 1
            }

            if newRow < filteredApps.count {
                tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
                tableView.scrollRowToVisible(newRow)
            }
            return true
        }

        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter - confirm selection
            confirmSelection()
            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape - close popover
            close()
            return true
        }

        return false
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredApps.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = filteredApps[row]
        let isDisabled = disabledApps[app.bundleId] != nil
        let disabledReason = disabledApps[app.bundleId]

        let cellId = NSUserInterfaceItemIdentifier("AppCell")
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

                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }

        // Show disabled reason if app is already added
        if isDisabled, let reason = disabledReason {
            cell?.textField?.stringValue = "\(app.name) (\(reason))"
            cell?.textField?.textColor = .tertiaryLabelColor
            cell?.imageView?.alphaValue = 0.5
        } else {
            cell?.textField?.stringValue = app.name
            cell?.textField?.textColor = .labelColor
            cell?.imageView?.alphaValue = 1.0
        }

        // Load app icon
        if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
            let icon = NSWorkspace.shared.icon(forFile: appPath.path)
            icon.size = NSSize(width: 20, height: 20)
            cell?.imageView?.image = icon
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let app = filteredApps[row]
        return disabledApps[app.bundleId] == nil
    }

}

// MARK: - Running Apps Popover (Multi-select)

final class RunningAppsPopover: NSPopover, NSTableViewDelegate, NSTableViewDataSource {

    var onAppsSelected: (([AppEntry]) -> Void)?
    var disabledApps: [String: String] = [:]

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let addButton = NSButton()

    private var runningApps: [AppEntry] = []
    private var selectedApps: Set<String> = []  // bundleIds

    override init() {
        super.init()
        loadRunningApps()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .compactMap { app -> AppEntry? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return AppEntry(bundleId: bundleId, name: name)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func setupContent() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 320))

        // Header label
        let headerLabel = NSTextField(labelWithString: "Currently running apps")
        headerLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerLabel)

        // Table view with checkboxes
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 28
        tableView.allowsMultipleSelection = true

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("App"))
        column.width = 260
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)

        // Add button
        addButton.title = "Add Selected"
        addButton.bezelStyle = .rounded
        addButton.target = self
        addButton.action = #selector(addSelectedClicked)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.isEnabled = false
        containerView.addSubview(addButton)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -8),

            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            addButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        let viewController = NSViewController()
        viewController.view = containerView
        contentViewController = viewController
        behavior = .transient
    }

    @objc private func addSelectedClicked() {
        let apps = runningApps.filter { selectedApps.contains($0.bundleId) }
        onAppsSelected?(apps)
        close()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return runningApps.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = runningApps[row]
        let isDisabled = disabledApps[app.bundleId] != nil
        let disabledReason = disabledApps[app.bundleId]

        let container = NSView()

        // Checkbox
        let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxClicked(_:)))
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.tag = row
        checkbox.state = selectedApps.contains(app.bundleId) ? .on : .off
        checkbox.isEnabled = !isDisabled
        container.addSubview(checkbox)

        // App icon
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
            let icon = NSWorkspace.shared.icon(forFile: appPath.path)
            icon.size = NSSize(width: 18, height: 18)
            iconView.image = icon
        }
        iconView.alphaValue = isDisabled ? 0.5 : 1.0
        container.addSubview(iconView)

        // App name label
        let label = NSTextField(labelWithString: isDisabled ? "\(app.name) (\(disabledReason ?? ""))" : app.name)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.textColor = isDisabled ? .tertiaryLabelColor : .labelColor
        container.addSubview(label)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            checkbox.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            iconView.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    @objc private func checkboxClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row < runningApps.count else { return }
        let app = runningApps[row]

        if sender.state == .on {
            selectedApps.insert(app.bundleId)
        } else {
            selectedApps.remove(app.bundleId)
        }

        addButton.isEnabled = !selectedApps.isEmpty
        addButton.title = selectedApps.count > 0 ? "Add \(selectedApps.count) App\(selectedApps.count == 1 ? "" : "s")" : "Add Selected"
    }
}
