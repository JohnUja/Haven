//
//  HomeDashboardViewModel.swift
//  Haven2.0
//
//  Created by John Uja
//  MVVM Architecture: All business logic, state, and data fetching for HomeDashboardView
//

import SwiftUI
import SwiftData
import Combine
import FirebaseAuth
import AudioToolbox

// MARK: - Shared Enums (Move to DataStubs if needed elsewhere)
enum HomeMode: String, CaseIterable {
    case focus = "Focus"
    case plan = "Plan"
}

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case category = "Category"
    case goals = "Goals"
    case priority = "Priority"
    case timePeriod = "Time Period"
    case status = "Status"
    case dateRange = "Date Range"
}

enum TaskSortOrder: String, CaseIterable {
    case priority = "Priority"
    case mostRecent = "Most Recent"
    case timeSensitive = "Time Sensitive"
    case category = "Category"
    case goal = "Goal"
}

enum HomeViewMode: String, CaseIterable {
    case tasks = "Tasks"
    case goals = "Goals"
}

// MARK: - ViewModel
@MainActor
@Observable
final class HomeDashboardViewModel {
    // MARK: - Dependencies
    var modelContext: ModelContext?
    
    // MARK: - Data (injected from View's @Query)
    // Note: Only users and routines are kept in memory (small datasets)
    // Tasks, taskBlocks, and goals are queried on-demand with predicates
    var users: [User] = []
    var routines: [DailyRoutine] = []
    
    // Cached filtered data (updated when selectedDate changes)
    private var _selectedDateTasks: [Task] = []
    private var _selectedDateTaskBlocks: [TaskBlock] = []
    private var _allGoals: [Goal] = []
    
    // Update data from View (only for users and routines)
    func updateData(users: [User], routines: [DailyRoutine]) {
        self.users = users
        self.routines = routines
    }
    
    // Fetch filtered tasks for selected date using SwiftData predicate
    func refreshSelectedDateData() {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
        
        // Query tasks that overlap with selected date
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
            print("Failed to fetch tasks: \(error)")
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
            print("Failed to fetch task blocks: \(error)")
            _selectedDateTaskBlocks = []
        }
        
