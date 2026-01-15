# DeskModes

## 1. What DeskModes Is

DeskModes is a native macOS menu bar productivity utility that reduces app clutter and cognitive overload when switching between different work contexts. It controls app lifecycle (open/close) with a clean UX, allowing users to define "modes" that automatically close irrelevant apps and open the ones needed for a specific task.

**Key characteristics:**
- Menu bar app (no Dock icon)
- Native macOS app built with Swift and AppKit
- Requires macOS 13+
- Uses Apple Events for safe app termination

## 2. Mental Model (Core Concepts)

DeskModes uses a **simplified two-concept model**:

### 1. Global "Always Open" Apps
Apps that are **NEVER closed**, regardless of the selected mode.
- Examples: WhatsApp, Telegram, Spotify, Chrome
- This list is global and shared across all modes
- Perfect for apps you always want running

### 2. Apps per Mode
Each mode defines the set of apps that should be open when that mode is active.
- If an app is **not** in Global Always Open AND **not** in the current mode's app list → it gets closed (safe quit)

### Behavior Rules

| App Location | When Mode Switches |
|--------------|-------------------|
| In Global "Always Open" | **Never closed** - stays open always |
| In current mode's apps | **Kept open** if running, **launched** if not |
| Not in either list | **Safe quit** (never force quit) |

### Effective Allowed Apps Formula
```
effectiveAllowedApps = globalAlwaysOpen ∪ modeApps
```

Any running app NOT in `effectiveAllowedApps` will be safely closed.

### Why This Model
- Users think in terms of "what should be open in this mode"
- No redundancy or cognitive overload
- Simple formula: **Global baseline + per-mode intent = final state**

## 3. MVP Scope

### In Scope

- Menu bar application with mode selection panel
- Customizable modes (Work, Dev, AI as defaults)
- Global "Always Open" apps list
- Single apps list per mode
- Safe quit for apps not in allowed lists
- App launching when switching modes
- Preferences UI for customization
- Console-based logging
- Clean Architecture implementation

### Out of Scope

- iCloud sync
- AI prompt sending
- Dock manipulation
- Calendar triggers / automatic scheduling
- Window positioning (deferred)
- Subscriptions / monetization
- Marketing / onboarding
- Project path opening in Dev mode (placeholder only)

## 4. Architecture Overview

DeskModes follows Clean Architecture with a DDD mindset, organized into four layers:

```
+-------------------------------------------------------------+
|                      Presentation                            |
|  (MenuBarController, ModePanel, StatusItem)                 |
|  Responsibility: UI components, user interaction            |
+-------------------------------------------------------------+
|                      Application                             |
|  (ModeManager, AppStateManager, ModeSwitchUseCase)          |
|  Responsibility: Use cases, orchestration, state management |
+-------------------------------------------------------------+
|                        Domain                                |
|  (Mode, AppIdentifier, AppRule, GlobalAllowList,            |
|   WindowLayoutEntry)                                         |
|  Responsibility: Business entities, pure Swift, no deps     |
+-------------------------------------------------------------+
|                     Infrastructure                           |
|  (AppLister, AppCloser, AppLauncher, WindowLayoutManager,   |
|   IDELauncher, Logger)                                       |
|  Responsibility: System APIs, external dependencies         |
+-------------------------------------------------------------+
```

**Key Principle:** The Domain layer must NOT depend on AppKit, Accessibility APIs, or any system frameworks. It contains only pure Swift types and business logic.

### Layer Responsibilities

| Layer | Depends On | Contains |
|-------|-----------|----------|
| Presentation | Application, Domain | UI controllers, views, menu bar items |
| Application | Domain | Use cases, managers, orchestration logic |
| Domain | Nothing | Entities, value objects, business rules |
| Infrastructure | Domain | System integrations, APIs, logging |

## 5. Domain Model

### AppIdentifier (Value Object)

Uniquely identifies a macOS application.

