# DeskModes - Common Issues & Debugging Guide

## Issue #1: NSTableView shows correct row count but cells are invisible

**Symptoms:**
- `numberOfRows` returns correct count (e.g., 5)
- `viewFor` is NOT being called
- Data is correct, saves work fine
- UI shows empty table

**Root Cause:** Auto Layout constraints - the scroll view or table view has 0 or minimal height.

**How to Debug:**
```swift
print("ScrollView frame: \(scrollView.frame)")
print("ScrollView documentVisibleRect: \(scrollView.documentVisibleRect)")
print("TableView frame: \(tableView.frame)")
```

**What to look for:**
- `ScrollView frame` height should be > 0 (if it's 2px or less, that's the problem!)
- `documentVisibleRect` height should be > 0

**Common Causes:**
1. Missing `bottomAnchor` constraint on scroll view
2. Using `lessThanOrEqualTo` instead of `equalTo` for bottom constraints
3. Incomplete constraint chain (top → content → bottom)

**Fix Pattern:**
```swift
// WRONG - scroll view can collapse
scrollView.topAnchor.constraint(equalTo: labelAbove.bottomAnchor)
// NO bottom constraint!
button.topAnchor.constraint(equalTo: scrollView.bottomAnchor)
button.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)  // ❌

// CORRECT - complete chain with fixed positions
scrollView.topAnchor.constraint(equalTo: labelAbove.bottomAnchor)
scrollView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8)  // ✅
button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding)  // ✅
```

---

## Issue #2: Infinite recursion / Stack overflow when opening windows

**Symptoms:**
- App crashes with EXC_BAD_ACCESS
- Stack trace shows repeated calls to same methods
- Window won't open

**Root Cause:** NotificationCenter observer creating a loop.

**Pattern:**
```
selectionChanged → saveData → notification posted → observer reloads → selectionChanged → ...
```

**Fix:** Remove unnecessary observers or add guard flags:
```swift
private var isRestoringSelection = false

func selectionDidChange() {
    guard !isRestoringSelection else { return }
    // ... handle selection
}
```

---

## Issue #3: Data disappears when switching tabs/modes

**First, check if it's Issue #1** (constraints problem) by logging frame sizes.

If frames are OK, then check:
1. Is data being saved before switch? (add logging to save methods)
2. Is the correct data being passed to the view? (log what's received)
3. Is there a race condition with async code?

---

## Debugging Checklist

When UI doesn't show expected data:

1. [ ] **Log the data** - Is it actually there?
2. [ ] **Log the frames** - Does the view have size?
3. [ ] **Check constraints** - Is there a complete top-to-bottom chain?
4. [ ] **Check delegate/dataSource** - Are they set and not nil?
5. [ ] **Check for async issues** - Is data changing between calls?
