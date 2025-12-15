
//  TimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import EventKit
import AudioToolbox

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager
    
    // REVERTED TO ORIGINAL: Simple @Query approach that was working
    @Query private var tasks: [Task]
    @Query private var taskBlocks: [TaskBlock]
    @Query private var goals: [Goal]
    @Query private var users: [User]
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @State private var timer: Timer?
    @State private var showingCalendar = false
    @State private var showingAddTask = false
    @State private var showingAddTaskBlock = false
    
    // Check if selected date is today
    private var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // Drag and drop state
    @State private var draggedTask: Task? = nil
    
    // Collision detection state
    @State private var showingCollisionAlert = false
    @State private var collisionData: (draggedTask: Task?, newStart: Date, newEnd: Date, overlappingTasks: [Task])? = nil
    
    // REVERTED TO ORIGINAL: Simple computed property - no caching complexity
    private var selectedDateTasks: [Task] {
        let calendar = Calendar.current
        let filteredTasks = tasks.filter { task in
            calendar.isDate(task.startTime, inSameDayAs: selectedDate) &&
            // Filter out tasks from paused goals
            !(task.goal != nil && task.goal?.status == .paused)
        }.sorted { $0.startTime < $1.startTime }
        
        return filteredTasks
    }
    
    // Helper to get adjusted display times for a task on the selected date
    private func getDisplayTimes(for task: Task, on date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let taskStart = task.startTime
        let taskEnd = task.endTime
        let taskStartDay = calendar.startOfDay(for: taskStart)
        let taskEndDay = calendar.startOfDay(for: taskEnd)
        let selectedDay = calendar.startOfDay(for: date)
        let startOfSelectedDay = calendar.startOfDay(for: date)
        let endOfSelectedDay = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDay) ?? startOfSelectedDay
        
        // If task starts on a previous day but ends on or after selected day
        if taskStartDay < selectedDay && taskEndDay >= selectedDay {
            // Show continuation from 12:00 AM on selected day
            let displayStart = startOfSelectedDay
            // Keep original end time if it's on selected day, otherwise show to end of day
            let displayEnd = taskEndDay > selectedDay ? endOfSelectedDay : taskEnd
            return (displayStart, displayEnd)
        }
        // If task starts on selected day but ends on next day
        else if taskStartDay == selectedDay && taskEndDay > selectedDay {
            // Show from start time to end of selected day (midnight)
            return (taskStart, endOfSelectedDay)
        }
        // Otherwise, task is fully on selected day - no adjustment needed
        else {
            return (taskStart, taskEnd)
        }
    }
    
    private var currentTime: Date {
        Date()
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }
    
    private var currentMinute: Int {
        Calendar.current.component(.minute, from: currentTime)
    }
    
    // MARK: - Helper Functions
    // Removed isFromInactiveRoutine - now handled in ViewModel
    
    // MARK: - Drag and Drop Functions
    // REVERTED TO ORIGINAL: Simple save without async wrapping
    private func updateTaskTime(_ task: Task, _ newStartTime: Date, _ newEndTime: Date) {
        task.startTime = newStartTime
        task.endTime = newEndTime
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task time: \(error)")
        }
    }
    
    private func updateTaskSide(_ task: Task, _ newSide: TaskTimelineBlock.TimelineSide) {
        // CRITICAL FIX: Ensure task has a valid id before saving (prevents SwiftData crash)
        if task.id.isEmpty {
            task.id = UUID().uuidString
        }
        
        // Map category to the appropriate side while preserving visual color
        // Store original color if not already set
        if task.color == nil {
            task.color = task.category.rawValue // Store original category for color reference
        }
        
        // Update category to match the side for filtering purposes
        // Work-side categories: .work, .fixed, .growth, .reading
        // Personal-side categories: .personal, .flexible, .hobbies, .selfCare, .leisure, .skinCare
        switch newSide {
        case .left: // Work side
            // If current category is personal-side, change to work-side category
            if task.category == .personal || task.category == .flexible ||
                task.category == .hobbies || task.category == .selfCare ||
                task.category == .leisure || task.category == .skinCare {
                task.category = .work
            }
            // Otherwise keep original work-side category
        case .right: // Personal side
            // If current category is work-side, change to personal-side category
            if task.category == .work || task.category == .fixed ||
                task.category == .growth || task.category == .reading {
                task.category = .personal
            }
            // Otherwise keep original personal-side category
        }
        
        // REVERTED TO ORIGINAL: Simple save
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task side: \(error)")
        }
    }
    
    private func updateTaskBlockTime(_ taskBlock: TaskBlock, _ newStartTime: Date, _ newEndTime: Date) {
        // REVERTED TO ORIGINAL: Simple approach using relationship
        let tasksInBlock = tasks.filter { $0.taskBlock?.id == taskBlock.id }
        let duration = newEndTime.timeIntervalSince(newStartTime)
        let taskDuration = duration / Double(tasksInBlock.count)
        
        for (index, task) in tasksInBlock.enumerated() {
            let taskStartTime = newStartTime.addingTimeInterval(taskDuration * Double(index))
            let taskEndTime = taskStartTime.addingTimeInterval(taskDuration)
            
            task.startTime = taskStartTime
            task.endTime = taskEndTime
        }
        
        // REVERTED TO ORIGINAL: Simple save
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task block time: \(error)")
        }
    }
    
    private func updateTaskBlockSide(_ taskBlock: TaskBlock, _ newSide: TaskTimelineBlock.TimelineSide) {
        // REVERTED TO ORIGINAL: Simple approach using relationship
        let tasksInBlock = tasks.filter { $0.taskBlock?.id == taskBlock.id }
        let newCategory = newSide == .left ? TaskCategory.work : TaskCategory.personal
        
        for task in tasksInBlock {
            task.category = newCategory
        }
        
        // REVERTED TO ORIGINAL: Simple save
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task block side: \(error)")
        }
    }
    
    private func handleTaskCollision(task: Task, newStartTime: Date, newEndTime: Date) {
        // Check if the new time overlaps with any existing tasks
        // This is called on DROP, not during drag
        let overlappingTasks = selectedDateTasks.filter { otherTask in
            // Don't check collision with the task being dragged
            if otherTask.id == task.id { return false }
            
            let taskStart = otherTask.startTime
            let taskEnd = otherTask.endTime
            
            // Check for overlap
            return (newStartTime < taskEnd && newEndTime > taskStart)
        }
        
        if !overlappingTasks.isEmpty {
            // Store collision data and show alert
            // The alert will prevent time update until user decides
            collisionData = (draggedTask: task, newStart: newStartTime, newEnd: newEndTime, overlappingTasks: overlappingTasks)
            showingCollisionAlert = true
        }
    }
    
    private func createTaskBlockFromCollision() {
            guard let data = collisionData, let draggedTask = data.draggedTask else { return }
            
            // CRITICAL FIX: Ensure dragged task has a valid id before saving (prevents SwiftData crash)
            if draggedTask.id.isEmpty {
                draggedTask.id = UUID().uuidString
            }
            
            // Create a new task block with a better title
            let taskTitles = data.overlappingTasks.prefix(2).map { $0.title }
            let blockTitle = taskTitles.isEmpty ? "Task Block" : (taskTitles.count == 1 ? "\(taskTitles[0]) Block" : "\(taskTitles[0]) & \(taskTitles.count > 1 ? "\(taskTitles.count - 1) more" : "")")
            
            // ⭐️ FIX: Swapped 'color' and 'priority' to match the initializer order
            let newBlock = TaskBlock(
                id: UUID().uuidString,
                userID: users.first?.id ?? "",
                title: blockTitle,
                color: draggedTask.category.rawValue, // Use dragged task's category color
                priority: draggedTask.priority // Use dragged task's priority
            )
            newBlock.isLocked = false // Set property after initialization
            modelContext.insert(newBlock)
            
            // Add all overlapping tasks to the block
            for task in data.overlappingTasks {
                // CRITICAL FIX: Ensure each task has a valid id before saving (prevents SwiftData crash)
                if task.id.isEmpty {
                    task.id = UUID().uuidString
                }
                task.taskBlock = newBlock
            }
            
            // Update the dragged task's time and add to block
            draggedTask.startTime = data.newStart
            draggedTask.endTime = data.newEnd
            draggedTask.taskBlock = newBlock
            
            // REVERTED TO ORIGINAL: Simple save
            try? modelContext.save()
            showingCollisionAlert = false
            collisionData = nil
        }
    
    private func cancelCollision() {
        // User cancelled - just clear the collision data
        // The task time update was already prevented in updateTaskTime
        showingCollisionAlert = false
        collisionData = nil
    }
    
    private var scrollBasedTime: String {
        // Calculate time based on scroll position
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        let targetDate = Calendar.current.date(bySettingHour: targetHour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return timeSettings.formatTime(targetDate)
    }
    
    private var headerTimeDisplay: String {
        // Show current time if viewing today, otherwise show 00:00 for other days
        if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
            return timeSettings.formatTime(currentTime)
        } else {
            return timeSettings.use24HourFormat ? "00:00" : "12:00 AM"
        }
    }
    
    private var isCurrentTimeInView: Bool {
        // Check if current time hour is in screen view
        if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
            let currentHour = Calendar.current.component(.hour, from: currentTime)
            let hourOffset = Int(abs(scrollOffset) / 120)
            let baseHour = Calendar.current.component(.hour, from: selectedDate)
            let targetHour = (baseHour + hourOffset) % 24
            
            return targetHour == currentHour
        }
        return false
    }
    
    private var totalTimelineHeight: CGFloat {
        // Total height for 24 hours
        return 24 * 120 // 2880 points
    }
    
    private var knotSpacing: CGFloat {
        // Distance between each knot (hour marker)
        return totalTimelineHeight / 24 // 120 points
    }
    
    private func knotPosition(for hour: Int) -> CGFloat {
        // Calculate position of knot for a specific hour
        return CGFloat(hour) * knotSpacing
    }
    
    private func isKnotActive(for hour: Int) -> Bool {
        // Check if a knot should be "lit up" based on current time
        if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
            return hour <= currentHour
        } else {
            return false // For other days, no knots are active
        }
    }
    
    var body: some View {
        let theme = themeManager.currentTheme // Cache theme to prevent multiple accesses
        
        return GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Timeline background - matching home screen style
                theme.primaryGradient
                    .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    // Header (Today button is now in headerView)
                    headerView(theme: theme)
                    
                    // Timeline Content
                    ScrollView {
                        ContinuousTimelineView(
                            tasks: selectedDateTasks,
                            taskBlocks: taskBlocks.filter { block in
                                Calendar.current.isDate(block.createdDate, inSameDayAs: selectedDate)
                            },
                            calendarEvents: calendarManager.getEventsForDate(selectedDate),
                            selectedDate: selectedDate,
                            currentTime: currentTime,
                            workItemGroups: nil, // REVERTED: Compute in ContinuousTimelineView (simpler)
                            personalItemGroups: nil, // REVERTED: Compute in ContinuousTimelineView (simpler)
                            getTasksForBlock: getTasksForBlock,
                            getAllTasksForBlock: getAllTasksForBlock,
                            getOverlappingTasks: getOverlappingTasks,
                            updateTaskTime: updateTaskTime,
                            updateTaskSide: updateTaskSide,
                            updateTaskBlockTime: updateTaskBlockTime,
                            updateTaskBlockSide: updateTaskBlockSide,
                            handleTaskCollision: { task, newStart, newEnd in
                                handleTaskCollision(task: task, newStartTime: newStart, newEndTime: newEnd)
                            },
                            viewMode: .fullView // Always use full view (collapsible removed)
                        )
                        .frame(height: 24 * 120) // Full height
                                .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("timelineScroll")).minY)
                            }
                        )
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // CRITICAL FIX: Infinite Loop Prevention - only update if change is significant
                            // Scroll offset tracking (does NOT trigger task recalculation)
                            // This is for timeline scroll, not day scroller
                            // Today button visibility is handled by isSelectedDateToday
                            if abs(scrollOffset - value) > 2.0 {
                            scrollOffset = value
                            }
                        }
                    }
                    .coordinateSpace(name: "timelineScroll")
                }
            }
            .navigationBarHidden(true)
            .alert("Schedule Overlap", isPresented: $showingCollisionAlert) {
                Button("Cancel", role: .cancel) {
                    cancelCollision()
                }
                Button("Group Tasks", role: .none) {
                    createTaskBlockFromCollision()
                }
            } message: {
                if let data = collisionData {
                    let taskCount = data.overlappingTasks.count + 1 // +1 for the dragged task
                    Text("There is a schedule overlap. Would you like to group these \(taskCount) tasks into a task block?")
                } else {
                    Text("There is a schedule overlap. Would you like to group these tasks into a task block?")
                }
            }
            // Calendar system removed - will be reimplemented with theme
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(selectedDate: selectedDate)
                    .environment(themeManager)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showingAddTaskBlock) {
                AddBlockView(selectedDate: selectedDate)
                    .presentationDetents([.medium])
                    .environment(themeManager)
                    .environment(\.modelContext, modelContext)
            }
            .onAppear {
                startTimer()
            }
                .onDisappear {
                    stopTimer()
            }
        }
    }
    
    // MARK: - Calendar Modal View - REMOVED (will be reimplemented with theme)
    
    // MARK: - Helper Functions
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func headerView(theme: any AppTheme) -> some View {
        VStack(spacing: 16) {
            // Month/Year Header (DEC 2025) and Today Button - Top Row
            HStack {
                // Calendar Button (DEC 2025) - Calendar system removed, will be reimplemented
                Button(action: {
                    // Calendar system removed - will be reimplemented with theme
                }) {
                    Text(monthYearString(from: selectedDate).uppercased())
                        .font(theme.headerFont)
                        .foregroundColor(theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                }
                
                Spacer()
                
                // Today Button - Smooth transition when appearing
                if !isSelectedDateToday {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = Date()
                            DatePersistenceService.shared.saveSelectedDate(selectedDate)
                            calendarManager.loadCalendarEvents(for: selectedDate)
                        }
                    }) {
                        Text("Today")
                            .font(theme.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                            .stroke(theme.accentColor, lineWidth: theme.cardBorderWidth)
                                    )
                            )
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelectedDateToday)
            .padding(.bottom, 4)
            
            // Infinite Day Selector with Fixed Center Controller (ORIGINAL STRUCTURE)
            // REVERTED TO ORIGINAL: Simple binding and callback
            InfiniteDaySelector(
                selectedDate: $selectedDate,
                onDateChanged: { newDate in
                    // Persist selected date
                    DatePersistenceService.shared.saveSelectedDate(newDate)
                    calendarManager.loadCalendarEvents(for: newDate)
                },
                hasEvents: { date in
                    // Optimize: Use cached check instead of heavy computation
                    calendarManager.hasEventsOnDate(date)
                },
                showMonthHeader: true
            )
            
            // Weather Info - Shows weather for selected date (ORIGINAL STRUCTURE)
            ZStack {
                // Background HStack for edge buttons
                HStack {
                    // Work label on left edge - Purple gradient background
                    Text("Work")
                        .font(theme.bodyFont) // Use theme bodyFont (10pt, regular)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentColor.opacity(0.3), theme.accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                        .stroke(theme.accentColor, lineWidth: theme.cardBorderWidth)
                                )
                        )
                    
                    Spacer()
                    
                    // Personal label on right edge - Purple gradient background
                    Text("Personal")
                        .font(theme.bodyFont) // Use theme bodyFont (10pt, regular)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentColor.opacity(0.3), theme.accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                        .stroke(theme.accentColor, lineWidth: theme.cardBorderWidth)
                                )
                        )
                }
                
                // Time box - truly centered in middle (ORIGINAL STRUCTURE)
                Text(headerTimeDisplay)
                    .font(theme.bodyFont) // Use theme bodyFont (10pt, regular)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .fill(Color.clear)
                    .overlay(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black.opacity(0.3), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var hourRange: [Int] {
        Array(0...23)
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func tasksForHour(_ hour: Int) -> [Task] {
        // Filter tasks for selected date and hour
        selectedDateTasks.filter { task in
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
    
    private func calendarEventsForHour(_ hour: Int) -> [EKEvent] {
        calendarManager.getEventsForDate(selectedDate).filter { event in
            Calendar.current.component(.hour, from: event.startDate) == hour
        }
    }
    
    // REVERTED TO ORIGINAL: Check if any task in this block falls within the selected date
    private var taskBlocksForSelectedDate: [TaskBlock] {
        taskBlocks.filter { taskBlock in
            let blockTasks = selectedDateTasks.filter { $0.taskBlock?.id == taskBlock.id }
            return !blockTasks.isEmpty
        }
    }
    
    private func taskBlocksForHour(_ hour: Int) -> [TaskBlock] {
        taskBlocksForSelectedDate.filter { block in
            let blockTasks = getAllTasksForBlock(block)
            return blockTasks.contains { task in
                Calendar.current.component(.hour, from: task.startTime) == hour
            }
        }
    }
    
    // REVERTED TO ORIGINAL: Simple approach using relationship
    private func getTasksForBlock(_ taskBlock: TaskBlock, hour: Int) -> [Task] {
        selectedDateTasks.filter { task in
            task.taskBlock?.id == taskBlock.id &&
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
    
    // New function to get all tasks for a block regardless of hour
    private func getAllTasksForBlock(_ taskBlock: TaskBlock) -> [Task] {
        selectedDateTasks.filter { $0.taskBlock?.id == taskBlock.id }
    }
    
    private func getOverlappingTasks(_ tasks: [Task]) -> [[Task]] {
        // Simple grouping: tasks that overlap in time
        var groups: [[Task]] = []
        var processed: Set<String> = []
        
        for task in tasks {
            if processed.contains(task.id) { continue }
            
            var group = [task]
            processed.insert(task.id)
            
            for otherTask in tasks {
                if processed.contains(otherTask.id) { continue }
                
                // Check if tasks overlap
                if task.startTime < otherTask.endTime && task.endTime > otherTask.startTime {
                    group.append(otherTask)
                    processed.insert(otherTask.id)
                }
            }
            
            if !group.isEmpty {
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func startTimer() {
        // FIX: Timer runs on main thread - structs don't need weak references
        // Note: scheduledTimer already adds timer to current run loop, no need to add again
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // Update every minute to refresh current time
            // Minimal update - just trigger a refresh if needed
            // Don't force full view update to prevent hangs
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Calculate collapsed height based on hours with tasks
    // REMOVED: calculateCollapsedHeight - collapsible mode removed
    private func _calculateCollapsedHeight() -> CGFloat {
        let calendar = Calendar.current
        var hoursWithTasks: Set<Int> = []
        
        // Get all hours that have tasks
        for task in selectedDateTasks {
            let taskHour = calendar.component(.hour, from: task.startTime)
            hoursWithTasks.insert(taskHour)
            // Also include end hour if different
            let endHour = calendar.component(.hour, from: task.endTime)
            if endHour != taskHour {
                hoursWithTasks.insert(endHour)
            }
        }
        
        // Get all hours that have task blocks
        for block in taskBlocksForSelectedDate {
            let blockTasks = selectedDateTasks.filter { $0.taskBlock?.id == block.id }
            for task in blockTasks {
                let taskHour = calendar.component(.hour, from: task.startTime)
                hoursWithTasks.insert(taskHour)
                let endHour = calendar.component(.hour, from: task.endTime)
                if endHour != taskHour {
                    hoursWithTasks.insert(endHour)
                }
            }
        }
        
        // Add padding hours (1 hour before first, 1 hour after last)
        if let firstHour = hoursWithTasks.min(), let lastHour = hoursWithTasks.max() {
            let startHour = max(0, firstHour - 1)
            let endHour = min(23, lastHour + 1)
            let hourCount = endHour - startHour + 1
            return CGFloat(hourCount) * 120 // 120 points per hour
        }
        
        // Default to showing 12 hours if no tasks
        return 12 * 120
    }
}

struct TimelineHourView: View {
    let hour: Int
    let tasks: [Task]
    let taskBlocks: [TaskBlock]
    let calendarEvents: [EKEvent]
    let selectedDate: Date
    let currentTime: Date
    let scrollBasedTime: String
    let scrollOffset: CGFloat
    let getTasksForBlock: (TaskBlock, Int) -> [Task]
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let getOverlappingTasks: ([Task]) -> [[Task]]
    let updateTaskTime: (Task, Date, Date) -> Void
    let updateTaskSide: (Task, TaskTimelineBlock.TimelineSide) -> Void
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Date, Date) -> Void
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    private var hourText: String {
        return timeSettings.formatHour(hour)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            workTasksView
            centralTimelineView
            personalTasksView
        }
        .padding(.horizontal)
    }
    
    // MARK: - Work Tasks View
    private var workTasksView: some View {
        VStack(alignment: .leading, spacing: 4) {
            workTasksList
            workTaskBlocksList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var workTasksList: some View {
        let workTasks = tasks.filter {
            $0.taskBlock == nil &&
            ($0.category == .work || $0.category == .fixed || $0.category == .growth || $0.category == .reading)
        }
        let overlappingWorkGroups = getOverlappingTasks(workTasks)
        
        return ForEach(Array(overlappingWorkGroups.enumerated()), id: \.offset) { index, group in
            HStack(spacing: 2) {
                ForEach(group, id: \.id) { task in
                    UnifiedDraggableTimelineItem(
                        content: {
                            TaskTimelineBlock(task: task, side: .left)
                        },
                        side: .left,
                        isLocked: task.isLocked,
                        startTime: task.startTime,
                        endTime: task.endTime,
                        onTimeChanged: { newStart, newEnd in
                            updateTaskTime(task, newStart, newEnd)
                        },
                        onSideChanged: { newSide in
                            updateTaskSide(task, newSide)
                        },
                        onTaskCollision: { newStart, newEnd in
                            handleTaskCollision(newStart, newEnd)
                        }
                    )
                    .frame(maxWidth: group.count > 1 ? 60 : .infinity)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedDate)
    }
    
    private var workTaskBlocksList: some View {
        ForEach(workTaskBlocks, id: \.id) { taskBlock in
            let blockTasks = getAllTasksForBlock(taskBlock).filter { $0.category == .work }
            let firstTask = blockTasks.first
            let lastTask = blockTasks.last
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskBlockTimelineView(
                        taskBlock: taskBlock,
                        tasks: blockTasks,
                        side: .left
                    )
                },
                side: .left,
                isLocked: taskBlock.isLocked,
                startTime: firstTask?.startTime ?? Date(),
                endTime: lastTask?.endTime ?? Date(),
                onTimeChanged: { newStart, newEnd in
                    updateTaskBlockTime(taskBlock, newStart, newEnd)
                },
                onSideChanged: { newSide in
                    updateTaskBlockSide(taskBlock, newSide)
                },
                onTaskCollision: { newStart, newEnd in
                    handleTaskCollision(newStart, newEnd)
                }
            )
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedDate)
    }
    
    private var workTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getTasksForBlock(block, hour)
            return blockTasks.contains { $0.category == .work }
        }
    }
    
    // MARK: - Central Timeline View
    private var centralTimelineView: some View {
        VStack {
            Text(hourText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.vertical, 4)
            
            ZStack(alignment: .top) {
                // Background timeline
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                
                // 15/30/45 minute marks (always visible for precision)
                minuteMarksOverlay
                
                // Calendar events indicators
                calendarEventsIndicators
                
                // Current time indicator
                currentTimeIndicator
            }
        }
        .frame(width: 60)
    }
    
    // Minute marks overlay - shows 15, 30, 45 minute intervals
    private var minuteMarksOverlay: some View {
        VStack(spacing: 0) {
            ForEach([15, 30, 45], id: \.self) { minute in
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 6, height: 1)
                    .offset(y: CGFloat(minute) * 2 - 60) // 2 points per minute, center at hour
            }
        }
    }
    
    private var calendarEventsIndicators: some View {
        ForEach(calendarEvents, id: \.eventIdentifier) { event in
            let startMinute = Calendar.current.component(.minute, from: event.startDate)
            let duration = event.endDate.timeIntervalSince(event.startDate)
            let durationMinutes = duration / 60
            
            VStack(spacing: 0) {
                // Event indicator dot
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .offset(y: CGFloat(startMinute) * 2) // 2 points per minute
                
                // Event duration bar
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 4, height: CGFloat(durationMinutes) * 2)
                    .offset(y: CGFloat(startMinute) * 2)
            }
        }
    }
    
    private var currentTimeIndicator: some View {
        Group {
            if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
                let currentHour = Calendar.current.component(.hour, from: currentTime)
                let isCurrentHour = hour == currentHour
                
                if isCurrentHour {
                    Text(timeSettings.formatTime(currentTime))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        )
                        .offset(y: 20)
                }
            }
        }
    }
    
    // MARK: - Personal Tasks View
    private var personalTasksView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            personalTasksList
            personalTaskBlocksList
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var personalTasksList: some View {
        let personalTasks = tasks.filter {
            $0.taskBlock == nil &&
            ($0.category == .personal || $0.category == .flexible ||
             $0.category == .hobbies || $0.category == .selfCare ||
             $0.category == .leisure || $0.category == .skinCare)
        }
        let overlappingPersonalGroups = getOverlappingTasks(personalTasks)
        
        return ForEach(Array(overlappingPersonalGroups.enumerated()), id: \.offset) { index, group in
            HStack(spacing: 2) {
                ForEach(group, id: \.id) { task in
                    UnifiedDraggableTimelineItem(
                        content: {
                            TaskTimelineBlock(task: task, side: .right)
                        },
                        side: .right,
                        isLocked: task.isLocked,
                        startTime: task.startTime,
                        endTime: task.endTime,
                        onTimeChanged: { newStart, newEnd in
                            updateTaskTime(task, newStart, newEnd)
                        },
                        onSideChanged: { newSide in
                            updateTaskSide(task, newSide)
                        },
                        onTaskCollision: { newStart, newEnd in
                            handleTaskCollision(newStart, newEnd)
                        }
                    )
                    .frame(maxWidth: group.count > 1 ? 60 : .infinity)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedDate)
    }
    
    private var personalTaskBlocksList: some View {
        ForEach(personalTaskBlocks, id: \.id) { taskBlock in
            let blockTasks = getAllTasksForBlock(taskBlock).filter { $0.category == .personal }
            let firstTask = blockTasks.first
            let lastTask = blockTasks.last
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskBlockTimelineView(
                        taskBlock: taskBlock,
                        tasks: blockTasks,
                        side: .right
                    )
                },
                side: .right,
                isLocked: taskBlock.isLocked,
                startTime: firstTask?.startTime ?? Date(),
                endTime: lastTask?.endTime ?? Date(),
                onTimeChanged: { newStart, newEnd in
                    updateTaskBlockTime(taskBlock, newStart, newEnd)
                },
                onSideChanged: { newSide in
                    updateTaskBlockSide(taskBlock, newSide)
                },
                onTaskCollision: { newStart, newEnd in
                    handleTaskCollision(newStart, newEnd)
                }
            )
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedDate)
    }
    
    private var personalTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getTasksForBlock(block, hour)
            return blockTasks.contains { $0.category == .personal }
        }
    }
}

struct TaskTimelineBlock: View {
    let task: Task
    let side: TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    enum TimelineSide {
        case left, right
    }
    
    private var taskHeight: CGFloat {
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let minutes = duration / 60
        // Each hour is 120 points, so each minute is 2 points
        // Minimum height of 20 points (10 minutes)
        return max(20, CGFloat(minutes) * 2)
    }
    
    // Priority-based outline color
    private var priorityOutlineColor: Color {
        switch task.priority {
        case .urgent: return .red.opacity(0.9)
        case .high: return .orange.opacity(0.9)
        case .normal: return .green.opacity(0.9) // Changed from green
        case .low: return .blue.opacity(0.9)
        }
    }
    
    // Border color - darker shade of the same category color
    private var borderColor: Color {
        categoryBackgroundColor.opacity(0.6)
    }
    
    // Category-based background color - MORE TRANSPARENT
    private var categoryBackgroundColor: Color {
        // If task.color is set, it contains the original category name - use that for color
        if let originalCategoryString = task.color,
           let originalCategory = TaskCategory(rawValue: originalCategoryString) {
            return originalCategory.color().opacity(0.5) // Increased transparency from 0.85
        }
        // Otherwise use current category color
        return task.category.color().opacity(0.5) // Increased transparency from 0.85
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 4) {
            // Task title with routine indicator
            HStack(spacing: 4) {
                if side == .left {
                    if task.isRoutineTask {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                    Text(task.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else {
                    Text(task.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    if task.isRoutineTask {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
            }
            .multilineTextAlignment(side == .left ? .leading : .trailing)
            
            // Time range
            Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            // Priority indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(priorityOutlineColor)
                    .frame(width: 6, height: 6)
                
                Text(task.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: taskHeight, alignment: side == .left ? .leading : .trailing)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryBackgroundColor) // Already darker, no need for additional opacity
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2) // Darker shade of same color
                )
        )
        .overlay(
            // Lock icon for locked tasks - BOTTOM RIGHT CORNER
            Group {
                if task.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                        .offset(x: -8, y: -8) // Bottom-right corner - within element space
                }
            },
            alignment: .bottomTrailing
        )
    }
}

struct TaskBlockTimelineView: View {
    let taskBlock: TaskBlock
    let tasks: [Task]
    let side: TaskTimelineBlock.TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    private var blockHeight: CGFloat {
        // Calculate from first task start to last task end
        guard let firstTask = tasks.sorted(by: { $0.startTime < $1.startTime }).first,
              let lastTask = tasks.sorted(by: { $0.endTime < $1.endTime }).last else {
            return 40
        }
        let duration = lastTask.endTime.timeIntervalSince(firstTask.startTime)
        let minutes = duration / 60
        // Each hour is 120 points, so each minute is 2 points
        // Minimum height of 30 points
        return max(30, CGFloat(minutes) * 2)
    }
    
    private var blockColor: Color {
        switch taskBlock.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    private var categoryColor: Color {
        // Use the category color of the first task, or default to blue - MORE TRANSPARENT
        if let firstTask = tasks.first {
            return firstTask.category.color().opacity(0.5) // Increased transparency from 0.85
        }
        return Color.blue.opacity(0.5) // Increased transparency from 0.85
    }
    
    // ⭐️ FIX 2: Break body into helper views
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Beautiful storage container design with overlapped tasks visualization
            VStack(alignment: side == .left ? .leading : .trailing, spacing: 0) {
                headerView
                stackedTasksView
                timeRangeView
            }
        }
        .frame(maxWidth: .infinity, minHeight: blockHeight, alignment: side == .left ? .leading : .trailing)
        .background(
            // Beautiful storage container with darker border
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoryColor.opacity(0.6), lineWidth: 2) // Darker shade of same color
                )
        )
        .overlay(lockOverlay, alignment: .bottomTrailing)
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 6) {
            // Priority indicator
            Circle()
                .fill(blockColor)
                .frame(width: 8, height: 8)
            
            Text(taskBlock.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Task count badge
            Text("\(tasks.count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var stackedTasksView: some View {
        // Overlapped tasks visualization - show first few task titles stacked
        if tasks.count > 1 {
            VStack(alignment: side == .left ? .leading : .trailing, spacing: -4) {
                ForEach(Array(tasks.prefix(3).enumerated()), id: \.element.id) { index, task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(task.category.color().opacity(0.9))
                            .frame(width: 4, height: 4)
                        
                        Text(task.title)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
    
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(task.category.color().opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(task.category.color().opacity(0.5), lineWidth: 1)
                            )
                    )
                    .offset(x: CGFloat(index * 3), y: CGFloat(index * 2))
                    .zIndex(Double(tasks.count - index))
                }
                
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .offset(x: CGFloat(3 * 3), y: CGFloat(3 * 2))
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var timeRangeView: some View {
        // Time range
        if let firstTask = tasks.first, let lastTask = tasks.last {
            let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
            let startTime = sortedTasks.first?.startTime ?? firstTask.startTime
            let endTime = sortedTasks.last?.endTime ?? lastTask.endTime
            
            // Time range without clock icon (removed per user request)
            Text("\(timeSettings.formatTime(startTime)) - \(timeSettings.formatTime(endTime))")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var lockOverlay: some View {
        // Lock icon for locked task blocks
        Group {
            if taskBlock.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.7))
                    )
                    .offset(x: -8, y: -8)
            }
        }
    }
}


#Preview {
    TimelineView()
        .modelContainer(for: [Task.self], inMemory: true)
}
// ScrollOffsetPreferenceKey is defined in InfiniteDaySelector.swift to avoid redeclaration

