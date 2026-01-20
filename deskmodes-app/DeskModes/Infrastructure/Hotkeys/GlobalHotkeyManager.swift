import Cocoa
import Carbon

/// Manages global hotkeys using Carbon API (RegisterEventHotKey)
/// This is the reliable way to capture global keyboard shortcuts on macOS
final class GlobalHotkeyManager {

    static let shared = GlobalHotkeyManager()

    // MARK: - Properties

    private var hotKeyRef: EventHotKeyRef?
    private var reapplyHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Callbacks
    var onModeSwitcherTriggered: (() -> Void)?
    var onReapplyTriggered: (() -> Void)?

    // Hotkey IDs
    private let modeSwitcherHotKeyID = EventHotKeyID(signature: OSType(0x444D5357), id: 1) // "DMSW"
    private let reapplyHotKeyID = EventHotKeyID(signature: OSType(0x444D5357), id: 2)       // "DMSW"

    // MARK: - Initialization

    private init() {
        installEventHandler()
    }

    deinit {
        unregisterAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    // MARK: - Public API

    func updateHotkeys() {
        let config = ConfigStore.shared.config

        // Unregister existing hotkeys
        unregisterAll()

        // Register mode switcher hotkey if set
        if let shortcut = config.modeSwitcherShortcut {
            registerModeSwitcherHotkey(shortcut)
        }

        // Register reapply hotkey if set
        if let shortcut = config.reapplyShortcut {
            registerReapplyHotkey(shortcut)
        }
    }

    // MARK: - Private Methods

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            return manager.handleHotKeyEvent(event!)
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        print("✅ Carbon event handler installed")
    }

    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let error = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard error == noErr else { return error }

        DispatchQueue.main.async { [weak self] in
            if hotKeyID.id == 1 {
                print("🎹 Mode switcher hotkey triggered!")
                self?.onModeSwitcherTriggered?()
            } else if hotKeyID.id == 2 {
                print("🎹 Reapply hotkey triggered!")
                self?.onReapplyTriggered?()
            }
        }

        return noErr
    }

    private func registerModeSwitcherHotkey(_ shortcut: KeyboardShortcut) {
        let carbonKeyCode = UInt32(shortcut.keyCode)
        let carbonModifiers = convertToCarbonModifiers(shortcut.modifiers)

        var hotKeyID = modeSwitcherHotKeyID

        let status = RegisterEventHotKey(
            carbonKeyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            print("✅ Mode switcher hotkey registered: \(shortcut.displayString)")
        } else {
            print("❌ Failed to register mode switcher hotkey: \(status)")
        }
    }

    private func registerReapplyHotkey(_ shortcut: KeyboardShortcut) {
        let carbonKeyCode = UInt32(shortcut.keyCode)
        let carbonModifiers = convertToCarbonModifiers(shortcut.modifiers)

        var hotKeyID = reapplyHotKeyID

        let status = RegisterEventHotKey(
            carbonKeyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reapplyHotKeyRef
        )

        if status == noErr {
            print("✅ Reapply hotkey registered: \(shortcut.displayString)")
        } else {
            print("❌ Failed to register reapply hotkey: \(status)")
        }
    }

    private func unregisterAll() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = reapplyHotKeyRef {
            UnregisterEventHotKey(ref)
            reapplyHotKeyRef = nil
        }
    }

    private func convertToCarbonModifiers(_ modifiers: UInt) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        var carbonMods: UInt32 = 0

        if flags.contains(.command) {
            carbonMods |= UInt32(cmdKey)
        }
        if flags.contains(.option) {
            carbonMods |= UInt32(optionKey)
        }
        if flags.contains(.control) {
            carbonMods |= UInt32(controlKey)
        }
        if flags.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
        }

        return carbonMods
    }
}
