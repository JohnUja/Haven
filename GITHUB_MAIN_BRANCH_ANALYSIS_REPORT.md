# GitHub Main Branch Analysis Report
## Comparison: Main Branch (Working) vs Current Branch (Freezing)

**Date:** 2026-01-17  
**Main Branch Commit:** `2c516b4` - "Major UI/UX improvements and fixes"  
**Analysis Focus:** @Query properties, view construction, and performance optimizations

---

## 🔍 **CRITICAL FINDING: Main Branch Had NO Sort Descriptors**

### Main Branch @Query Properties (WORKING):
```swift
// GoalsView.swift (main branch)
@Query private var goals: [Goal]  // ✅ NO sort descriptor - WORKED FINE

// TimelineView.swift (main branch)  
@Query private var tasks: [Task]  // ✅ NO sort descriptor - WORKED FINE
@Query private var taskBlocks: [TaskBlock]  // ✅ NO sort descriptor - WORKED FINE
@Query private var goals: [Goal]  // ✅ NO sort descriptor - WORKED FINE
```

### Current Branch @Query Properties (FREEZING):
```swift
// GoalsView.swift (current branch)
@Query(sort: [SortDescriptor(\Goal.createdAt, order: .reverse)])
private var goals: [Goal]  // ❌ HAS sort descriptor - STILL FREEZES

// TimelineView.swift (current branch)
@Query(sort: [SortDescriptor(\Goal.createdAt, order: .reverse)])
private var goals: [Goal]
@Query(sort: [SortDescriptor(\User.level, order: .reverse), SortDescriptor(\User.currentXP, order: .reverse)])
private var users: [User]
// Plus: @State private var dayTasks: [Task] = []  // Day-scoped data
```

---

## 🎯 **KEY INSIGHT: Sort Descriptors Are NOT the Root Cause**

**Evidence:**
1. ✅ Main branch worked WITHOUT sort descriptors
2. ❌ Current branch freezes WITH sort descriptors
3. ❌ Adding sort descriptors did NOT fix the freeze

**Conclusion:** The freeze is NOT caused by missing sort descriptors. Something else changed.

---

## 📊 **What Changed Between Main Branch and Current**

### 1. **TimelineView.swift - Major Refactor**

#### Main Branch (Simple, Working):
```swift
@Query private var tasks: [Task]  // All tasks loaded
@Query private var taskBlocks: [TaskBlock]  // All blocks loaded
@Query private var goals: [Goal]  // All goals loaded

private var selectedDateTasks: [Task] {
    // Simple filter in computed property
    tasks.filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
}
```

#### Current Branch (Complex, Freezing):
```swift
@Query(sort: [...]) private var goals: [Goal]
@Query(sort: [...]) private var users: [User]
@State private var dayTasks: [Task] = []  // ⚠️ NEW: Day-scoped data
@State private var dayTaskBlocks: [TaskBlock] = []  // ⚠️ NEW: Day-scoped data
@State private var workGroups: [[Task]] = []  // ⚠️ NEW: Pre-computed groups
@State private var personalGroups: [[Task]] = []  // ⚠️ NEW: Pre-computed groups

// Complex refreshForSelectedDate() function
// Background tasks for group computation
// Multiple state variables
```

**Key Differences:**
- ✅ Main: Simple @Query properties, direct filtering
- ❌ Current: Day-scoped @State, pre-computed groups, background tasks
- ❌ Current: More complex initialization logic

---

### 2. **GoalsView.swift - Minimal Changes**

#### Main Branch:
```swift
@Query private var goals: [Goal]  // Simple, no sort descriptor

private var sortedGoals: [Goal] {
    // Computed property with filtering/sorting
    // Fetches allTasks in computed property (line 67)
    let allTasks = (try? modelContext.fetch(FetchDescriptor<Task>())) ?? []
    // ... sorting logic
}
```

#### Current Branch:
```swift
@Query(sort: [SortDescriptor(\Goal.createdAt, order: .reverse)])
private var goals: [Goal]  // Has sort descriptor

// Removed @Query private var allTasks: [Task]
// Now fetches tasks on-demand in deleteGoalAndLinkedTasks()
```

**Key Differences:**
- ✅ Main: Fetched allTasks in computed property (blocking but worked)
- ❌ Current: Removed @Query allTasks, fetches on-demand
- ⚠️ Both: Have sortedGoals computed property

---

### 3. **View Construction Complexity**

#### Main Branch:
- Simple view hierarchy
- Direct @Query properties
- Computed properties for filtering
- No pre-computation
- No background tasks during view construction

#### Current Branch:
- Complex view hierarchy
- @Query with sort descriptors
- @State for day-scoped data
- Pre-computed groups
- Background tasks during view construction
- Multiple sheet modifiers with views that have @Query properties

---

## 🚨 **ROOT CAUSE HYPOTHESIS**

Based on the analysis, the freeze is likely caused by:

### **Hypothesis 1: SwiftUI Pre-Evaluation of Sheet Closures** ⚠️ **MOST LIKELY**

**Evidence:**
- Main branch: Simple views, fewer sheet modifiers
- Current branch: Multiple sheet modifiers (AddGoalView, EditGoalInlineView, AddTaskToGoalView, GoalsDetailView)
- All sheet views have @Query properties
- SwiftUI pre-evaluates sheet closures during view construction
- This triggers SwiftData macro generation BEFORE the view appears

