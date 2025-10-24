//
//  TimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import EventKit
import TimelineTypes
// import WeatherKit
// import CoreLocation

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @Query private var taskBlocks: [TaskBlock]
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @StateObject private var weatherManager = WeatherManager()
    @State private var timer: Timer?
    
    @State private var showingCollisionAlert = false
    @State private var collisionData: (newStart: Date, newEnd: Date, overlappingTasks: [Task])?
    
    private var selectedDateTasks: [Task] {
        let calendar = Calendar.current
        let filteredTasks = tasks.filter { task in
            calendar.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
        
        // Debug: Print what we're looking for vs what we found
        print("Looking for tasks on: \(selectedDate)")
        print("Found \(filteredTasks.count) tasks:")
        for task in filteredTasks {
            print("  - \(task.title) at \(task.startTime)")
        }
        
        return filteredTasks
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
    
    // MARK: - Drag and Drop Functions
    private func updateTaskTime(_ task: Task, _ newStartTime: Date, _ newEndTime: Date) {
        task.startTime = newStartTime
        task.endTime = newEndTime
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task time: \(error)")
        }
    }
    
    private func updateTaskSide(_ task: Task, _ newSide: TimelineSide) {
        // Update task category based on side
        task.category = newSide == .left ? .work : .personal
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task side: \(error)")
        }
    }
    
    private func updateTaskBlockTime(_ taskBlock: TaskBlock, _ newStartTime: Date, _ newEndTime: Date) {
        // Update all tasks in the block
        let tasksInBlock = tasks.filter { $0.taskBlockID == taskBlock.id }
        let duration = newEndTime.timeIntervalSince(newStartTime)
        let taskDuration = duration / Double(tasksInBlock.count)
        
        for (index, task) in tasksInBlock.enumerated() {
            let taskStartTime = newStartTime.addingTimeInterval(taskDuration * Double(index))
            let taskEndTime = taskStartTime.addingTimeInterval(taskDuration)
            
            task.startTime = taskStartTime
            task.endTime = taskEndTime
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task block time: \(error)")
        }
    }
    
    private func updateTaskBlockSide(_ taskBlock: TaskBlock, _ newSide: TimelineSide) {
        // Update all tasks in the block category based on side
        let tasksInBlock = tasks.filter { $0.taskBlockID == taskBlock.id }
        let newCategory = newSide == .left ? TaskCategory.work : TaskCategory.personal
        
        for task in tasksInBlock {
            task.category = newCategory
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task block side: \(error)")
        }
    }
    
    private func handleTaskCollision(newStartTime: Date, newEndTime: Date) {
        // Check if the new time overlaps with any existing tasks
        let overlappingTasks = selectedDateTasks.filter { task in
            let taskStart = task.startTime
            let taskEnd = task.endTime
            
            // Check for overlap, but exclude tasks that are being moved (same time range)
            let isSameTask = (taskStart == newStartTime && taskEnd == newEndTime)
            if isSameTask { return false }
            
            return (newStartTime < taskEnd && newEndTime > taskStart)
        }
        
        if !overlappingTasks.isEmpty {
            // Store collision data and show alert
            collisionData = (newStartTime, newEndTime, overlappingTasks)
            showingCollisionAlert = true
        }
    }
    
    private func replaceTaskWithNewTime() {
        guard let data = collisionData else { return }
        
        // Delete overlapping tasks
        for task in data.overlappingTasks {
            modelContext.delete(task)
        }
        
        // The new task will be created by the drag operation
        try? modelContext.save()
        collisionData = nil
    }
    
    private func createTaskBlockWithCollision() {
        guard let data = collisionData else { return }
        
        // Get current user ID
        let currentUser = users.first
        guard let userID = currentUser?.id else { return }
        
        // Create a new task block
        let taskBlock = TaskBlock(
            userID: userID,
            title: "New Task Block",
            blockDescription: "Created from task collision"
        )
        
        // Move overlapping tasks into the block
        for task in data.overlappingTasks {
            task.taskBlockID = taskBlock.id
        }
        
        modelContext.insert(taskBlock)
        try? modelContext.save()
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
        GeometryReader { geometry in
            ZStack {
                // Apple-style Weather Background
                AppleWeatherBackground(
                    weatherData: weatherManager.getWeatherForScrollPosition(scrollOffset, selectedDate: selectedDate),
                    scrollOffset: scrollOffset,
                    selectedDate: selectedDate
                )
                .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Timeline Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(hourRange, id: \.self) { hour in
                                TimelineHourView(
                                    hour: hour,
                                    tasks: tasksForHour(hour),
                                    taskBlocks: taskBlocksForHour(hour),
                                    calendarEvents: calendarEventsForHour(hour),
                                    selectedDate: selectedDate,
                                    currentTime: currentTime,
                                    scrollBasedTime: scrollBasedTime,
                                    scrollOffset: scrollOffset,
                                    getTasksForBlock: getTasksForBlock,
                                    getAllTasksForBlock: getAllTasksForBlock,
                                    getOverlappingTasks: getOverlappingTasks,
                                    updateTaskTime: updateTaskTime,
                                    updateTaskSide: updateTaskSide,
                                    updateTaskBlockTime: updateTaskBlockTime,
                                    updateTaskBlockSide: updateTaskBlockSide,
                                    handleTaskCollision: handleTaskCollision
                                )
                                .frame(height: 120)
                            }
                        }
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        print("Scroll offset changed to: \(value)")
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Task Collision Detected", isPresented: $showingCollisionAlert) {
                Button("Replace Existing Tasks") {
                    replaceTaskWithNewTime()
                }
                Button("Create Task Block") {
                    createTaskBlockWithCollision()
                }
                Button("Cancel", role: .cancel) {
                    collisionData = nil
                }
            } message: {
                if let data = collisionData {
                    Text("This time slot conflicts with \(data.overlappingTasks.count) existing task(s). Choose an action:")
                }
            }
            .onAppear {
                startTimer()
            }
                .onDisappear {
                    stopTimer()
                }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Day Selector with Swipe Navigation
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    Button(action: { 
                        selectedDate = day
                        calendarManager.loadCalendarEvents(for: day)
                    }) {
                        VStack(spacing: 2) {
                            Text(dayOfWeek(for: day))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                            
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                            
                            // Calendar event indicator
                            if calendarManager.hasEventsOnDate(day) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 40, height: 50)
                        .background(
                            Circle()
                                .fill(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? 
                                      Color.white.opacity(0.3) : Color.clear)
                        )
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.x > threshold {
                            // Swipe right - go to previous week
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                            calendarManager.loadCalendarEvents(for: selectedDate)
                        } else if value.translation.x < -threshold {
                            // Swipe left - go to next week
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                            calendarManager.loadCalendarEvents(for: selectedDate)
                        }
                    }
            )
            
            // Weather Info - Shows weather for selected date
            HStack {
                // Work label on the left
                Text("Work")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    )
                
                Spacer()
                
                let selectedDateWeather = weatherManager.getWeatherForTime(selectedDate)
                
                Image(systemName: selectedDateWeather.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(weatherManager.getTemperatureString(selectedDateWeather.temperature))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(selectedDateWeather.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Personal label on the right
                Text("Personal")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal)
            
            // Weather controls row - removed, now in settings
            
                // Dynamic time based on scroll position (smaller) - Clickable to toggle format
                Text(headerTimeDisplay)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                    )
                    .onTapGesture {
                        timeSettings.use24HourFormat.toggle()
                    }
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
        selectedDateTasks.filter { task in
            let taskStartHour = Calendar.current.component(.hour, from: task.startTime)
            let taskEndHour = Calendar.current.component(.hour, from: task.endTime)
            
            // Show task if it starts in this hour, ends in this hour, or spans across this hour
            return taskStartHour == hour || taskEndHour == hour || (taskStartHour < hour && taskEndHour > hour)
        }
    }
    
    private func calendarEventsForHour(_ hour: Int) -> [EKEvent] {
        calendarManager.getEventsForDate(selectedDate).filter { event in
            Calendar.current.component(.hour, from: event.startDate) == hour
        }
    }
    
    private func taskBlocksForHour(_ hour: Int) -> [TaskBlock] {
        taskBlocks.filter { taskBlock in
            // Only show task block in the hour where its first task starts
            let blockTasks = selectedDateTasks.filter { $0.taskBlockID == taskBlock.id }
            guard let firstTask = blockTasks.min(by: { $0.startTime < $1.startTime }) else { return false }
            return Calendar.current.component(.hour, from: firstTask.startTime) == hour
        }
    }
    
    private func getTasksForBlock(_ taskBlock: TaskBlock, hour: Int) -> [Task] {
        selectedDateTasks.filter { task in
            task.taskBlockID == taskBlock.id && 
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
    
    // New function to get all tasks for a block regardless of hour
    private func getAllTasksForBlock(_ taskBlock: TaskBlock) -> [Task] {
        selectedDateTasks.filter { task in
            task.taskBlockID == taskBlock.id
        }
    }
    
    private func getOverlappingTasks(_ tasks: [Task]) -> [[Task]] {
        var groups: [[Task]] = []
        var processed: Set<String> = []
        
        for task in tasks {
            if processed.contains(task.id) { continue }
            
            var group = [task]
            processed.insert(task.id)
            
            for otherTask in tasks {
                if processed.contains(otherTask.id) { continue }
                
                // Check if tasks overlap
                if tasksOverlap(task, otherTask) {
                    group.append(otherTask)
                    processed.insert(otherTask.id)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    private func tasksOverlap(_ task1: Task, _ task2: Task) -> Bool {
        return task1.startTime < task2.endTime && task2.startTime < task1.endTime
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // Update every minute to refresh current time
            DispatchQueue.main.async {
                // Force view update
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
    let updateTaskSide: (Task, TimelineSide) -> Void
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TimelineSide) -> Void
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
        let workTasks = tasks.filter { $0.category == .work && $0.taskBlockID == nil }
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
                    .frame(maxWidth: group.count > 1 ? 60 : 120)
                }
            }
        }
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
        }
    }
    
    private var workTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getTasksForBlock(block, hour)
            return blockTasks.contains { $0.category == .work }
        }
    }
    
    // MARK: - Central Timeline View
    private var centralTimelineView: some View {
        ZStack(alignment: .top) {
            // Background timeline line
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
            
            // Hour text integrated into timeline
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    let hourDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                    let hourText = timeSettings.formatHour(hourDate)
                    
                    ZStack {
                        // Hour text positioned on the timeline
                        Text(hourText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 24, height: 24)
                            )
                            .offset(x: -15) // Position to the left of timeline
                    }
                    .frame(height: 120) // Full hour height
                }
            }
            
            // Calendar events indicators
            calendarEventsIndicators
                
            // Current time indicator
            currentTimeIndicator
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
                let currentMinute = Calendar.current.component(.minute, from: currentTime)
                let isCurrentHour = hour == currentHour
                
                if isCurrentHour {
                    Text("\(currentHour):\(String(format: "%02d", currentMinute))")
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
        let personalTasks = tasks.filter { $0.category == .personal && $0.taskBlockID == nil }
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
                    .frame(maxWidth: group.count > 1 ? 60 : 120)
                }
            }
        }
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
        }
    }
    
    private var personalTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getTasksForBlock(block, hour)
            return blockTasks.contains { $0.category == .personal }
        }
    }