```swift
struct AppIdentifier: Equatable, Hashable {
    let bundleId: String      // e.g., "com.apple.Safari"
    let displayName: String   // e.g., "Safari"
}
```

### Mode (Entity)

Represents a work context with its associated apps. **Single unified apps list.**

```swift
struct Mode {
    let id: String
    let name: String
    let icon: String
    let shortcut: String?
    let apps: [AppIdentifier]                // Apps for this mode (kept open + launched)
    let windowLayouts: [WindowLayoutEntry]?  // Optional positioning (future)
    let projectPath: String?                 // Dev mode only (future)
}
```

### GlobalAllowList (Entity)

Apps that are **never closed**, regardless of mode.

```swift
struct GlobalAllowList {
    let apps: [AppIdentifier]

    func isProtected(_ bundleId: String) -> Bool
}
```

### AppConfig (Root Configuration)

The root configuration stored in JSON.

```swift
struct AppConfig {
    var globalAllowList: [AppEntry]  // Global "Always Open" apps
    var modes: [ModeConfig]          // User's modes
}
```

### WindowLayoutEntry (Value Object)

Placeholder for future window positioning functionality.

```swift
struct WindowLayoutEntry {
    let appIdentifier: AppIdentifier
    let frame: WindowFrame
}
```

## 6. Mode Switch Flow

When a user selects a mode, the following sequence executes:

```
User selects mode from menu bar
            |
            v
+------------------------------------------+
| 1. LIST RUNNING APPS                     |
|    - Query all running user-facing apps  |
|    - Ignore system/background agents     |
+------------------------------------------+
            |
            v
+------------------------------------------+
| 2. EVALUATE EACH APP                     |
|    For each running app:                 |
|    - Is it in Global "Always Open"? KEEP |
|    - Is it in mode.apps? -> KEEP         |
|    - Otherwise -> SAFE QUIT              |
+------------------------------------------+
            |
            v
+------------------------------------------+
| 3. HANDLE QUIT FAILURES                  |
|    If app refuses (unsaved changes):     |
|    - Skip the app                        |
|    - Log skip reason                     |
|    - Continue with remaining apps        |
+------------------------------------------+
            |
            v
+------------------------------------------+
| 4. LAUNCH MODE APPS                      |
|    For each app in mode.apps:            |
|    - If already running -> skip          |
|    - If not running -> Launch app        |
+------------------------------------------+
            |
            v
+------------------------------------------+
| 5. LOG SUMMARY                           |
|    Report:                               |
|    - Apps closed                         |
|    - Apps skipped (refused to quit)      |
|    - Apps opened                         |
+------------------------------------------+
```

### Safety Rules

- **SAFE quit only**: Uses terminate / Cmd+Q behavior via Apple Events
- **Never force quit**: Respects app's unsaved document dialogs
- **Non-blocking**: Individual app failures do not block the mode switch
- **Logging**: All operations are logged for debugging

## 7. Required Permissions

### Apple Events / Automation

**What:** Permission to send Apple Events to other applications.

**Why:** Required to request apps to quit safely (equivalent to Cmd+Q). The system will prompt the user to grant permission the first time DeskModes attempts to close an app.

**How it works:**
- DeskModes sends a "quit" Apple Event to target apps
- Apps can refuse if they have unsaved changes
- User sees the standard "Save changes?" dialog

### Accessibility API (Future)

**What:** Permission to control UI elements of other applications.

**Why:** Required for window positioning functionality (not in MVP).

**Note:** Not required for MVP. Will be implemented when window layout features are added.

## 8. Current Status

### Implemented

- [x] Project scaffold (Xcode project, menu bar app, no Dock icon)
- [x] Folder structure following Clean Architecture
- [x] Logger utility (console-based)
- [x] PROJECT.md documentation

### Domain Layer

- [x] AppIdentifier value object
- [x] Mode entity with single apps list
- [x] GlobalAllowList entity
- [x] AppConfig (root configuration)
- [x] WindowLayoutEntry placeholder

