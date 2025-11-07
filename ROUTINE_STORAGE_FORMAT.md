# Routine Storage Format - Performance Optimization

## Problem Statement

**Challenge:** How to store daily routines without causing slow rendering when SwiftData queries 30+ days of routine-generated tasks.

**Solution:** Template-based storage with **pre-generation** strategy.

---

## Storage Format: Template-Based

### `DailyRoutine` Model (SwiftData)

```swift
import Foundation
import SwiftData

@Model
final class DailyRoutine {
    var id: String
    var userID: String
    var title: String // e.g., "My Daily Essentials"
    var isActive: Bool
    var isDefault: Bool // true for sleep/eat defaults
    
    // Duration Type
    var durationTypeRaw: String // "tillMonthEnd" or "days"
    var durationDays: Int? // If "days", how many (30, 45, 60, etc.)
    var startDate: Date
    var endDate: Date? // Calculated: startDate + duration
    
    // Task Templates (LIGHTWEIGHT - JSON-encoded array)
    var taskTemplatesJSON: Data // JSON-encoded [RoutineTaskTemplate]
    
    // Notifications
    var notificationEnabled: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date? // After routine expires + 30 day grace period
    
    // Computed property for easy access
    var taskTemplates: [RoutineTaskTemplate] {
        get {
            guard let data = taskTemplatesJSON,
                  let templates = try? JSONDecoder().decode([RoutineTaskTemplate].self, from: data) else {
                return []
            }
            return templates
        }
        set {
            taskTemplatesJSON = try? JSONEncoder().encode(newValue)
        }
    }
    
    var durationType: RoutineDurationType {
        get {
            RoutineDurationType(rawValue: durationTypeRaw) ?? .days
        }
        set {
            durationTypeRaw = newValue.rawValue
        }
    }
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         isActive: Bool = true,
         isDefault: Bool = false,
         durationType: RoutineDurationType,
         durationDays: Int? = nil,
         startDate: Date = Date(),
         taskTemplates: [RoutineTaskTemplate] = [],
         notificationEnabled: Bool = true) {
        self.id = id
        self.userID = userID
        self.title = title
        self.isActive = isActive
        self.isDefault = isDefault
        self.durationTypeRaw = durationType.rawValue
        self.durationDays = durationDays
        self.startDate = startDate
        
        // Calculate endDate
        if durationType == .tillMonthEnd {
            let calendar = Calendar.current
            if let monthEnd = calendar.dateInterval(of: .month, for: startDate)?.end {
                self.endDate = calendar.date(byAdding: .day, value: -1, to: monthEnd)
            }
        } else if let days = durationDays {
            self.endDate = calendar.date(byAdding: .day, value: days, to: startDate)
        }
        
        // Encode templates as JSON
        self.taskTemplatesJSON = try? JSONEncoder().encode(taskTemplates)
        self.notificationEnabled = notificationEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum RoutineDurationType: String, Codable {
    case tillMonthEnd = "tillMonthEnd"
    case days = "days"
}
```

### `RoutineTaskTemplate` Struct (Codable, Not @Model)

```swift
import Foundation

struct RoutineTaskTemplate: Codable, Identifiable {
    var id: String
    var title: String
    var description: String?
    var timeOfDay: String // "HH:mm" format (e.g., "08:00", "12:30")
    var durationMinutes: Int
    var priority: PriorityType
    var category: TaskCategory
    var hasDefaultNotifications: Bool // For sleep/eat defaults
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String? = nil,
         timeOfDay: String,
         durationMinutes: Int,
         priority: PriorityType = .normal,
         category: TaskCategory = .personal,
         hasDefaultNotifications: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.timeOfDay = timeOfDay
        self.durationMinutes = durationMinutes
        self.priority = priority
        self.category = category
        self.hasDefaultNotifications = hasDefaultNotifications
    }
}
```

**Why JSON Encoding?**

- ✅ SwiftData `@Model` doesn't support nested structs or arrays of structs directly
- ✅ JSON encoding is efficient for small arrays (typically 5-10 templates per routine)
- ✅ Easy to serialize/deserialize
- ✅ Minimal storage overhead (templates are lightweight)

