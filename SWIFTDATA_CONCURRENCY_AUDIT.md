# SwiftData Concurrency Violation Audit

## Critical Issues Found

### 1. **FeedView.swift** - SwiftData Models Passed to Background Task ⚠️ CRITICAL

#### Issue: SwiftData Models Captured in Task.detached
**Location**: Line 76
**Problem**: SwiftData models (`users`, `routines`, `goals`, `moodEntries`) are being captured directly in a `Task.detached` closure. SwiftData models are NOT thread-safe and must only be accessed on the MainActor.

**Current Code**:
```swift
_Concurrency.Task.detached { [users, routines, goals, moodEntries] in
    guard let user = users.first else { ... }
    // Accessing SwiftData models off MainActor! ⚠️
    let completedRoutines = routines.filter { ... }
    // ...
}
```

**Why This Is Dangerous**:
- SwiftData models are tied to a specific `ModelContext` and thread
- Accessing them from a background thread causes undefined behavior
- Can lead to crashes, data corruption, or EXC_BAD_INSTRUCTION errors

**Fix**: Extract primitive values (IDs, strings, dates) before passing to background task, or perform all SwiftData operations on MainActor.

---

### 2. **HomeDashboardViewModel.swift** - User Object in Background Task ⚠️ CRITICAL

#### Issue: SwiftData User Model in Task.detached
**Location**: Line 640
**Problem**: `user` object (SwiftData model) is being accessed in a `Task.detached` closure.

**Current Code**:
```swift
_Concurrency.Task.detached {
    try await FirestoreService.shared.syncGamificationStats(
        uid: uid,
        level: user.level,  // ⚠️ Accessing SwiftData model off MainActor
        currentXP: user.currentXP,
        // ...
    )
}
```

**Fix**: Extract all needed values from `user` on MainActor before the Task.detached block.

---

### 3. **HomeDashboardView.swift** - modelContext.fetch in Closure

#### Issue: modelContext.fetch in Sheet Closure
**Location**: Lines 198-200
**Problem**: `modelContext.fetch()` is called in a closure that might not be on MainActor.

**Current Code**:
```swift
let allTasks: [Task] = {
    let descriptor = FetchDescriptor<Task>()
    return (try? modelContext.fetch(descriptor)) ?? []  // ⚠️ May not be on MainActor
}()
```

**Fix**: Ensure this runs on MainActor or use @Query instead.

---

### 4. **HomeDashboardView.swift** - Direct modelContext.save() Calls

#### Issue: modelContext.save() Without MainActor Guarantee
**Location**: Lines 215, 551, 605
**Problem**: `modelContext.save()` called directly in closures without ensuring MainActor.

**Current Code**:
```swift
block.color = newColor
try? modelContext.save()  // ⚠️ May not be on MainActor
```

**Fix**: Wrap in `_Concurrency.Task { @MainActor in }` or ensure closure is @MainActor.

---

## SwiftData Thread Safety Rules

1. **modelContext must only be accessed on MainActor** (for main context)
2. **SwiftData model objects must not be passed between threads**
3. **Use PersistentIdentifier to pass references between threads**, then fetch on the target thread
4. **Extract primitive values** (String, Int, Date, etc.) before passing to background tasks

## Recommended Fixes Priority

### Critical Priority (Causes Crashes)
1. ✅ **FIXED** - **FeedView.swift** - Changed to compute on MainActor (FeedItem requires SwiftData models)
2. ✅ **FIXED** - **HomeDashboardViewModel.swift** - Extract user values before Task.detached
3. ✅ **FIXED** - **HomeDashboardView.swift** - All modelContext.save() calls now wrapped in Task { @MainActor in }

### High Priority (Potential Crashes)
4. ✅ **FIXED** - All closures that access modelContext now ensure MainActor
5. ✅ **FIXED** - All sheet closures verified to run on MainActor

## Summary of Fixes Applied

### FeedView.swift
- **Issue**: SwiftData models (users, routines, goals, moodEntries) captured in Task.detached
- **Fix**: Changed to compute feed items on MainActor since FeedItem enum requires SwiftData model objects
- **Reason**: FeedItem stores actual SwiftData models, so we must compute on MainActor

### HomeDashboardViewModel.swift
- **Issue**: User SwiftData model accessed in Task.detached
- **Fix**: Extract all primitive values (level, currentXP, etc.) on MainActor before Task.detached
- **Result**: Background task now uses only primitive values, no SwiftData models

### HomeDashboardView.swift
- **Issue**: Multiple modelContext.save() calls in closures without MainActor guarantee
- **Fix**: Wrapped all modelContext.save() calls in `_Concurrency.Task { @MainActor in }`
- **Locations Fixed**:
  - CategoryChangeView closure
  - BlockColorPickerView closure
  - Alert button closures (Delete Goal, Pause Goal)
  - Floating menu unlock closures
  - Button action closures (Snooze, Complete, Block Complete)
  - deleteTask function
  - handleTaskCompletion function

## SwiftData Thread Safety Rules (Applied)

1. ✅ **modelContext must only be accessed on MainActor** - All operations now ensure MainActor
2. ✅ **SwiftData model objects must not be passed between threads** - Primitive values extracted before Task.detached
3. ✅ **Use PersistentIdentifier to pass references between threads** - Not needed in current implementation
4. ✅ **Extract primitive values** before passing to background tasks - Applied in HomeDashboardViewModel

