# DeskModes - Design Document

## Overview

**DeskModes** is a native macOS menu bar productivity utility that reduces app clutter and cognitive overload when switching between different work contexts.

**Core Value Proposition:** Control app lifecycle (open/close) with a clean UX - NOT a window manager clone.

## Tech Stack

- Swift
- AppKit (NOT SwiftUI)
- macOS 13+
- Menu bar app (NSStatusItem)
- No Dock icon
- Apple Events + Accessibility API

## Architecture

### Clean Architecture with DDD Mindset

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation                            │
│  (MenuBarController, ModePanel, StatusItem)                 │
├─────────────────────────────────────────────────────────────┤
│                      Application                             │
│  (ModeManager, AppStateManager, ModeSwitchUseCase)          │
├─────────────────────────────────────────────────────────────┤
│                        Domain                                │
│  (Mode, AppIdentifier, AppRule, GlobalAllowList,            │
│   WindowLayoutEntry)                                         │
├─────────────────────────────────────────────────────────────┤
│                     Infrastructure                           │
│  (AppLister, AppCloser, AppLauncher, WindowLayoutManager,   │
│   IDELauncher, Logger)                                       │
└─────────────────────────────────────────────────────────────┘
```

**Key Principle:** Domain must NOT depend on AppKit, Accessibility, or system APIs.

## Domain Model

### Entities

1. **Mode** - A work context (Work, Dev, AI)
   - `id: String`
   - `name: String`
   - `allowList: [AppIdentifier]` - Apps that stay open
   - `appsToOpen: [AppIdentifier]` - Apps to launch
   - `windowLayouts: [WindowLayoutEntry]?` - Optional positioning
   - `projectPath: String?` - Dev mode only

2. **AppIdentifier** - Unique app identification
   - `bundleId: String`
   - `displayName: String`

3. **AppRule** - Defines behavior for an app
   - `appIdentifier: AppIdentifier`
   - `action: AppAction` (keep, close, open)

4. **GlobalAllowList** - Apps NEVER closed
   - `apps: [AppIdentifier]`

5. **WindowLayoutEntry** - Window positioning
   - `appIdentifier: AppIdentifier`
   - `frame: WindowFrame` (x, y, width, height)

## Mode Switch Flow

```
User selects mode
       ↓