---

## Task Generation Strategy: Pre-Generate

### When Routine is Created

```swift
func generateTasksFromRoutine(_ routine: DailyRoutine, in context: ModelContext) async {
    let calendar = Calendar.current
    var currentDate = routine.startDate
    let endDate = routine.endDate ?? calendar.date(byAdding: .day, value: 30, to: routine.startDate)!
    
    // Generate all tasks upfront (in background)
    var tasksToInsert: [Task] = []
    
    while currentDate <= endDate {
        for template in routine.taskTemplates {
            // Combine date with time
            let timeComponents = template.timeOfDay.split(separator: ":")
            guard let hour = Int(timeComponents[0]),
                  let minute = Int(timeComponents[1]) else { continue }
            
            let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: currentDate) ?? currentDate
            let endTime = calendar.date(byAdding: .minute, value: template.durationMinutes, to: startTime) ?? startTime
            
            let task = Task(
                userID: routine.userID,
                title: template.title,
                taskDescription: template.description,
                startTime: startTime,
                endTime: endTime,
                priority: template.priority,
                category: template.category,
                isRoutineTask: true,
                routineID: routine.id,
                isLocked: true // Cannot delete/move
            )
            
            tasksToInsert.append(task)
        }
        
        // Move to next day
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    }
    
    // Batch insert (efficient)
    for task in tasksToInsert {
        context.insert(task)
    }
    
    try? context.save()
}
```

**Benefits of Pre-Generation:**

1. **Instant Queries**: Tasks available immediately when scrolling days
2. **No Generation Lag**: No delay when viewing timeline
3. **Efficient Filtering**: Can query `tasks.filter { $0.routineID == routine.id }` instantly
4. **SwiftData Optimized**: SwiftData handles batch inserts efficiently

**Storage Considerations:**

- 1 routine with 5 tasks/day × 30 days = 150 tasks
- Average task size: ~200 bytes (metadata only)
- Total: ~30 KB per routine month (negligible)

---

## Alternative: Lazy Generation (Not Recommended)

### On-Demand Generation

```swift
func getTasksForDay(_ date: Date, context: ModelContext) -> [Task] {
    let calendar = Calendar.current
    let existingTasks = fetchTasksForDay(date, context: context)
    
    // Check if routine tasks missing for this day
    let activeRoutines = fetchActiveRoutines(context: context)
    
    for routine in activeRoutines {
        if isDateInRoutineRange(date, routine) {
            let routineTasksForDay = existingTasks.filter { $0.routineID == routine.id }
            if routineTasksForDay.isEmpty {
                // Generate now (lazy)
                generateTasksForRoutine(routine, for: date, context: context)
                // Re-fetch after generation
                return fetchTasksForDay(date, context: context)
            }
        }
    }
    
    return existingTasks
}
```

**Why Not Recommended:**

- ⚠️ **First-Time Lag**: First time viewing a day causes generation delay
- ⚠️ **Complex Queries**: Need to check every day if tasks exist
- ⚠️ **UI Stuttering**: Generation happens during UI rendering
- ⚠️ **More Complexity**: Need to track which days are generated

---

## Performance Optimization: Query Filtering

### Efficient Routine Task Queries

```swift
// Filter by routineID for fast queries
@Query(filter: #Predicate<Task> { task in
    task.isRoutineTask == true && task.routineID == routineID
}, sort: \Task.startTime)
var routineTasks: [Task]

// Filter by date range (for timeline view)
@Query(filter: #Predicate<Task> { task in
    task.startTime >= startDate && task.startTime <= endDate
}, sort: \Task.startTime)
var tasksInRange: [Task]

// Combined filter (routine tasks in date range)
func getRoutineTasksForDateRange(_ startDate: Date, _ endDate: Date, routineID: String, context: ModelContext) -> [Task] {
    let descriptor = FetchDescriptor<Task>(
        predicate: #Predicate<Task> { task in
            task.isRoutineTask == true &&
            task.routineID == routineID &&
            task.startTime >= startDate &&
            task.startTime <= endDate
        },
        sortBy: [SortDescriptor(\.startTime)]
    )
    
    return (try? context.fetch(descriptor)) ?? []
}
```