        // Fetch all goals (needed for filtering and sorting)
        do {
            let goalDescriptor = FetchDescriptor<Goal>()
            _allGoals = try modelContext.fetch(goalDescriptor)
        } catch {
            print("Failed to fetch goals: \(error)")
            _allGoals = []
        }
    }
    
    // MARK: - State Properties
    var selectedDate: Date = {
        // Priority: 1. Last worked date, 2. Last selected date, 3. Today
        if let lastWorkedDate = DatePersistenceService.shared.restoreLastWorkedDate() {
            return lastWorkedDate
        }
        if let lastSelectedDate = DatePersistenceService.shared.restoreSelectedDate() {
            return lastSelectedDate
        }
        return Date()
    }()
    
    var showingAddTask = false
    var showingCalendar = false
    var currentTime = Date()
    var showingAddBlock = false
    var taskSortOrder: TaskSortOrder = .timeSensitive
    var viewMode: HomeViewMode = .tasks
    var recentlyCompletedTasks: Set<String> = []
    var showingEditTask: Task? = nil
    var showingProgressDetails = false
    var showingFloatingMenu: Task? = nil
    var showingFloatingMenuForBlock: [Task]? = nil
    var showingMoveToDay: Task? = nil
    var showingMoveToDayBlock: [Task]? = nil
    var showingUndoMove: Task? = nil
    var showingUndoMoveBlock: [Task]? = nil
    nonisolated(unsafe) var undoMoveTimer: Timer? = nil
    var originalTaskDates: [String: Date] = [:]
    var originalBlockDates: [String: [Date]] = [:]
    var showingCompletionRingPopup = false
    var showingCategoryChange: Task? = nil
    var showingEditBlock: (taskBlock: TaskBlock, tasks: [Task])? = nil
    var showingBlockColorPicker: TaskBlock? = nil
    var pendingDeleteBlockTasks: [Task]? = nil
    var showDeleteBlockAlert = false
    var showingGoalFloatingMenu: Goal? = nil
    var showingEditGoal: Goal? = nil
    var showingAddTaskToGoal: Goal? = nil
    var showingLinkTaskToGoal: Task? = nil
    var showingDeleteGoalConfirmation: Goal? = nil
    var showingPauseGoalConfirmation: Goal? = nil
    var selectedGoal: Goal? = nil
    var showingLevelUp: LevelUpResult? = nil
    var isShowingLevelUp = false
    var levelUpNotificationObserver: Set<AnyCancellable> = []
    var showingDailySummary: DailySummary? = nil
    var dailyXPTotal: Int = 0
    var dailyCrystalsTotal: Int = 0
    var dailyBonuses: [String] = []
    var showingImmersiveWorkingOn = false
    var homeMode: HomeMode = .focus
    var showingDayPickerInPlan = false
    var selectedFilter: TaskFilter = .all
    var showingLevelToggle = false
    var previewTaskForDynamicBox: Task? = nil
    var showingRecents = false
    var isViewAllTasksMode = false // For Dynamic Box mode toggle
    
    // MARK: - Computed Properties
    var currentUser: User? {
        users.first
    }
    
    var userRoutines: [DailyRoutine] {
        guard let user = currentUser else { return [] }
        return routines.filter { $0.userID == user.id }
    }
    
    var selectedDateTasks: [Task] {
        // Sort the cached filtered tasks
        let filteredTasks = _selectedDateTasks
        
        // Separate completed and incomplete tasks
        let incompleteTasks = filteredTasks.filter { !$0.isComplete }
        let completedTasks = filteredTasks.filter { $0.isComplete }
        
        // Further separate recently completed tasks
        let recentlyCompleted = completedTasks.filter { recentlyCompletedTasks.contains($0.id) }
        let oldCompleted = completedTasks.filter { !recentlyCompletedTasks.contains($0.id) }
        
        let sortedIncomplete: [Task]
        let sortedCompleted: [Task]
        
        switch taskSortOrder {
        case .priority:
            let priorityOrder: [PriorityType] = [.urgent, .high, .normal]
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                let task1Index = priorityOrder.firstIndex(of: task1.priority) ?? 2
                let task2Index = priorityOrder.firstIndex(of: task2.priority) ?? 2
                return task1Index < task2Index
            }
            sortedCompleted = oldCompleted.sorted { task1, task2 in
                let task1Index = priorityOrder.firstIndex(of: task1.priority) ?? 2
                let task2Index = priorityOrder.firstIndex(of: task2.priority) ?? 2
                return task1Index < task2Index
            } + recentlyCompleted.sorted { task1, task2 in
                let task1Index = priorityOrder.firstIndex(of: task1.priority) ?? 2
                let task2Index = priorityOrder.firstIndex(of: task2.priority) ?? 2
                return task1Index < task2Index
            }
        case .mostRecent:
            sortedIncomplete = incompleteTasks.sorted { $0.startTime > $1.startTime }
            sortedCompleted = oldCompleted.sorted { $0.startTime > $1.startTime } + recentlyCompleted.sorted { $0.startTime > $1.startTime }
        case .timeSensitive:
            let now = Date()
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            }
            sortedCompleted = oldCompleted.sorted { task1, task2 in
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            } + recentlyCompleted.sorted { task1, task2 in
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            }
        case .category:
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                task1.category.rawValue < task2.category.rawValue
            }
            sortedCompleted = oldCompleted.sorted { task1, task2 in
                task1.category.rawValue < task2.category.rawValue
            } + recentlyCompleted.sorted { task1, task2 in
                task1.category.rawValue < task2.category.rawValue
            }
        case .goal:
            // Sort by goal: goal tasks first, then by goal name
            func goalSortValue(_ task: Task) -> String {
                guard let goal = task.goal else {
                    return "zzz_no_goal"
                }
                return goal.title
            }
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                goalSortValue(task1) < goalSortValue(task2)
            }
            sortedCompleted = oldCompleted.sorted { task1, task2 in
                goalSortValue(task1) < goalSortValue(task2)
            } + recentlyCompleted.sorted { task1, task2 in
                goalSortValue(task1) < goalSortValue(task2)
            }
        }
        
        return sortedIncomplete + sortedCompleted
    }
    
    var selectedDateTaskBlocks: [TaskBlock] {
        // Return cached filtered task blocks
        return _selectedDateTaskBlocks
    }
    
    var sortedGoals: [Goal] {
        // Separate active and paused goals
        let activeGoals = _allGoals.filter { $0.status != .paused }
        let pausedGoals = _allGoals.filter { $0.status == .paused }
        
        // Sort active goals
        let sortedActive = activeGoals.sorted { g1, g2 in
            if g1.effectivePriority.order != g2.effectivePriority.order {
                return g1.effectivePriority.order > g2.effectivePriority.order
            }
            if let d1 = g1.deadline, let d2 = g2.deadline {
                return d1 < d2
            } else if g1.deadline != nil {
                return true
            } else if g2.deadline != nil {
                return false
            }
            return g1.title < g2.title
        }
        
        // Sort paused goals by creation date (most recent first)
        let sortedPaused = pausedGoals.sorted { $0.createdAt > $1.createdAt }
        
        // Return active goals first, then paused goals at the bottom
        return sortedActive + sortedPaused
    }
    
    // MARK: - Initialization
    init() {
        setupTimeRefresh()
    }
    
    // Call this when selectedDate changes to refresh filtered data
    func onSelectedDateChanged() {
        refreshSelectedDateData()
    }
    
    // MARK: - Time Refresh Timer
    nonisolated(unsafe) private var timeRefreshTimer: Timer?
    
    private func setupTimeRefresh() {
        timeRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.currentTime = Date()
            }
        }
    }
    
    func stopTimeRefresh() {
        timeRefreshTimer?.invalidate()
        timeRefreshTimer = nil
    }
    
    // MARK: - Business Logic Functions
    
    func checkAndShowDailySummary() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all tasks for today (query on demand)
        let todayTasks: [Task]
        if let modelContext = modelContext {
            let startOfToday = calendar.startOfDay(for: today)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? today
            let predicate = #Predicate<Task> { task in
                task.startTime < endOfToday && task.endTime >= startOfToday
            }
            let descriptor = FetchDescriptor<Task>(predicate: predicate)
            todayTasks = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            todayTasks = []
        }
        
        // Check if all tasks for today are completed (need at least 2 tasks to avoid single-task issue)
        let allTasksComplete = todayTasks.count >= 2 && todayTasks.allSatisfy { $0.isComplete }
        
        if allTasksComplete && dailyXPTotal > 0 {
            // Get mood entries for today
            let todayMoodEntries: [MoodEntry]
            if let user = currentUser, let moodHistory = user.moodHistory {
                todayMoodEntries = moodHistory.filter { entry in
                    calendar.isDate(entry.timestamp, inSameDayAs: today)
                }
            } else {
                todayMoodEntries = []
            }
            
            let summary = DailySummary(
                date: Date(),
                tasksCompleted: todayTasks.count,
                xpGained: dailyXPTotal,
                crystalsGained: dailyCrystalsTotal,
                bonuses: dailyBonuses,
                moodsRecorded: todayMoodEntries.map { moodTypeFromCoreMood($0.coreMood) }
            )
            
            showingDailySummary = summary
            
            // Reset daily totals after showing summary
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dailyXPTotal = 0
                self.dailyCrystalsTotal = 0
                self.dailyBonuses = []
            }
        }
    }
    
    func checkEarnedRewardsOnAppOpen() {
        // Check if we should show rewards from previous session
        guard let rewardInfo = DailyRewardService.shared.checkForEarnedRewards() else {
            return
        }
        
        let calendar = Calendar.current
        let checkDate = rewardInfo.date
        
        // Get completed tasks from that date (query on demand)
        let completedTasks: [Task]
        if let modelContext = modelContext {
            let startOfDate = calendar.startOfDay(for: checkDate)
            let endOfDate = calendar.date(byAdding: .day, value: 1, to: startOfDate) ?? checkDate
            let predicate = #Predicate<Task> { task in
                task.startTime < endOfDate && task.endTime >= startOfDate && task.isComplete == true
            }
            let descriptor = FetchDescriptor<Task>(predicate: predicate)
            completedTasks = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            completedTasks = []
        }
        
        // Calculate XP and crystals earned
        var totalXP = 0
        var totalCrystals = 0
        
        if let user = currentUser {
            for task in completedTasks {
                let goal = task.goal
                let momentumBonus = GamificationService.getMomentumBonus(user: user)
                let baseRewards = GamificationService.calculateTaskRewards(
                    task: task,
                    goal: goal,
                    momentumBonus: momentumBonus
                )
                let timeBasedRewards = GamificationService.calculateTimeBasedTaskRewards(task: task)
                
                totalXP += baseRewards.xp + timeBasedRewards.xp
                totalCrystals += baseRewards.crystals + timeBasedRewards.crystals
            }
        }
        
        // Only show if there are meaningful rewards
        if totalXP > 0 || totalCrystals > 0 {
            let summary = DailySummary(
                date: checkDate,
                tasksCompleted: completedTasks.count,
                xpGained: totalXP,
                crystalsGained: totalCrystals,
                bonuses: [],
                moodsRecorded: []
            )
            
            // Show after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showingDailySummary = summary
            }
        }
    }
    
    func isFromInactiveRoutine(_ task: Task) -> Bool {
        guard let routineID = task.routineID else { return false }
        if let routine = routines.first(where: { $0.id == routineID }) {
            return !routine.isActive
        }
        return false
    }
    
    func getTaskBlock(for blockID: String) -> TaskBlock? {
        // Query on demand
        guard let modelContext = modelContext else { return nil }
        let predicate = #Predicate<TaskBlock> { block in
            block.id == blockID
        }
        let descriptor = FetchDescriptor<TaskBlock>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }
    
    func handleLevelUp(levelUp: LevelUpResult) {
        guard let modelContext = modelContext else { return }
        
        // Query themes dynamically for this level
        let themes: [Theme] = (try? modelContext.fetch(FetchDescriptor<Theme>())) ?? []
        let unlockedThemeIDs = LevelService.getUnlockedThemes(level: levelUp.newLevel, themes: themes)
        
        // Create updated level up result with actual unlocked themes
        let updatedLevelUp = LevelUpResult(
            newLevel: levelUp.newLevel,
            unlockedThemes: unlockedThemeIDs,
            unlockedFeatures: [] // No feature unlocks
        )
        
        showingLevelUp = updatedLevelUp
        
        // Auto-unlock themes in user's ownedThemeIDs
        if let user = currentUser {
            for themeID in unlockedThemeIDs {
                if !user.ownedThemeIDs.contains(themeID) {
                    user.ownedThemeIDs.append(themeID)
                }
            }
            try? modelContext.save()
        }
    }
    
    func handleTaskCompleted(_ taskId: String) {
        recentlyCompletedTasks.insert(taskId)
        
        // Remove from recently completed after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.recentlyCompletedTasks.remove(taskId)
        }
    }
    
    func moveTaskToDay(_ task: Task, to targetDate: Date) {
        guard let modelContext = modelContext else { return }
        
        // Store original date for undo
        originalTaskDates[task.id] = task.startTime
        
        // Update task date
        let calendar = Calendar.current
        let targetStartOfDay = calendar.startOfDay(for: targetDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: task.startTime)
        let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: targetStartOfDay) ?? targetDate
        
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let newEndTime = newStartTime.addingTimeInterval(duration)
        
        task.startTime = newStartTime
        task.endTime = newEndTime
        
        // Show undo notification
        showingUndoMove = task
        
        try? modelContext.save()
        
        // Auto-hide undo after 5 seconds
        undoMoveTimer?.invalidate()
        let taskId = task.id
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.showingUndoMove = nil
                self?.originalTaskDates.removeValue(forKey: taskId)
            }
        }
    }
    
    func moveTaskBlockToDay(_ taskBlock: [Task], to targetDate: Date) {
        guard let modelContext = modelContext else { return }
        
        // Store original dates for undo
        let originalDates = taskBlock.map { $0.startTime }
        let blockId = taskBlock.first?.id ?? UUID().uuidString
        originalBlockDates[blockId] = originalDates
        
        // Update all tasks in the block
        let calendar = Calendar.current
        let targetStartOfDay = calendar.startOfDay(for: targetDate)
        
        for task in taskBlock {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: task.startTime)
            let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: targetStartOfDay) ?? targetDate
            
            let duration = task.endTime.timeIntervalSince(task.startTime)
            let newEndTime = newStartTime.addingTimeInterval(duration)
            
            task.startTime = newStartTime
            task.endTime = newEndTime
        }
        
        // Show undo notification
        showingUndoMoveBlock = taskBlock
        
        try? modelContext.save()
        
        // Auto-hide undo after 5 seconds
        undoMoveTimer?.invalidate()
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.showingUndoMoveBlock = nil
                self?.originalBlockDates.removeValue(forKey: blockId)
            }
        }
    }
    
    func undoMoveTask(_ task: Task) {
        guard let modelContext = modelContext, let originalDate = originalTaskDates[task.id] else { return }
        
        // Restore original date
        let calendar = Calendar.current
        let originalStartOfDay = calendar.startOfDay(for: originalDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: originalDate)
        let restoredStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: originalStartOfDay) ?? originalDate
        
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let restoredEndTime = restoredStartTime.addingTimeInterval(duration)
        
        task.startTime = restoredStartTime
        task.endTime = restoredEndTime
        
        // Clean up
        originalTaskDates.removeValue(forKey: task.id)
        try? modelContext.save()
    }
    
    func undoMoveTaskBlock(_ taskBlock: [Task]) {
        guard let modelContext = modelContext else { return }
        
        let blockId = taskBlock.first?.id ?? UUID().uuidString
        guard let originalDates = originalBlockDates[blockId] else { return }
        
        // Restore original dates for all tasks in the block
        let calendar = Calendar.current
        
        for (index, task) in taskBlock.enumerated() {
            if index < originalDates.count {
                let originalDate = originalDates[index]
                let originalStartOfDay = calendar.startOfDay(for: originalDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: originalDate)
                let restoredStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: originalStartOfDay) ?? originalDate
                
                let duration = task.endTime.timeIntervalSince(task.startTime)
                let restoredEndTime = restoredStartTime.addingTimeInterval(duration)
                
                task.startTime = restoredStartTime
                task.endTime = restoredEndTime
            }
        }
        
        // Clean up
        originalBlockDates.removeValue(forKey: blockId)
        try? modelContext.save()
    }
    
    func deleteTask(_ task: Task) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    func deleteTaskBlock(_ tasks: [Task]) {
        guard let modelContext = modelContext else { return }
        for task in tasks {
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
    
    func syncUserStatsToFirestore(user: User) {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            // Not logged in or guest - don't sync
            return
        }
        
        // Sync in background (non-blocking)
        _Concurrency.Task.detached {
            do {
                try await FirestoreService.shared.syncGamificationStats(
                    uid: uid,
                    level: user.level,
                    currentXP: user.currentXP,
                    nextLevelXP: user.nextLevelXP,
                    crystals: user.gamificationCurrency,
                    momentumDays: user.momentumDays,
                    lastMomentumUpdate: user.lastMomentumUpdate,
                    weeklyProductivityScore: user.weeklyProductivityScore,
                    weeklyResetDate: user.weeklyResetDate
                )
                
                // Sync theme unlocks
                try await FirestoreService.shared.syncThemeUnlocks(
                    uid: uid,
                    ownedThemeIDs: user.ownedThemeIDs,
                    activeThemeID: user.activeThemeID
                )
            } catch {
                print("FirestoreService: Failed to sync user stats: \(error)")
                // Don't show error to user - background sync can fail silently
            }
        }
    }
    
    // MARK: - Plan View Filter Functions
    func getFilteredTasks() -> [Task] {
        // Apply selected filter
        switch selectedFilter {
        case .all:
            return selectedDateTasks
        case .category:
            return selectedDateTasks // Will be grouped by category in UI
        case .goals:
            return selectedDateTasks.filter { $0.goal != nil }
        case .priority:
            return selectedDateTasks // Will be grouped by priority in UI
        case .timePeriod:
            return selectedDateTasks // Will be grouped by time period in UI
        case .status:
            return selectedDateTasks // Will be grouped by status (complete/incomplete) in UI
        case .dateRange:
            return selectedDateTasks
        }
    }
    
    func groupTasksByFilter(_ tasks: [Task]) -> [String: [Task]] {
        var grouped: [String: [Task]] = [:]
        
        switch selectedFilter {
        case .category:
            for task in tasks {
                let categoryName = task.category.displayName
                if grouped[categoryName] == nil {
                    grouped[categoryName] = []
                }
                grouped[categoryName]?.append(task)
            }
        case .priority:
            for task in tasks {
                let priorityName = task.priority.rawValue.capitalized
                if grouped[priorityName] == nil {
                    grouped[priorityName] = []
                }
                grouped[priorityName]?.append(task)
            }
        case .timePeriod:
            for task in tasks {
                let hour = Calendar.current.component(.hour, from: task.startTime)
                let period: String
                switch hour {
                case 5..<12: period = "Morning"
                case 12..<17: period = "Afternoon"
                case 17..<21: period = "Evening"
                default: period = "Night"
                }
                if grouped[period] == nil {
                    grouped[period] = []
                }
                grouped[period]?.append(task)
            }
        case .status:
            let completed = tasks.filter { $0.isComplete }
            let incomplete = tasks.filter { !$0.isComplete }
            if !completed.isEmpty {
                grouped["Completed"] = completed
            }
            if !incomplete.isEmpty {
                grouped["Incomplete"] = incomplete
            }
        default:
            grouped["All Tasks"] = tasks
        }
        
        return grouped
    }
    
    // MARK: - Helper Functions
    func moodTypeFromCoreMood(_ coreMood: CoreMood) -> MoodType {
        switch coreMood {
        case .happy: return .happy
        case .sad: return .sad
        case .anxious: return .anxious
        case .calm: return .calm
        case .energetic: return .energetic
        case .tired: return .tired
        }
    }
    
    func getRecentItems() -> [Any] {
        var items: [Any] = []
        
        // Get recent tasks (last 10) - query on demand
        let recentTasks: [Task]
        if let modelContext = modelContext {
            var descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\Task.startTime, order: .reverse)]
            )
            descriptor.fetchLimit = 10
            let fetched = try? modelContext.fetch(descriptor)
            recentTasks = fetched ?? []
        } else {
            recentTasks = []
        }
        items.append(contentsOf: recentTasks)
        
        // Get recent goals (last 5)
        let recentGoals = Array(_allGoals.sorted { $0.createdAt > $1.createdAt }.prefix(5))
        items.append(contentsOf: recentGoals)
        
        // Get recent task blocks (last 5) - query on demand
        let recentBlocks: [TaskBlock]
        if let modelContext = modelContext {
            var descriptor = FetchDescriptor<TaskBlock>(
                sortBy: [SortDescriptor(\TaskBlock.createdDate, order: .reverse)]
            )
            descriptor.fetchLimit = 5
            let fetched = try? modelContext.fetch(descriptor)
            recentBlocks = fetched ?? []
        } else {
            recentBlocks = []
        }
        items.append(contentsOf: recentBlocks)
        
        // Sort all by creation date and return top 20
        return items.sorted { item1, item2 in
            let date1: Date
            let date2: Date
            
            if let task1 = item1 as? Task {
                date1 = task1.startTime // Task doesn't have createdAt, use startTime
            } else if let goal1 = item1 as? Goal {
                date1 = goal1.createdAt
            } else if let block1 = item1 as? TaskBlock {
                date1 = block1.createdDate
            } else {
                date1 = Date.distantPast
            }
            
            if let task2 = item2 as? Task {
                date2 = task2.startTime // Task doesn't have createdAt, use startTime
            } else if let goal2 = item2 as? Goal {
                date2 = goal2.createdAt
            } else if let block2 = item2 as? TaskBlock {
                date2 = block2.createdDate
            } else {
                date2 = Date.distantPast
            }
            
            return date1 > date2
        }.prefix(20).map { $0 }
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit is nonisolated, so we can't call main actor methods
        // Just invalidate timers directly
        timeRefreshTimer?.invalidate()
        undoMoveTimer?.invalidate()
    }
}

