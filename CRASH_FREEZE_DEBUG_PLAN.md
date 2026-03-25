# Crash & Freeze Debug Plan - Comprehensive Investigation

## 🎯 Primary Issue
App crashes/freezes when user toggles task completion (check/uncheck checkbox) in Plan tab.

## 🔍 Hypotheses to Test

### Hypothesis A: SwiftData Save Blocking Main Thread
**Theory:** `modelContext.save()` is blocking the main thread, causing UI freeze
**Test:** Log save duration and check if it exceeds 100ms

### Hypothesis B: Task State Mutation Race Condition
**Theory:** Multiple simultaneous toggles or view updates causing state conflicts
**Test:** Log all task state changes and check for concurrent modifications

### Hypothesis C: ModelContext Invalid State
**Theory:** ModelContext is in invalid state when save is called (e.g., deleted object, invalid relationship)
**Test:** Log ModelContext state before save, check for errors

### Hypothesis D: View Update Cascade
**Theory:** Task toggle triggers cascading view updates that block main thread
**Test:** Log all view updates triggered by task state change

### Hypothesis E: Storage I/O Blocking
**Theory:** SQLite write operations blocking main thread
**Test:** Log storage operations and check timing

### Hypothesis F: Task ID/Relationship Issues
**Theory:** Task has invalid ID or broken relationships causing save to fail
**Test:** Log task properties before toggle, verify relationships

### Hypothesis G: Goal Progress Update Blocking
**Theory:** Goal progress calculation triggered by task toggle is blocking
**Test:** Log goal progress updates and check timing

### Hypothesis H: Gamification Calculation Blocking
**Theory:** XP/crystal calculation triggered by task completion is blocking
**Test:** Log gamification calculations and check timing

## 📊 Instrumentation Points

### 1. Task Toggle Flow
- Task toggle button pressed
- Task state before toggle
- Task state after toggle
- ModelContext.save() start
- ModelContext.save() completion/error
- View update triggered

### 2. Storage Operations
- ModelContext state before save
- Save operation start
- Save operation duration
- Save operation result (success/error)
- Storage file I/O operations

### 3. View Updates
- View body computation start
- @Query property access
- Computed property evaluation
- View render start/complete

### 4. Related Operations
- Goal progress calculation
- Gamification reward calculation
- Firestore sync operations
- View model updates

## 🔧 Implementation

See code changes in:
- `HomeDashboardView.swift` - Task toggle instrumentation
- `TaskCardView` (if exists) - Checkbox toggle instrumentation
- `GoalProgressUpdater.swift` - Goal update instrumentation
- `GamificationService.swift` - Reward calculation instrumentation