struct TaskTimelineBlock: View {
    let task: Task
    let side: TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    
    private var taskHeight: CGFloat {
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let minutes = duration / 60
        // Full hour space: 120 points per hour, so each minute is 2 points
        // Allow tasks to span multiple hours - no maximum height cap
        return max(20, CGFloat(minutes) * 2.0)
    }
    
    private var taskOffset: CGFloat {
        // Calculate offset within the hour for tasks that start in this hour
        let taskStartHour = Calendar.current.component(.hour, from: task.startTime)
        let taskStartMinute = Calendar.current.component(.minute, from: task.startTime)
        
        // If task starts in this hour, offset by minutes within the hour
        if taskStartHour == Calendar.current.component(.hour, from: Date()) {
            return CGFloat(taskStartMinute) * 2.0 // 2 points per minute
        }
        
        // If task spans across this hour, start at the top
        return 0
    }
    
    private var taskColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    private var categoryColor: Color {
        task.category.color()
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 4) {
            // Task title
            Text(task.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(side == .left ? .leading : .trailing)
            
            // Time range
            Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            // Priority indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(taskColor)
                    .frame(width: 6, height: 6)
                
                Text(task.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(taskColor, lineWidth: 2)
                )
        )
        .frame(maxWidth: 120, minHeight: taskHeight)
        .offset(y: taskOffset) // Apply the calculated offset
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        .overlay(
            // Lock icon for locked tasks
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
                        .offset(x: 50, y: -20) // Top-right corner
                }
            },
            alignment: .topTrailing
        )
    }
}

