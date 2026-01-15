# Settings UI Design - DeskModes

**Date:** 2026-01-12
**Status:** Approved

## Overview

Native macOS Settings UI for configuring DeskModes. Apple-style design with master-detail layout.

## User Decisions

| Question | Decision |
|----------|----------|
| How to open settings | Menu → "Preferences..." (⌘,) |
| Window structure | Single view master-detail (like Mail/Notes) |
| App selection | Hybrid: installed apps list + manual add |
| Global Allow List | Special "Global" mode, always first |
| Mode features | Name + apps + keyboard shortcut + icon/emoji |

## Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ● ● ●                    DeskModes                          │
├────────────────┬────────────────────────────────────────────┤
│                │                                            │
│  🌐 Global     │   Mode: Work                               │
│  ─────────     │   ─────────────────────────────────        │
│  💼 Work    ←  │   Icon: 💼  Name: [Work............]       │
│  💻 Dev        │   Shortcut: [⌘⇧1] [Record]                 │
│  🤖 AI         │                                            │
│                │   ─────────────────────────────────        │
│                │   Apps to Keep Open:                       │
│                │   ┌────────────────────────────────┐       │
│                │   │ ☑ Safari                       │       │
│                │   │ ☑ Notes                        │       │
│                │   │ ☑ Reminders                    │       │
│                │   │ ☐ Mail                         │       │
│                │   └────────────────────────────────┘       │
│                │   [+ Add App...]                           │
│                │                                            │
│  ─────────     │   ─────────────────────────────────        │
│  [+] [-]       │   Apps to Open When Switching:             │
│                │   Safari, Notes                    [Edit]  │
│                │                                            │
└────────────────┴────────────────────────────────────────────┘
```

**Window size:** ~600x450 px

## Components

### Sidebar (Left)
- `NSTableView` with single selection
- Icon + mode name
- "Global" with 🌐 icon, fixed, not deletable
- Drag & drop to reorder (except Global)
- Double-click to rename inline
- +/- buttons at bottom

### Detail Panel (Right)

| Component | AppKit Type | Behavior |
|-----------|-------------|----------|
| Icon picker | `NSButton` with popover | Click opens emoji grid |
| Name field | `NSTextField` | Direct edit, max 20 chars |
| Shortcut | Custom `NSButton` | Click → "Press shortcut..." → capture keys |
| Apps list | `NSTableView` with checkbox | Scrollable, search integrated |
| Add App | `NSButton` | Opens `NSOpenPanel` filtered to .app |

### Interactions
- Auto-save on change (no "Save" button)
- New mode: name "New Mode", no apps, no shortcut
- Delete mode: confirmation only if has apps configured
- Shortcut conflicts: warning if already in use

## Data Persistence

**Location:** `~/Library/Application Support/DeskModes/config.json`

**Schema:**
```json
{
  "version": 1,
  "globalAllowList": [
    {"bundleId": "net.whatsapp.WhatsApp", "name": "WhatsApp"},
    {"bundleId": "ru.keepcoder.Telegram", "name": "Telegram"}
  ],
  "modes": [
    {
      "id": "work-uuid-1234",
      "name": "Work",
      "icon": "💼",
      "shortcut": "cmd+shift+1",
      "allowList": [
        {"bundleId": "com.apple.Safari", "name": "Safari"},
        {"bundleId": "com.apple.Notes", "name": "Notes"}
      ],
      "appsToOpen": [
        {"bundleId": "com.apple.Safari", "name": "Safari"}
      ]
    }
  ]
}
```

**Behavior:**
- No config.json → create with default modes (Work, Dev, AI)
- Auto-save on change (500ms debounce)
- Backup before save: `config.json.bak`
- Corrupted JSON → load backup or defaults

## File Architecture

```
DeskModes/
├── Domain/
│   └── Entities/
│       └── Config.swift           # Codable model for JSON
│
├── Infrastructure/
│   └── Persistence/
│       └── ConfigStore.swift      # Read/write config.json
│
└── Presentation/
    └── Settings/
        ├── SettingsWindowController.swift   # NSWindowController
        ├── SettingsViewController.swift     # Main view
        ├── ModesSidebarController.swift     # Left sidebar
        ├── ModeDetailViewController.swift   # Right panel
        ├── AppPickerViewController.swift    # Apps list + add
        └── ShortcutRecorder.swift           # Shortcut capture
```

## Integration

- `MenuBarController` adds "Preferences..." item (⌘,)
- Open Preferences → `SettingsWindowController.showWindow()`
- Config change → `ConfigStore` notifies `ModeManager`
- `ModeManager` reads modes from `ConfigStore` (no more hardcoded)

## External Dependencies

None. All native AppKit.
