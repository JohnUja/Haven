//
//  TimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
// import WeatherKit
// import CoreLocation

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @Query private var taskBlocks: [TaskBlock]
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @StateObject private var weatherManager = WeatherManager()
    @State private var timer: Timer?
    
    // Drag and drop state
    @State private var draggedTask: Task? = nil
    @State private var showTimelineGuidelines = false
    @State private var guidelineHour: Int? = nil
    
    // Edit and delete states
    @State private var showingEditTask: Task? = nil
    @State private var taskToDelete: Task? = nil
    
    private var selectedDateTasks: [Task] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
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
    
    private func updateTaskSide(_ task: Task, _ newSide: TaskTimelineBlock.TimelineSide) {
        // Update task category based on side
        task.category = newSide == .left ? .work : .personal
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task side: \(error)")
        }
    }
    
    private func showGuidelines(for hour: Int) {
        guidelineHour = hour
        showTimelineGuidelines = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showTimelineGuidelines = false
            guidelineHour = nil
        }
    }
    
    private func editTask(_ task: Task) {
        showingEditTask = task
    }
    
    private func deleteTask(_ task: Task) {
        taskToDelete = task
    }
    
    private func confirmDeleteTask() {
        guard let task = taskToDelete else { return }
        modelContext.delete(task)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete task: \(error)")
        }
        
        taskToDelete = nil
    }
    
    private var scrollBasedTime: String {
        // Calculate time based on scroll position
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let targetDate = Calendar.current.date(bySettingHour: targetHour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return formatter.string(from: targetDate)
    }
    
    private var headerTimeDisplay: String {
        // Show current time if viewing today, otherwise show 00:00 for other days
        if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: currentTime)
        } else {
            return "00:00"
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
                // Dynamic Weather Background
                WeatherBackgroundView(
                    scrollOffset: scrollOffset,
                    weatherManager: weatherManager,
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
                                    selectedDate: selectedDate,
                                    currentTime: currentTime,
                                    scrollBasedTime: scrollBasedTime,
                                    scrollOffset: scrollOffset,
                                    getTasksForBlock: getTasksForBlock,
                                    getOverlappingTasks: getOverlappingTasks,
                                    updateTaskTime: updateTaskTime,
                                    updateTaskSide: updateTaskSide,
                                    showGuidelines: showTimelineGuidelines && guidelineHour == hour,
                                    onShowGuidelines: { showGuidelines(for: hour) }
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
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .sheet(item: $showingEditTask) { task in
                EditTaskView(task: task)
            }
            .alert("Delete Task", isPresented: .constant(taskToDelete != nil)) {
                Button("Cancel", role: .cancel) {
                    taskToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    confirmDeleteTask()
                }
            } message: {
                if let task = taskToDelete {
                    Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Day Selector
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    Button(action: { selectedDate = day }) {
                        VStack(spacing: 2) {
                            Text(dayOfWeek(for: day))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                            
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? 
                                      Color.white.opacity(0.3) : Color.clear)
                        )
                    }
                }
            }
            
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
            
                // Dynamic time based on scroll position (smaller)
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
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
    
    private func taskBlocksForHour(_ hour: Int) -> [TaskBlock] {
        taskBlocks.filter { taskBlock in
            // Check if any task in this block falls within this hour
            let blockTasks = selectedDateTasks.filter { $0.taskBlockID == taskBlock.id }
            return blockTasks.contains { task in
                Calendar.current.component(.hour, from: task.startTime) == hour
            }
        }
    }
    
    private func getTasksForBlock(_ taskBlock: TaskBlock, hour: Int) -> [Task] {
        selectedDateTasks.filter { task in
            task.taskBlockID == taskBlock.id && 
            Calendar.current.component(.hour, from: task.startTime) == hour
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
    let selectedDate: Date
    let currentTime: Date
    let scrollBasedTime: String
    let scrollOffset: CGFloat
    let getTasksForBlock: (TaskBlock, Int) -> [Task]
    let getOverlappingTasks: ([Task]) -> [[Task]]
    let updateTaskTime: (Task, Date, Date) -> Void
    let updateTaskSide: (Task, TaskTimelineBlock.TimelineSide) -> Void
    let showGuidelines: Bool
    let onShowGuidelines: () -> Void
    
    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return formatter.string(from: date)
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
                    DraggableTaskTimelineBlock(
                        task: task,
                        side: .left,
                        onTimeChanged: updateTaskTime,
                        onSideChanged: updateTaskSide,
                        onEdit: {
                            editTask(task)
                        },
                        onUnlock: {
                            task.isLocked.toggle()
                            try? modelContext.save()
                        },
                        onDelete: {
                            deleteTask(task)
                        }
                    )
                    .frame(maxWidth: group.count > 1 ? 60 : 120)
                }
            }
        }
    }
    
    private var workTaskBlocksList: some View {
        ForEach(workTaskBlocks, id: \.id) { taskBlock in
            TaskBlockTimelineView(
                taskBlock: taskBlock,
                tasks: getTasksForBlock(taskBlock, hour).filter { $0.category == .work },
                side: .left
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
                
                // Guidelines overlay
                if showGuidelines {
                    guidelinesOverlay
                }
                
                // Current time indicator
                currentTimeIndicator
            }
        }
        .frame(width: 60)
        .onTapGesture {
            onShowGuidelines()
        }
    }
    
    private var guidelinesOverlay: some View {
        VStack(spacing: 0) {
            // 15-minute guideline (30 points from top)
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 8, height: 1)
                .offset(y: 30)
            
            // 30-minute guideline (60 points from top)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 12, height: 1)
                .offset(y: 60)
            
            // 45-minute guideline (90 points from top)
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 8, height: 1)
                .offset(y: 90)
        }
        .animation(.easeInOut(duration: 0.3), value: showGuidelines)
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
                    DraggableTaskTimelineBlock(
                        task: task,
                        side: .right,
                        onTimeChanged: updateTaskTime,
                        onSideChanged: updateTaskSide,
                        onEdit: {
                            editTask(task)
                        },
                        onUnlock: {
                            task.isLocked.toggle()
                            try? modelContext.save()
                        },
                        onDelete: {
                            deleteTask(task)
                        }
                    )
                    .frame(maxWidth: group.count > 1 ? 60 : 120)
                }
            }
        }
    }
    
    private var personalTaskBlocksList: some View {
        ForEach(personalTaskBlocks, id: \.id) { taskBlock in
            TaskBlockTimelineView(
                taskBlock: taskBlock,
                tasks: getTasksForBlock(taskBlock, hour).filter { $0.category == .personal },
                side: .right
            )
        }
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
    
    enum TimelineSide {
        case left, right
    }
    
    private var taskHeight: CGFloat {
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let minutes = duration / 60
        // Each hour is 120 points, so each minute is 2 points
        // Minimum height of 16 points (8 minutes), maximum of 120 points (1 hour)
        return max(16, min(120, CGFloat(minutes) * 2))
    }
    
    private var taskOffset: CGFloat {
        // Calculate offset based on start time within the hour
        let startMinute = Calendar.current.component(.minute, from: task.startTime)
        return CGFloat(startMinute) * 2 // 2 points per minute
    }
    
    private var taskColor: Color {
        switch task.priority {
        case .urgent: return .red.opacity(0.3)
        case .high: return .orange.opacity(0.3)
        case .normal: return .green.opacity(0.3)
        case .low: return .blue.opacity(0.3)
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
            Text("\(task.startTime, format: .dateTime.hour().minute()) - \(task.endTime, format: .dateTime.hour().minute())")
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
        .offset(y: taskOffset)
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
    let side: TaskTimelineBlock.TimelineSide
    
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
                
                Text("\(startTime, format: .dateTime.hour().minute()) - \(endTime, format: .dateTime.hour().minute())")
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
    }
}

struct WeatherBackgroundView: View {
    let scrollOffset: CGFloat
    let weatherManager: WeatherManager
    let selectedDate: Date
    
    private var timeAndWeatherBasedColors: [Color] {
        guard weatherManager.isWeatherEnabled else {
            // Return theme-based colors when weather is disabled
            return [.purple.opacity(0.8), .blue.opacity(0.6), .pink.opacity(0.4)]
        }
        
        // Calculate which hour is in the middle of the screen based on scroll position
        let middleOfScreenHour = getMiddleOfScreenHour()
        let currentWeather = weatherManager.getWeatherForHour(middleOfScreenHour)
        
        print("Middle of screen hour: \(middleOfScreenHour), Weather: \(currentWeather.condition), Temp: \(currentWeather.temperature)")
        
        // Base colors for time of day
        var baseColors: [Color]
        switch middleOfScreenHour {
        case 6...8:
            baseColors = [.orange.opacity(0.8), .yellow.opacity(0.6), .blue.opacity(0.4)]
        case 9...17:
            baseColors = [.blue.opacity(0.6), .cyan.opacity(0.4), .white.opacity(0.2)]
        case 18...20:
            baseColors = [.orange.opacity(0.6), .red.opacity(0.4), .purple.opacity(0.3)]
        default:
            baseColors = [.purple.opacity(0.8), .black.opacity(0.6), .blue.opacity(0.4)]
        }
        
        // Modify colors based on weather condition
        switch currentWeather.condition {
        case .sunny:
            return [.yellow.opacity(0.9), .orange.opacity(0.7), .white.opacity(0.5)]
        case .cloudy:
            return [.gray.opacity(0.8), .blue.opacity(0.6), .white.opacity(0.3)]
        case .rainy:
            return [.blue.opacity(0.8), .gray.opacity(0.6), .white.opacity(0.3)]
        case .stormy:
            return [.purple.opacity(0.9), .black.opacity(0.8), .blue.opacity(0.5)]
        }
    }
    
    private func getMiddleOfScreenHour() -> Int {
        // Calculate which hour is in the middle of the screen
        // Each hour is 120 points high
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        print("Weather - Scroll offset: \(scrollOffset), Hour offset: \(hourOffset), Target hour: \(targetHour)")
        return targetHour
    }
    
    var body: some View {
        ZStack {
            // Base gradient based on time of day and weather
            LinearGradient(
                colors: timeAndWeatherBasedColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Weather effects based on current scroll position
            if weatherManager.isWeatherEnabled {
                let currentWeather = weatherManager.getWeatherForScrollPosition(scrollOffset, selectedDate: selectedDate)
                
                if currentWeather.condition == .rainy {
                    RainEffectView()
                } else if currentWeather.condition == .cloudy {
                    CloudEffectView()
                } else if currentWeather.condition == .stormy {
                    StormEffectView()
                }
            }
        }
    }
}

struct RainEffectView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: 20)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: animationOffset + CGFloat.random(in: -100...0)
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = 1000
            }
        }
    }
}

struct CloudEffectView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height * 0.5)
                    )
            }
        }
    }
}

struct StormEffectView: View {
    @State private var lightningFlash: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Lightning flash
                if lightningFlash {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .ignoresSafeArea()
                }
                
                // Rain drops
                ForEach(0..<30, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3, height: 25)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: -100...geometry.size.height)
                        )
                }
            }
        }
        .onAppear {
            // Random lightning flashes
            Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    lightningFlash = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        lightningFlash = false
                    }
                }
            }
        }
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
