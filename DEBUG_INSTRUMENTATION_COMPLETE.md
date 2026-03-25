# Comprehensive Debug Instrumentation - Complete ✅

## 🎯 Instrumentation Added

### Task Toggle Operations
1. **HomeDashboardView.swift:agendaTaskCard** (Context Menu Toggle)
   - Task toggle start/end
   - Task state before/after
   - ModelContext.save() timing and success/failure
   - Total duration tracking

2. **TaskCardView:handleTaskCompletion** (Main Toggle Handler)
   - Early completion detection
   - Momentum bonus calculation timing
   - Task reward calculation timing
   - Goal progress update timing
   - ModelContext.save() detailed logging
   - Thread information (main thread check)

3. **HomeDashboardView:taskBlockToggle** (Block Checkbox)
   - Block toggle start/end
   - Individual task toggles within block
   - Block save operation timing

### Goal Progress Updates
4. **GoalProgressUpdater:handleTaskToggle**
   - Goal update start/end
   - Effective target calculation timing
   - Goal value updates (before/after)
   - Goal status changes
   - Context save timing and errors

### Gamification Calculations
5. **GamificationService:calculateTaskRewards**
   - Reward calculation start/end
   - Task properties (priority, category, goal)
   - Momentum bonus
   - Final rewards (crystals, XP, score)
   - Calculation duration

### View Updates
6. **HomeDashboardView:getSortedPlanItems**
   - Function start/end
   - Filtered tasks count
   - Sort operation timing
   - Total duration

## 🔍 Hypotheses Being Tested

### Hypothesis A: SwiftData Save Blocking Main Thread
- **Test:** Log save duration, check if > 100ms
- **Location:** All `modelContext.save()` calls
- **Data:** Save start time, save duration, success/failure

### Hypothesis B: Task State Mutation Race Condition
- **Test:** Log all task state changes, check for concurrent modifications
- **Location:** All `task.isComplete.toggle()` calls
- **Data:** Task ID, old state, new state, timing

### Hypothesis C: ModelContext Invalid State
- **Test:** Log ModelContext state before save, check for errors
- **Location:** All save operations
- **Data:** Task ID validation, save errors, error types

### Hypothesis D: View Update Cascade
- **Test:** Log view updates triggered by task state change
- **Location:** `getSortedPlanItems`, view body computations
- **Data:** Function timing, item counts

### Hypothesis E: Storage I/O Blocking
- **Test:** Log storage operations and check timing
- **Location:** All `modelContext.save()` calls
- **Data:** Save duration, thread information

### Hypothesis F: Task ID/Relationship Issues
- **Test:** Log task properties before toggle, verify relationships
- **Location:** Task toggle handlers
- **Data:** Task ID, task properties, goal relationships

### Hypothesis G: Goal Progress Update Blocking
- **Test:** Log goal progress updates and check timing
- **Location:** `GoalProgressUpdater.handleTaskToggle`
- **Data:** Goal update duration, effective target calculation time

### Hypothesis H: Gamification Calculation Blocking
- **Test:** Log gamification calculations and check timing
- **Location:** `GamificationService.calculateTaskRewards`
- **Data:** Calculation duration, momentum bonus calculation time

## 📊 Log Format

All logs include:
- `location`: File and function name
- `message`: What operation is happening
- `data`: Relevant context (task IDs, states, durations, errors)
- `hypothesisId`: Which hypothesis this log tests (A-H)
- `timestamp`: When the operation occurred

## 🚀 Next Steps

1. **Build and run the app**
2. **Reproduce the crash:**
   - Navigate to Home → Plan tab
   - Create a task
   - Toggle the task (check/uncheck)
3. **Check logs** at `/Users/johnuja/Desktop/Haven2.0/.cursor/debug.log`
4. **Analyze logs** to identify:
   - Which operation takes longest
   - Where the freeze/crash occurs
   - Any save failures
   - Thread blocking issues

## 📝 Log Analysis Guide

**Look for:**
- Operations taking > 100ms (potential blocking)
- Save failures (ModelContext issues)
- Missing "completed" logs (operation didn't finish)
- Thread information (main thread blocking)
- Error messages (what failed)

**Key Patterns:**
- If save duration is high → Hypothesis A (SwiftData blocking)
- If goal update is slow → Hypothesis G (Goal progress blocking)
- If reward calc is slow → Hypothesis H (Gamification blocking)
- If save fails → Hypothesis C (ModelContext invalid)
- If no "completed" log → Operation crashed/froze

