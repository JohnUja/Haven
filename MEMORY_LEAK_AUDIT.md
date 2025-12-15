# Memory Leak & Retain Cycle Audit Report

## Critical Issues Found

### 1. **ContinuousTimelineView.swift** - Retain Cycle in Sheet Closure

#### Issue: Strong Self Capture in modelContext.save()
**Location**: Line 170
**Problem**: Closure captures `task` and `modelContext` strongly, and calls `modelContext.save()` which could cause retain cycle.

**Current Code**:
```swift
.sheet(item: $showingTaskDetails) { task in
    TimelineTaskDetailView(task: task, onSave: { updatedNotes in
        task.taskDescription = updatedNotes.isEmpty ? nil : updatedNotes
        try? modelContext.save()  // ⚠️ Strong capture of modelContext
        showingTaskDetails = nil
    }, onCancel: { showingTaskDetails = nil })
}
```

**Fix**: Use `[weak self]` or capture modelContext weakly, ensure save happens on MainActor.

---

### 2. **ImmersiveWorkingOnView.swift** - Timer Without Weak Self

#### Issue: Timer Closure Captures Self Strongly
**Location**: Line 392
**Problem**: Timer closure doesn't use `[weak self]`, causing retain cycle if view is dismissed while timer is running.

**Current Code**:
```swift
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    if !isPaused {
        elapsedTime += 1.0  // ⚠️ Strong capture of self
        // ...
    }
}
```

**Fix**: Use `[weak self]` in timer closure.

---

### 3. **UnifiedDraggableTimelineItem.swift** - Timer Without Weak Capture

#### Issue: Timer Closure May Capture Parent Strongly
**Location**: Line 393
**Problem**: Timer closure captures `onScrollRequest` closure, which may capture parent view strongly.

**Current Code**:
```swift
scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [onScrollRequest] _ in
    onScrollRequest?(direction)  // ⚠️ May capture parent strongly
}
```

**Fix**: Ensure `onScrollRequest` is captured weakly or use `[weak self]` pattern.

---

### 4. **LeaderboardView.swift** - Timer Not Invalidated

#### Issue: Timer Created But Never Invalidated
**Location**: Line 283
**Problem**: Timer is created in `onAppear` but there's no `onDisappear` to invalidate it.

**Current Code**:
```swift
.onAppear {
    Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
        updateTimeUntilReset()  // ⚠️ Timer never invalidated
    }
}
```

**Fix**: Store timer in @State and invalidate in `onDisappear`.

---

### 5. **ContinuousTimelineView.swift** - UndoTimer Not Invalidated

#### Issue: Timer Created But Never Invalidated
**Location**: Line 678
**Problem**: Timer is created but never stored or invalidated.

**Current Code**:
```swift
private func startUndoTimer() {
    undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
        print("Block creation confirmed")
    }
}
```

**Fix**: Ensure timer is invalidated in `onDisappear` or when view is deallocated.

---

## SwiftData Threading Issues

### 6. **FeedView.swift** - modelContext Used in Background Task

#### Issue: modelContext.save() Called in Background Thread
**Location**: Lines 496, 516
**Problem**: `modelContext.save()` is called directly in closures that may execute on background threads. SwiftData modelContext must only be used on the MainActor.

**Current Code**:
```swift
try? modelContext.save()  // ⚠️ May be called off main thread
```

**Fix**: Wrap in `await MainActor.run { }` or ensure closure runs on MainActor.

---

### 7. **ContinuousTimelineView.swift** - modelContext.save() in Closure

#### Issue: modelContext.save() in Sheet Closure
**Location**: Line 170
**Problem**: `modelContext.save()` called in closure that may not be on MainActor.

**Fix**: Ensure save happens on MainActor.

---

### 8. **HomeDashboardView.swift** - Multiple modelContext.save() Calls

#### Issue: modelContext.save() in Multiple Closures
**Location**: Lines 156, 496, 516, etc.
**Problem**: Multiple places where `modelContext.save()` is called without ensuring MainActor context.

**Fix**: Audit all `modelContext.save()` calls and ensure they're on MainActor.

---

## Recommended Fixes Priority

### High Priority (Memory Leaks)
1. ✅ Fix Timer closures to use `[weak self]`
2. ✅ Ensure all Timers are invalidated in `onDisappear`
3. ✅ Fix retain cycles in sheet closures

### Critical Priority (SwiftData Threading Crashes)
4. ✅ Ensure all `modelContext.save()` calls happen on MainActor
5. ✅ Audit all `modelContext.fetch()` calls to ensure MainActor
6. ✅ Ensure Task.detached blocks don't use modelContext directly

