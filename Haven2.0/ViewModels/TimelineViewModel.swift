//
//  TimelineViewModel.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Optimized Timeline ViewModel: Combines SwiftData predicates with Dictionary grouping
//

import SwiftUI
import SwiftData
import Combine

@MainActor
@Observable
final class TimelineViewModel {
    // MARK: - Dependencies
    var modelContext: ModelContext?
    
    // MARK: - Data (injected from View's @Query)
    var routines: [DailyRoutine] = []
    var users: [User] = []
    
    // MARK: - State
    // Track initialization to prevent didSet during init
    private var isInitialized = false
    
    var selectedDate: Date = {
        // Priority: 1. Last worked date, 2. Last selected date, 3. Today
        if let lastWorkedDate = DatePersistenceService.shared.restoreLastWorkedDate() {
            return lastWorkedDate
        }
        if let lastSelectedDate = DatePersistenceService.shared.restoreSelectedDate() {
            return lastSelectedDate
        }
        return Date()
    }() {
        didSet {
            // Only refresh if ViewModel is initialized and modelContext is available
            guard isInitialized, modelContext != nil else { return }
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                refreshSelectedDateData()
            }
        }
    }
    
    // Cached filtered data (updated when selectedDate changes)
    private var _selectedDateTasks: [Task] = []
    private var _selectedDateTaskBlocks: [TaskBlock] = []
    
    // MARK: - Memoized Grouped Data (Only recalculates when tasks/date change, NOT on scroll)
    // Dictionary: [hour: [tasks]] for O(1) lookups
    private var _tasksByHour: [Int: [Task]] = [:]
    private var _workTasks: [Task] = []
    private var _personalTasks: [Task] = []
    private var _workTaskBlocks: [TaskBlock] = []
    private var _personalTaskBlocks: [TaskBlock] = []
    
    // Memoized grouped items (pre-computed overlap groups)
    private var _workItemGroups: [[TimelineItem]] = []
    private var _personalItemGroups: [[TimelineItem]] = []
    
    // Cache invalidation tracking
    private var _lastCachedDate: Date?
    private var _lastCachedTaskIDs: Set<String> = []
    
    // MARK: - Public Computed Properties (O(1) lookups from pre-computed dictionaries)
    var selectedDateTasks: [Task] {
        _selectedDateTasks
    }
    
    var taskBlocksForSelectedDate: [TaskBlock] {
        _selectedDateTaskBlocks
    }
    
    // O(1) lookup: Get tasks for a specific hour
    func tasksForHour(_ hour: Int) -> [Task] {
        _tasksByHour[hour] ?? []
    }
    
    // O(1) lookup: Get work tasks (pre-filtered)
    var workTasks: [Task] {
        _workTasks
    }
    
    // O(1) lookup: Get personal tasks (pre-filtered)
    var personalTasks: [Task] {
        _personalTasks
    }
    
    // O(1) lookup: Get work task blocks (pre-filtered)
    var workTaskBlocks: [TaskBlock] {
        _workTaskBlocks
    }
    
    // O(1) lookup: Get personal task blocks (pre-filtered)
    var personalTaskBlocks: [TaskBlock] {
        _personalTaskBlocks
    }
    
    // Pre-computed grouped items (no recalculation on scroll)
    var workItemGroups: [[TimelineItem]] {
        _workItemGroups
    }
    
    var personalItemGroups: [[TimelineItem]] {
        _personalItemGroups
    }
    
    // MARK: - Update Data
    func updateData(routines: [DailyRoutine], users: [User]) {
        self.routines = routines
        self.users = users
    }
    
    // MARK: - Fetch Filtered Tasks Using SwiftData Predicates
    func refreshSelectedDateData() {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
        
        // Query tasks that overlap with selected date (database-level filtering)
        let taskPredicate = #Predicate<Task> { task in
            task.startTime < endOfDay && task.endTime >= startOfDay
        }
        
        do {
            let taskDescriptor = FetchDescriptor<Task>(
                predicate: taskPredicate,
                sortBy: [SortDescriptor(\Task.startTime, order: .forward)]
            )
            _selectedDateTasks = try modelContext.fetch(taskDescriptor)
            
            // Filter out tasks from paused goals and inactive routines
            _selectedDateTasks = _selectedDateTasks.filter { task in
                !(task.goal != nil && task.goal?.status == .paused) &&
                !isFromInactiveRoutine(task)
            }
        } catch {
            print("TimelineViewModel: Failed to fetch tasks: \(error)")
            _selectedDateTasks = []
        }
        
        // Query task blocks for selected date
        let blockPredicate = #Predicate<TaskBlock> { block in
            block.createdDate >= startOfDay && block.createdDate < endOfDay
        }
        
        do {
            let blockDescriptor = FetchDescriptor<TaskBlock>(predicate: blockPredicate)
            _selectedDateTaskBlocks = try modelContext.fetch(blockDescriptor)
        } catch {
            print("TimelineViewModel: Failed to fetch task blocks: \(error)")
            _selectedDateTaskBlocks = []
        }
        
        // Recompute grouped data (only when tasks/date change)
        recomputeGroupedData()
    }
    
    // MARK: - Recompute Grouped Data (Only called when tasks/date change, NOT on scroll)
    private func recomputeGroupedData() {
        let calendar = Calendar.current
        let currentTaskIDs = Set(_selectedDateTasks.map { $0.id })
        
        // Check if we need to recompute (date changed or tasks changed)
        let needsRecompute = _lastCachedDate == nil ||
                            !calendar.isDate(selectedDate, inSameDayAs: _lastCachedDate!) ||
                            currentTaskIDs != _lastCachedTaskIDs
        
        guard needsRecompute else { return }
        
        // 1. Group tasks by hour (O(N) - done once per date change)
        _tasksByHour = Dictionary(grouping: _selectedDateTasks) { task in
            calendar.component(.hour, from: task.startTime)
        }
        
        // 2. Pre-filter work/personal tasks (O(N) - done once per date change)
        _workTasks = _selectedDateTasks.filter { task in
            task.taskBlock == nil &&
            (task.category == .work || task.category == .fixed ||
             task.category == .growth || task.category == .reading)
        }
        
        _personalTasks = _selectedDateTasks.filter { task in
            task.taskBlock == nil &&
            (task.category == .personal || task.category == .flexible ||
             task.category == .hobbies || task.category == .selfCare ||
             task.category == .leisure || task.category == .skinCare)
        }
        
        // 3. Pre-filter task blocks by side
        _workTaskBlocks = _selectedDateTaskBlocks.filter { block in
            let blockTasks = _selectedDateTasks.filter { $0.taskBlock?.id == block.id }
            return blockTasks.contains { task in
                task.category == .work || task.category == .fixed ||
                task.category == .growth || task.category == .reading
            }
        }
        
        _personalTaskBlocks = _selectedDateTaskBlocks.filter { block in
            let blockTasks = _selectedDateTasks.filter { $0.taskBlock?.id == block.id }
            return blockTasks.contains { task in
                task.category == .personal || task.category == .flexible ||
                task.category == .hobbies || task.category == .selfCare ||
                task.category == .leisure || task.category == .skinCare
            }
        }
        
        // 4. Pre-compute grouped items (O(N log N) - done once per date change)
        let workItems = _workTasks.map { TimelineItem.task($0) } +
                       _workTaskBlocks.map { TimelineItem.block($0) }
        _workItemGroups = optimizedGroupOverlappingItems(workItems)
        
        let personalItems = _personalTasks.map { TimelineItem.task($0) } +
                           _personalTaskBlocks.map { TimelineItem.block($0) }
        _personalItemGroups = optimizedGroupOverlappingItems(personalItems)
        
        // Update cache tracking
        _lastCachedDate = selectedDate
        _lastCachedTaskIDs = currentTaskIDs
    }
    
    // MARK: - Optimized Overlap Algorithm (O(N log N) instead of O(N²))
    private func optimizedGroupOverlappingItems(_ items: [TimelineItem]) -> [[TimelineItem]] {
        guard !items.isEmpty else { return [] }
        
        // Sort by start time (O(N log N))
        let sortedItems = items.sorted { itemStart($0) < itemStart($1) }
        
        var groups: [[TimelineItem]] = []
        var currentGroup: [TimelineItem] = []
        var currentEndTime: Date?
        
        // Single pass through sorted items (O(N))
        for item in sortedItems {
            let itemStartTime = itemStart(item)
            let itemEndTime = itemEnd(item)
            
            if let endTime = currentEndTime, itemStartTime < endTime {
                // Overlaps with current group
                currentGroup.append(item)
                currentEndTime = max(currentEndTime ?? itemEndTime, itemEndTime)
            } else {
                // Start new group
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = [item]
                currentEndTime = itemEndTime
            }
        }
        
        // Add final group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        // Sort items within each group by priority then start time
        for i in 0..<groups.count {
            groups[i].sort { item1, item2 in
                let priority1 = getItemPriority(item1)
                let priority2 = getItemPriority(item2)
                if priority1 != priority2 {
                    return priority1 > priority2 // Higher priority first
                }
                return itemStart(item1) < itemStart(item2) // Then by start time
            }
        }
        
        return groups
    }
    
    // MARK: - Helper Functions
    private func itemStart(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.startTime
        case .block(let b):
            let blockTasks = getAllTasksForBlock(b)
            return blockTasks.map { $0.startTime }.min() ?? Date()
        }
    }
    
    private func itemEnd(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.endTime
        case .block(let b):
            let blockTasks = getAllTasksForBlock(b)
            return blockTasks.map { $0.endTime }.max() ?? Date()
        }
    }
    
    private func getItemPriority(_ item: TimelineItem) -> Int {
        switch item {
        case .task(let task):
            switch task.priority {
            case .urgent: return 4
            case .high: return 3
            case .normal: return 2
            case .low: return 1
            }
        case .block(let block):
            let blockTasks = _selectedDateTasks.filter { $0.taskBlock?.id == block.id }
            let priorities = blockTasks.map { task in
                switch task.priority {
                case .urgent: return 4
                case .high: return 3
                case .normal: return 2
                case .low: return 1
                }
            }
            return priorities.max() ?? 1
        }
    }
    
    private func isFromInactiveRoutine(_ task: Task) -> Bool {
        guard let routineID = task.routineID else { return false }
        return routines.first(where: { $0.id == routineID })?.isActive == false
    }
    
    // MARK: - Helper Functions for TimelineView
    func getTasksForBlock(_ taskBlock: TaskBlock, hour: Int) -> [Task] {
        _selectedDateTasks.filter { task in
            task.taskBlock?.id == taskBlock.id &&
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
    
    func getAllTasksForBlock(_ taskBlock: TaskBlock) -> [Task] {
        _selectedDateTasks.filter { $0.taskBlock?.id == taskBlock.id }
    }
    
    func getOverlappingTasks(_ tasks: [Task]) -> [[Task]] {
        var groups: [[Task]] = []
        var processed: Set<String> = []
        
        for task in tasks {
            if processed.contains(task.id) { continue }
            
            var group = [task]
            processed.insert(task.id)
            
            for otherTask in tasks {
                if processed.contains(otherTask.id) { continue }
                
                if task.startTime < otherTask.endTime && otherTask.startTime < task.endTime {
                    group.append(otherTask)
                    processed.insert(otherTask.id)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    // MARK: - Initialization
    init() {
        // Initial data fetch will happen when modelContext is set
    }
    
    // Call this when modelContext is available
    func setupDataService(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Mark as initialized before refreshing to allow didSet to work
        isInitialized = true
        // Now safe to refresh data
        refreshSelectedDateData()
    }
}

// MARK: - TimelineItem Enum (for grouping)
enum TimelineItem: Identifiable {
    case task(Task)
    case block(TaskBlock)
    
    var id: String {
        switch self {
        case .task(let t): return t.id
        case .block(let b): return b.id
        }
    }
}

