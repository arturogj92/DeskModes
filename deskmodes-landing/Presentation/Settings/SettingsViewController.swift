import Cocoa

/// Main view controller for Settings, containing sidebar and detail panel.
final class SettingsViewController: NSViewController {

    // MARK: - Properties

    private let splitView = NSSplitView()
    private let sidebarController = ModesSidebarController()
    private let detailController = ModeDetailViewController()

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 650, height: 480))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplitView()
        setupChildControllers()
        setupBindings()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        print("🟣 SettingsViewController.viewWillAppear called")
        // Always reload the current mode when the window appears
        // This handles both initial load and window reopen
        sidebarController.reloadAndSelectFirstMode()
    }

    // MARK: - Setup

    private func setupSplitView() {
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(splitView)

        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: view.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splitView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupChildControllers() {
        // Add sidebar
        addChild(sidebarController)
        let sidebarView = sidebarController.view
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(sidebarView)

        // Add detail
        addChild(detailController)
        let detailView = detailController.view
        detailView.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(detailView)

        // Set sidebar width constraints
        NSLayoutConstraint.activate([
            sidebarView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            sidebarView.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])

        // Set initial position
        splitView.setPosition(180, ofDividerAt: 0)
    }

    private func setupBindings() {
        sidebarController.onModeSelected = { [weak self] mode, isGlobal in
            if isGlobal {
                self?.detailController.showGlobalAllowList()
            } else if let mode = mode {
                self?.detailController.showMode(mode)
            }
        }

        // Refresh sidebar when mode name/icon changes
        detailController.onModeChanged = { [weak self] in
            self?.sidebarController.refreshModeList()
        }

        sidebarController.onModeAdded = { [weak self] in
            // Select the newly added mode
            let lastIndex = ConfigStore.shared.config.modes.count - 1
            self?.sidebarController.selectMode(at: lastIndex, isGlobal: false)

            // Auto-focus name field for immediate renaming
            DispatchQueue.main.async {
                self?.detailController.focusNameField()
            }
        }
    }
}

// MARK: - NSSplitViewDelegate

extension SettingsViewController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 150
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 250
    }
}
