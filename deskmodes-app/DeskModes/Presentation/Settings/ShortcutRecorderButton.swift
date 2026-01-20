import Cocoa

/// Represents a keyboard shortcut with modifiers and key
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt  // NSEvent.ModifierFlags.rawValue

    /// Returns display string like "⇧⌘R"
    var displayString: String {
        var parts: [String] = []

        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }

        // Convert keyCode to character
        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        return parts.joined()
    }

    /// Check if this shortcut matches an event
    func matches(_ event: NSEvent) -> Bool {
        guard event.keyCode == keyCode else { return false }

        let requiredMods = NSEvent.ModifierFlags(rawValue: modifiers).intersection([.control, .option, .shift, .command])
        let eventMods = event.modifierFlags.intersection([.control, .option, .shift, .command])

        return eventMods == requiredMods
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".",
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 105: "F13", 107: "F14",
            109: "F10", 111: "F12", 113: "F15", 118: "F4",
            119: "F2", 120: "F1",
            122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return keyMap[keyCode]
    }

    /// Default reapply shortcut: ⇧⌘R
    static var defaultReapply: KeyboardShortcut {
        KeyboardShortcut(
            keyCode: 15, // R
            modifiers: NSEvent.ModifierFlags([.shift, .command]).rawValue
        )
    }
}

/// Button that records keyboard shortcuts
final class ShortcutRecorderButton: NSButton {

    // MARK: - Properties

    private var isRecording = false
    private var currentShortcut: KeyboardShortcut?
    private var localMonitor: Any?

    /// Called when shortcut changes
    var onShortcutChanged: ((KeyboardShortcut?) -> Void)?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        stopRecording()
    }

    private func setup() {
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(buttonClicked)
        updateTitle()
    }

    // MARK: - Public API

    func setShortcut(_ shortcut: KeyboardShortcut?) {
        currentShortcut = shortcut
        updateTitle()
    }

    func getShortcut() -> KeyboardShortcut? {
        return currentShortcut
    }

    // MARK: - Actions

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        title = "Type shortcut..."

        // Start monitoring keyboard
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }

        // Make button first responder to capture keys
        window?.makeFirstResponder(self)
    }

    private func stopRecording() {
        isRecording = false

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        updateTitle()
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Escape cancels recording
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        // Delete/Backspace clears the shortcut
        if event.keyCode == 51 {
            currentShortcut = nil
            onShortcutChanged?(nil)
            stopRecording()
            return
        }

        // Need at least one modifier (except for function keys)
        let modifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])
        let isFunctionKey = event.keyCode >= 96 && event.keyCode <= 122

        if modifiers.isEmpty && !isFunctionKey {
            // Flash the button to indicate invalid
            return
        }

        // Create the shortcut
        let shortcut = KeyboardShortcut(
            keyCode: event.keyCode,
            modifiers: modifiers.rawValue
        )

        currentShortcut = shortcut
        onShortcutChanged?(shortcut)
        stopRecording()
    }

    private func updateTitle() {
        if let shortcut = currentShortcut {
            title = shortcut.displayString
        } else {
            title = "Click to set"
        }
    }

    // MARK: - First Responder

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if isRecording {
            handleKeyEvent(event)
        } else {
            super.keyDown(with: event)
        }
    }
}