**SwiftData Index Recommendations:**

```swift
// In TimeFlowApp.swift, when configuring SwiftData:
let configuration = ModelConfiguration(
    schema: Schema([Task.self, DailyRoutine.self, ...]),
    isStoredInMemoryOnly: false // Set to false for persistence
)

// Add indexes for performance
let container = ModelContainer(
    for: Task.self, DailyRoutine.self, ...,
    configurations: configuration
)
```

**Index on Task Model:**

Add index hints in `Task` model:

```swift
@Model
final class Task {
    // ... existing properties ...
    
    // SwiftData will automatically index these for fast queries:
    // - routineID (used in filters)
    // - isRoutineTask (used in filters)
    // - startTime (used in sorting and date range filters)
}
```

---

## Routine Archival Strategy

### Archive Expired Routines

```swift
func archiveExpiredRoutines(context: ModelContext) {
    let calendar = Calendar.current
    let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
    
    let descriptor = FetchDescriptor<DailyRoutine>(
        predicate: #Predicate<DailyRoutine> { routine in
            routine.isActive == true &&
            routine.endDate != nil &&
            routine.endDate! < thirtyDaysAgo &&
            routine.archivedAt == nil
        }
    )
    
    guard let expiredRoutines = try? context.fetch(descriptor) else { return }
    
    for routine in expiredRoutines {
        // Mark routine as archived
        routine.archivedAt = Date()
        routine.isActive = false
        
        // Archive all tasks from this routine (mark as archived, don't delete)
        let taskDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.routineID == routine.id
            }
        )
        
        if let routineTasks = try? context.fetch(taskDescriptor) {
            for task in routineTasks {
                // Mark as archived (add isArchived flag to Task model)
                task.isArchived = true
                task.archivedAt = Date()
            }
        }
    }
    
    try? context.save()
}
```

**Run Archival:**

- On app launch (background)
- Weekly (background)
- Or manually from Settings → "Clean Up Old Routines"

---

## Recommended Implementation

### 1. Pre-Generate Tasks on Routine Creation

**Benefits:**
- ✅ Zero lag when viewing timeline
- ✅ Instant queries
- ✅ Simple logic (generate once, done)

**When to Generate:**
- Immediately after user creates/activates routine
- In background task (don't block UI)

### 2. Batch Insert for Performance

**Benefits:**
- ✅ SwiftData handles batch inserts efficiently
- ✅ Single save operation
- ✅ Atomic (all or nothing)

### 3. Use SwiftData Indexes

**Benefits:**
- ✅ Fast queries by `routineID`
- ✅ Fast date range queries
- ✅ Minimal storage overhead

### 4. Archive Old Tasks (Not Delete)

**Benefits:**
- ✅ Preserves history (3 months)
- ✅ Can query archived tasks if needed
- ✅ SwiftData can filter out archived in queries

---

## Summary

**Recommended Format:**

- **Template-Based Storage**: `DailyRoutine` stores `[RoutineTaskTemplate]` as JSON
- **Pre-Generation**: Generate all tasks upfront (in background)
- **Batch Insert**: Insert all tasks in single save
- **Indexed Queries**: Filter by `routineID` and date range for fast access
- **Archive (Don't Delete)**: Mark tasks as archived after routine expires

**Result:**

- ✅ Fast queries (no lag)
- ✅ Instant timeline rendering
- ✅ Minimal storage (templates are tiny)
- ✅ Simple logic (generate once, query easily)

**Performance:**

- 1 routine × 5 tasks/day × 30 days = 150 tasks
- Generation time: < 1 second (in background)
- Query time: < 10ms (with indexes)
- Storage: ~30 KB per routine month

---

**Status:** Ready for implementation. This format prevents slow rendering while maintaining simplicity.