**Why Main Branch Worked:**
- Fewer sheet modifiers
- Simpler view hierarchy
- Less @Query properties in sheet views

**Why Current Branch Freezes:**
- Multiple sheet modifiers with @Query properties
- SwiftUI tries to initialize all @Query properties during view construction
- This blocks the main thread for 26+ seconds

---

### **Hypothesis 2: Day-Scoped Data Initialization** 

**Evidence:**
- Main branch: Used @Query for all tasks (simple)
- Current branch: Uses @State dayTasks with refreshForSelectedDate()
- refreshForSelectedDate() is called in onAppear
- But view construction might be trying to access dayTasks before it's initialized

**Why This Could Freeze:**
- If view body tries to access dayTasks before refreshForSelectedDate() completes
- Or if refreshForSelectedDate() is called synchronously during view construction

---

### **Hypothesis 3: Background Task Complexity**

**Evidence:**
- Main branch: No background tasks during view construction
- Current branch: Background tasks for group computation
- Task.detached blocks might be blocking if not properly isolated

**Why This Could Freeze:**
- If background tasks are not properly isolated
- Or if they're accessing main thread resources

---

## 🔧 **RECOMMENDED FIXES (Priority Order)**

### **Fix 1: Defer @Query Initialization in Sheet Views** 🔴 **HIGHEST PRIORITY**

**Problem:** SwiftUI pre-evaluates sheet closures, initializing @Query properties during view construction.

**Solution:** Use lazy initialization or @State with on-demand fetching for sheet views.

```swift
// Instead of:
.sheet(isPresented: $showingAddGoal) {
    AddGoalView()  // @Query initialized immediately
}

// Use:
.sheet(isPresented: $showingAddGoal) {
    LazyView {
        AddGoalView()  // @Query initialized only when sheet appears
    }
}

// Or better: Remove @Query from sheet views, fetch on-demand
struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var users: [User] = []
    
    var body: some View {
        // ...
    }
    .task {
        // Fetch users on-demand when sheet appears
        let descriptor = FetchDescriptor<User>()
        users = (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

---

### **Fix 2: Simplify TimelineView Data Loading**

**Problem:** Day-scoped data with pre-computed groups adds complexity.

**Solution:** Revert to simpler approach OR ensure proper initialization order.

```swift
// Option A: Revert to main branch approach (simple @Query)
@Query private var tasks: [Task]
private var selectedDateTasks: [Task] {
    tasks.filter { /* date filter */ }
}

// Option B: Keep day-scoped but ensure proper initialization
@State private var dayTasks: [Task] = []
.onAppear {
    // Ensure this runs BEFORE view body accesses dayTasks
    refreshForSelectedDate()
}
```

---

### **Fix 3: Remove Sort Descriptors (They're Not Needed)**

**Evidence:** Main branch worked without them.

**Solution:** Remove all sort descriptors and see if freeze persists.

```swift
// Change from:
@Query(sort: [SortDescriptor(\Goal.createdAt, order: .reverse)])
private var goals: [Goal]

// Back to:
@Query private var goals: [Goal]
```

**Test:** If removing sort descriptors fixes the freeze, then the issue is with SwiftData macro generation when sort descriptors are present.

---

## 📋 **Testing Plan**

1. **Test 1:** Remove all sort descriptors from @Query properties
   - Expected: If freeze persists, sort descriptors are not the issue
   - If freeze stops, sort descriptors are causing macro generation issues

2. **Test 2:** Defer @Query initialization in sheet views
   - Use LazyView wrapper or on-demand fetching
   - Expected: Sheet views don't block during view construction

3. **Test 3:** Simplify TimelineView to main branch approach
   - Revert to simple @Query properties
   - Expected: Simpler initialization, no freeze

4. **Test 4:** Compare view construction timing
   - Add logs to measure time from view init to onAppear
   - Expected: Identify where the 26-second freeze occurs

---

## 🎯 **Key Takeaways**

1. ✅ **Main branch worked WITHOUT sort descriptors** - They're not required
2. ❌ **Adding sort descriptors did NOT fix the freeze** - They're not the solution
3. ⚠️ **Sheet modifiers with @Query properties are the likely culprit** - SwiftUI pre-evaluation
4. ⚠️ **Complex view initialization (day-scoped data, pre-computed groups) adds risk** - More moving parts
5. 🔴 **The freeze happens during view construction, not during render** - Evidence: onAppear never runs

---

## 📝 **Next Steps**

1. **Immediate:** Test removing sort descriptors to see if they're actually causing issues
2. **Priority 1:** Fix sheet view @Query initialization (defer or remove)
3. **Priority 2:** Simplify TimelineView data loading (revert or fix initialization order)
4. **Priority 3:** Add detailed logging to identify exact freeze location

---

## 🔗 **Related Documents**

- `MAIN_BRANCH_VS_CURRENT_COMPARISON.md` - Detailed code comparison
- `TIMELINE_PERFORMANCE_CHANGES.md` - Performance refactor details
- `NAVIGATION_FREEZE_DEBUG_REPORT.md` - Debug findings
- `REFACTOR_SUMMARY.md` - Refactor summary

---

**Conclusion:** The freeze is NOT caused by missing sort descriptors. The main branch worked fine without them. The issue is likely SwiftUI pre-evaluating sheet closures with @Query properties, or complex view initialization logic. Focus on deferring @Query initialization in sheet views and simplifying the view construction process.

