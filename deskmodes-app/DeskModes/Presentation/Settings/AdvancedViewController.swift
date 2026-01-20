import Cocoa

/// Preferences section for advanced settings
final class AdvancedViewController: NSViewController {

    // MARK: - Properties

    private let forceCloseCheckbox = NSButton(checkboxWithTitle: "Force close apps instead of quitting gracefully", target: nil, action: nil)
    private let forceCloseHelpLabel = NSTextField(wrappingLabelWithString: "")

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
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
        let headerLabel = NSTextField(labelWithString: "Advanced")
        headerLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        // Warning icon and text
        let warningIcon = NSImageView()
        warningIcon.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")
        warningIcon.contentTintColor = .systemYellow
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningIcon)

        let warningText = NSTextField(labelWithString: "These settings may cause unexpected behavior. Use with caution.")
        warningText.font = NSFont.systemFont(ofSize: 11)
        warningText.textColor = .secondaryLabelColor
        warningText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningText)

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)

        // App Closing section
        let closingHeader = NSTextField(labelWithString: "App Closing Behavior")
        closingHeader.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        closingHeader.textColor = .secondaryLabelColor
        closingHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closingHeader)

        forceCloseCheckbox.target = self
        forceCloseCheckbox.action = #selector(forceCloseChanged)
        forceCloseCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(forceCloseCheckbox)

        forceCloseHelpLabel.stringValue = "This may cause unsaved data to be lost. Recommended only for advanced users who need apps to close immediately without confirmation dialogs."
        forceCloseHelpLabel.font = NSFont.systemFont(ofSize: 11)
        forceCloseHelpLabel.textColor = .tertiaryLabelColor
        forceCloseHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(forceCloseHelpLabel)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            // Warning
            warningIcon.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            warningIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            warningIcon.widthAnchor.constraint(equalToConstant: 16),
            warningIcon.heightAnchor.constraint(equalToConstant: 16),

            warningText.centerYAnchor.constraint(equalTo: warningIcon.centerYAnchor),
            warningText.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 6),
            warningText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Separator
            separator.topAnchor.constraint(equalTo: warningIcon.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // App Closing section
            closingHeader.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 20),
            closingHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            forceCloseCheckbox.topAnchor.constraint(equalTo: closingHeader.bottomAnchor, constant: 12),
            forceCloseCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            forceCloseCheckbox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            forceCloseHelpLabel.topAnchor.constraint(equalTo: forceCloseCheckbox.bottomAnchor, constant: 8),
            forceCloseHelpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding + 20),
            forceCloseHelpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    private func loadSettings() {
        let config = ConfigStore.shared.config
        forceCloseCheckbox.state = config.forceCloseApps ? .on : .off
    }

    @objc private func forceCloseChanged() {
        ConfigStore.shared.setForceCloseApps(forceCloseCheckbox.state == .on)
    }
}