### Infrastructure Layer

- [x] AppLister (list running user-facing apps)
- [x] AppCloser (safe quit via Apple Events)
- [x] AppLauncher (open apps)
- [x] ConfigStore (JSON persistence)

### Application Layer

- [x] ModeManager (mode storage/retrieval)
- [x] ModeSwitchUseCase (orchestrates mode switch)
- [x] Default modes (Work, Dev, AI)

### Presentation Layer

- [x] MenuBarController with NSStatusItem
- [x] Mode selection menu
- [x] **Preferences UI** (Settings window)
  - [x] Sidebar with modes list
  - [x] Global "Always Open" section with custom header
  - [x] Mode detail view (icon, name, shortcut, apps)
  - [x] Add/remove apps functionality
  - [x] Add/remove modes functionality

### Integration

- [x] End-to-end mode switch working
- [x] All components wired together
- [x] JSON config persistence

### Pending (Future)

- [ ] Window positioning (WindowLayoutManager)
- [ ] IDE launcher (Dev mode project opening)
- [ ] Keyboard shortcuts (global hotkeys)
- [ ] Mode persistence (remember last active mode)

## 9. How to Build and Run

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later

### Build Steps

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DeskModes
   ```

2. Open the Xcode project:
   ```bash
   open DeskModes.xcodeproj
   ```

3. Select the DeskModes scheme and your Mac as the target device.

4. Build and run (Cmd+R).

### First Run

On first run, DeskModes will appear in the menu bar (no Dock icon). When you switch modes for the first time, macOS will prompt you to grant Automation permission.

### Development Notes

- The app uses `LSUIElement = YES` in Info.plist to hide the Dock icon
- Logs are output to the console (View > Console in Xcode or use Console.app)
- Configuration is stored in `~/Library/Application Support/DeskModes/config.json`
- Default modes (Work, Dev, AI) are created on first launch

## 10. Known Limitations

### App Detection

- **Background agents excluded**: Apps running as background agents (LSBackgroundOnly) are not detected or closed.
- **Bundle ID required**: Apps without a valid bundle identifier cannot be managed.

### Safe Quit Behavior

- **Unsaved changes block quit**: Apps with unsaved documents will show their save dialog and may refuse to quit if the user cancels.
- **Hung apps not closed**: If an app is unresponsive, the safe quit will timeout and the app will be skipped.
- **No force quit**: DeskModes will never force terminate an app; users must handle hung apps manually.

### Mode Switching

- **Sequential execution**: Apps are closed and opened sequentially, not in parallel.
- **No rollback**: If a mode switch partially fails, there is no automatic rollback to the previous state.

### Platform Limitations

- **macOS only**: No iOS, iPadOS, or other platform support.
- **Intel + Apple Silicon**: Universal binary required for both architectures.

## 11. Next Steps

After MVP completion, the following features are prioritized for future iterations:

### Immediate Post-MVP

1. **Window Positioning**: Implement WindowLayoutManager to position app windows when switching modes.
2. **Settings UI**: Allow users to customize modes, allow lists, and app associations.
3. **Mode Persistence**: Remember the last active mode and restore on app launch.

### Medium-Term

4. **Project Path Support**: Open specific projects in IDEs when switching to Dev mode.
5. **Custom Modes**: Allow users to create, edit, and delete custom modes.
6. **iCloud Sync**: Synchronize mode configurations across devices.

### Long-Term

7. **Calendar Integration**: Automatically switch modes based on calendar events.
8. **Shortcuts Integration**: Expose mode switching via macOS Shortcuts.
9. **Keyboard Shortcuts**: Global hotkeys for quick mode switching.
10. **Notification Center**: Show mode switch summaries as notifications.

### Quality Improvements

- Unit tests for domain and application layers
- Integration tests for infrastructure layer
- UI tests for presentation layer
- Performance profiling for mode switches with many apps
