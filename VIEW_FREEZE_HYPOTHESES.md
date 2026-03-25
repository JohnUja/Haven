# View Freeze Investigation - Hypotheses

## 🎯 **Question**
Was FeedView primarily the problem causing hangs, or are there other views that need addressing?

## 📊 **Hypotheses Generated**

### **Hypothesis A: GoalsView.sortedGoals @Query Access** 🔴 **HIGH PRIORITY**
**Theory**: `sortedGoals` computed property accesses `goals` @Query during body computation (when `ForEach(sortedGoals)` is evaluated), triggering SwiftData macro generation that blocks the main thread.

**Evidence to Collect**:
- Timing of `GoalsView.body` computation START
- Timing of `sortedGoals` computed property access
- Timing of `GoalsView.onAppear` (after body computation)
- If freeze occurs between body START and onAppear → CONFIRMED

**Instrumentation Added**:
- `GoalsView.swift:body` - logs body computation START
- `GoalsView.swift:sortedGoals` - logs when @Query is accessed
- `GoalsView.swift:onAppear` - logs when view appears (after body computation)

---

### **Hypothesis B: TimelineView.selectedDateTasks @Query Access** 🟡 **MEDIUM PRIORITY**
**Theory**: `selectedDateTasks` computed property accesses `task.goal?.status` which may trigger @Query access during body computation, causing freezes.

**Evidence to Collect**:
- Timing of `TimelineView.body` computation START
- Timing of `selectedDateTasks` computed property access
- Timing of `TimelineView.onAppear` (after body computation)
- If freeze occurs between body START and onAppear → CONFIRMED

**Instrumentation Added**:
- `TimelineView.swift:body` - logs body computation START
- `TimelineView.swift:selectedDateTasks` - logs when @Query might be accessed via task.goal
- `TimelineView.swift:onAppear` - already has logs

---

### **Hypothesis C: Other Views with Similar Issues** 🟡 **MEDIUM PRIORITY**
**Theory**: Other views (HomeDashboardView, ProfileView, etc.) have computed properties that access @Query during body computation.

**Evidence to Collect**:
- Check logs for any view body computation that takes >100ms
- Check for computed properties accessing @Query in other views

**Next Steps**: If A or B are confirmed, audit other views for similar patterns.

---

### **Hypothesis D: Sheet Views Cause Issues** 🟢 **LOW PRIORITY**
**Theory**: Sheet views (even with LazyView) might still access @Query during their own body computation when the sheet is presented.

**Evidence to Collect**:
- Check if freeze occurs when opening sheets (AddGoalView, EditGoalInlineView, etc.)
- Check logs for sheet view body computation timing

**Status**: Sheets are already wrapped in LazyView, but need to verify they're not causing issues.

---

### **Hypothesis E: Freeze During Tab Switching** 🟢 **LOW PRIORITY**
**Theory**: The freeze happens during tab switching in MainTabView, not during individual view body computation.

**Evidence to Collect**:
- Timing of `MainTabView.onChange(selectedTab)` 
- If freeze occurs during tab switch → CONFIRMED
- If freeze occurs after tab switch but before view appears → REJECTED

**Instrumentation Added**:
- `MainTabView.swift:onChange(selectedTab)` - already has logs

---

## 🔍 **Analysis Plan**

### **Step 1: Reproduce Freeze**
User should navigate: Timeline → Goals → Feed → Profile

### **Step 2: Analyze Log Timing**
For each view transition, check:
1. **Body computation START** timestamp
2. **@Query access** timestamp (sortedGoals, selectedDateTasks, etc.)
3. **onAppear** timestamp (after body computation)
4. **Time gap** between body START and onAppear

### **Step 3: Identify Blocking View**
- If time gap >500ms between body START and onAppear → **CONFIRMED: That view is blocking**
- If time gap <100ms → **REJECTED: That view is not blocking**

### **Step 4: Fix Confirmed Views**
Apply same fix as FeedView:
- Convert computed properties accessing @Query to @State
- Initialize in `.task` modifier (after view appears)

---

## 📋 **Expected Log Sequence (Normal Flow)**

```
1. MainTabView: Tab change started (tab: 2 = Goals)
2. GoalsView: body computation START
3. GoalsView: sortedGoals computed property START - accessing @Query goals
4. GoalsView: sortedGoals computed property COMPLETE
5. GoalsView: body computation COMPLETE (implicit - view appears)
6. GoalsView: onAppear
```

**If freeze occurs**: Logs will show step 2 or 3, but step 5/6 never appears → **CONFIRMED: That view is blocking**

---

## 🎯 **Success Criteria**

- **Hypothesis A CONFIRMED**: If GoalsView body START appears but onAppear never appears
- **Hypothesis B CONFIRMED**: If TimelineView body START appears but onAppear never appears
- **Hypothesis C CONFIRMED**: If other views show similar blocking patterns
- **Hypothesis D CONFIRMED**: If freeze occurs when opening sheets
- **Hypothesis E CONFIRMED**: If freeze occurs during tab switch (before any view body computation)

---

**Date Created**: 2026-01-19  
**Status**: Ready for Testing  
**Priority**: 🔴 **CRITICAL** - Need to identify all blocking views

