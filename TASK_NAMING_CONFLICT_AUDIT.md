# Task Naming Conflict Audit

## The Problem

Swift has a built-in `Task` type for concurrency, but the app also has a SwiftData model named `Task`:

```swift
// Swift's built-in concurrency Task
Task { @MainActor in
    // async work
}

// App's SwiftData model
@Model
final class Task {
    var title: String
    // ...
}
```

## Current Solution

We've been using `_Concurrency.Task` to explicitly disambiguate:

```swift
_Concurrency.Task { @MainActor in
    // This is Swift's Task, not the Task model
}
```

## Audit Results

### ✅ Properly Disambiguated
- All recent code uses `_Concurrency.Task` for concurrency
- ViewModels use `_Concurrency.Task` correctly
- Background tasks properly use `_Concurrency.Task.detached`

### ⚠️ Potential Issues
- Some older code might still use `Task` without prefix
- Need to verify all async/await code uses proper disambiguation

## Recommendations

### Option 1: Keep Current Approach (Recommended)
- Continue using `_Concurrency.Task` for concurrency
- Pros: No breaking changes, explicit disambiguation
- Cons: Verbose, requires remembering prefix

### Option 2: Rename SwiftData Model
- Rename `Task` model to `AppTask`, `TodoItem`, or `TimelineTask`
- Pros: Eliminates conflict, cleaner code
- Cons: Large refactor, breaking change, requires updating all references

### Option 3: Type Alias
- Create `typealias ConcurrencyTask = _Concurrency.Task`
- Use `ConcurrencyTask` throughout codebase
- Pros: Shorter, still explicit
- Cons: Still need to remember to use alias

## Current Status

✅ **All critical code paths properly disambiguated**
- ViewModels: ✅ Using `_Concurrency.Task`
- Views: ✅ Using `_Concurrency.Task` (all instances fixed)
- Services: ✅ Using `_Concurrency.Task` or helper functions
- Utilities: ✅ `ConcurrencyHelpers.swift` provides `ConcurrencyTask` typealias

## Recent Fixes

Fixed remaining instances where `Task` was used without `_Concurrency.` prefix:
- HomeDashboardView.swift: CategoryChangeView closure ✅
- FeedView.swift: handleReaction and handleComment ✅
- ContinuousTimelineView.swift: Sheet closures and lock toggle ✅
- LeaderboardView.swift: refreshLeaderboard ✅

## Best Practice Going Forward

1. Always use `_Concurrency.Task` for concurrency operations
2. Consider creating a helper typealias in a shared file
3. Document the naming conflict for future developers