┌──────────────────────────────────────┐
│ 1. List all running user-facing apps │
│    (ignore system/background agents) │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 2. For each running app:             │
│    - Check Global Allow List         │
│    - Check Mode Allow List           │
│    - If in neither → SAFE quit       │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 3. If app refuses (unsaved):         │
│    - Skip it                         │
│    - Log skip reason                 │
│    - Continue flow                   │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 4. Open apps from mode.appsToOpen    │
│    that are not running              │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 5. Log summary:                      │
│    - Closed apps                     │
│    - Skipped apps                    │
│    - Opened apps                     │
└──────────────────────────────────────┘
```

## First Iteration Tasks

### Phase 1: Project Foundation
- [x] Task 1.1: Create Xcode project scaffold (macOS app, menu bar, no Dock icon)
- [x] Task 1.2: Create folder structure following Clean Architecture
- [x] Task 1.3: Create Logger utility (console-based)
- [x] Task 1.4: Create PROJECT.md documentation

### Phase 2: Domain Layer
- [x] Task 2.1: Implement AppIdentifier value object
- [x] Task 2.2: Implement Mode entity
- [x] Task 2.3: Implement GlobalAllowList
- [x] Task 2.4: Implement WindowLayoutEntry (placeholder for future)

### Phase 3: Infrastructure Layer
- [x] Task 3.1: Implement AppLister (list running user-facing apps)
- [x] Task 3.2: Implement AppCloser (safe quit via Apple Events)
- [x] Task 3.3: Implement AppLauncher (open apps)

### Phase 4: Application Layer
- [x] Task 4.1: Implement ModeManager (mode storage/retrieval)
- [x] Task 4.2: Implement ModeSwitchUseCase (orchestrates mode switch)
- [x] Task 4.3: Wire up hardcoded modes (Work, Dev, AI) - included in 4.1

### Phase 5: Presentation Layer
- [x] Task 5.1: Implement MenuBarController with NSStatusItem
- [x] Task 5.2: Implement ModePanel (shows available modes) - integrated into MenuBarController
- [x] Task 5.3: Connect panel to ModeSwitchUseCase - integrated into MenuBarController

### Phase 6: Integration & Testing
- [x] Task 6.1: Fix protocol duplication (ModeManaging)
- [x] Task 6.2: Update Xcode project with all Swift files
- [x] Task 6.3: Update PROJECT.md with final status

## Hardcoded Modes (MVP)

### Work Mode
```swift
allowList: ["com.apple.Safari", "com.apple.Notes", "com.apple.reminders"]
appsToOpen: ["com.apple.Safari"]
```

### Dev Mode
```swift
allowList: ["com.todesktop.230313mzl4w4u92", "com.microsoft.VSCode", "com.apple.Terminal"]
appsToOpen: ["com.todesktop.230313mzl4w4u92"] // Cursor
projectPath: optional
```

### AI Mode
```swift
allowList: ["com.openai.chat", "com.anthropic.claudefordesktop"]
appsToOpen: ["com.anthropic.claudefordesktop"]
```

### Global Allow List
```swift
["net.whatsapp.WhatsApp", "ru.keepcoder.Telegram", "com.google.Chrome"]
```

## Required Permissions

1. **Accessibility API** - For window positioning (future)
2. **Apple Events / Automation** - For safe quit via AppleScript/Apple Events

## Safety Rules

- SAFE quit only (terminate / Cmd+Q behavior)
- Never force quit
- Never block mode switch if one app fails
- Continue execution on individual failures
- Log all operations

## Out of Scope (MVP)

- Settings UI
- Sync / iCloud
- AI prompt sending
- Dock manipulation
- Calendar triggers
- Automatic scheduling
- Subscriptions
- Marketing
- Onboarding
- Window positioning (deferred until core works)

## Summary

### Execution Complete ✓

**All 18 tasks completed successfully across 6 phases.**

#### Phase 1: Project Foundation (4 tasks)
- Created Xcode project scaffold with menu bar configuration
- Established Clean Architecture folder structure
- Implemented Logger utility for console-based logging
- Created comprehensive PROJECT.md documentation

#### Phase 2: Domain Layer (4 tasks)
- AppIdentifier: Value object for app identification
- Mode: Entity representing work contexts
- GlobalAllowList: Protected apps that never close
- WindowLayoutEntry: Placeholder for future window positioning

#### Phase 3: Infrastructure Layer (3 tasks)
- AppLister: Lists running user-facing applications
- AppCloser: Safe quit using terminate() (never force quit)
- AppLauncher: Async app launching via NSWorkspace

#### Phase 4: Application Layer (3 tasks)
- ModeManager: Hardcoded modes (Work, Dev, AI) + global allow list
- ModeSwitchUseCase: Orchestrates full mode switch flow

#### Phase 5: Presentation Layer (2 tasks)
- MenuBarController: NSStatusItem with mode selection menu
- AppDelegate integration

#### Phase 6: Integration (3 tasks)
- Fixed protocol duplication
- Updated Xcode project with all source files
- Updated PROJECT.md status

### Files Created
```
DeskModes/
├── DeskModes.xcodeproj/project.pbxproj
├── PROJECT.md
├── DESIGN_DOCUMENT.md
└── DeskModes/
    ├── AppDelegate.swift
    ├── Info.plist
    ├── DeskModes.entitlements
    ├── Domain/
    │   └── Entities/
    │       ├── AppIdentifier.swift
    │       ├── Mode.swift
    │       ├── GlobalAllowList.swift
    │       └── WindowLayoutEntry.swift
    ├── Application/
    │   ├── Services/
    │   │   └── ModeManager.swift
    │   └── UseCases/
    │       └── ModeSwitchUseCase.swift
    ├── Infrastructure/
    │   ├── Adapters/
    │   │   ├── AppLister.swift
    │   │   ├── AppCloser.swift
    │   │   └── AppLauncher.swift
    │   └── Utilities/
    │       └── Logger.swift
    └── Presentation/
        └── MenuBar/
            └── MenuBarController.swift
```

### Next Steps
1. Open in Xcode and build
2. Test mode switching manually
3. Iterate on UX based on testing
4. Implement window positioning (future)
