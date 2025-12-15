# Task Naming Conflict - Summary & Best Practices

## The Issue

Your app has a SwiftData model named `Task`:
```swift
@Model
final class Task {
    var title: String
    // ...
}
```

But Swift also has a built-in `Task` type for concurrency:
```swift
Task { @MainActor in
    // async work
}
```

## The Solution We're Using

We explicitly disambiguate using `_Concurrency.Task`:

```swift
// ✅ CORRECT - Explicitly uses Swift's Task
_Concurrency.Task { @MainActor in
    try? modelContext.save()
}

// ❌ WRONG - Ambiguous, compiler might think it's your Task model
Task { @MainActor in
    try? modelContext.save()
}
```

## Helper Available

You already have a helper file `ConcurrencyHelpers.swift` that provides:
- `typealias ConcurrencyTask = _Concurrency.Task`
- Helper functions `_createConcurrencyTask()` and `_createConcurrencyTaskAsync()`

You can use `ConcurrencyTask` instead of `_Concurrency.Task` if you prefer:
```swift
ConcurrencyTask { @MainActor in
    // async work
}
```

## Current Status: ✅ ALL FIXED

All instances of concurrency `Task` now use `_Concurrency.Task`:
- ✅ HomeDashboardView.swift
- ✅ FeedView.swift
- ✅ ContinuousTimelineView.swift
- ✅ LeaderboardView.swift
- ✅ All ViewModels
- ✅ All Services

## Best Practice Going Forward

1. **Always use `_Concurrency.Task`** for concurrency operations
2. **Or use `ConcurrencyTask`** typealias from ConcurrencyHelpers
3. **Never use bare `Task`** - it's ambiguous with your model

## Alternative Solution (Future Consideration)

If you want to eliminate the conflict entirely, you could rename your model:
- `Task` → `AppTask` or `TodoItem` or `TimelineTask`
- This would be a large refactor but would eliminate the conflict
- Not recommended unless you're doing a major refactor anyway