struct TaskBlockTimelineView: View {
    let taskBlock: TaskBlock
    let tasks: [Task]
    let side: TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    private var blockHeight: CGFloat {
        let totalDuration = tasks.reduce(0) { total, task in
            total + task.endTime.timeIntervalSince(task.startTime)
        }
        let minutes = totalDuration / 60
        // Each hour is 120 points, so each minute is 2 points
        // Minimum height of 30 points, maximum of 100 points per hour
        return max(30, min(100, CGFloat(minutes) * 2))
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
        // Use the category color of the first task, or default to blue
        if let firstTask = tasks.first {
            return firstTask.category.color()
        }
        return .blue
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 4) {
            // Block title
            Text(taskBlock.title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(side == .left ? .leading : .trailing)
            
            // Task count
            Text("\(tasks.count) tasks")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            // Time range
            if let firstTask = tasks.first, let lastTask = tasks.last {
                let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
                let startTime = sortedTasks.first?.startTime ?? firstTask.startTime
                let endTime = sortedTasks.last?.endTime ?? lastTask.endTime
                
                Text("\(timeSettings.formatTime(startTime)) - \(timeSettings.formatTime(endTime))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Priority indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(blockColor)
                    .frame(width: 6, height: 6)
                
                Text(taskBlock.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(blockColor, lineWidth: 3)
                )
        )
        .frame(maxWidth: 120, minHeight: blockHeight)
        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
        .overlay(
            // Lock icon for locked task blocks
            Group {
                if taskBlock.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                        .offset(x: 50, y: -20) // Top-right corner
                }
            },
            alignment: .topTrailing
        )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Task.self], inMemory: true)
}
