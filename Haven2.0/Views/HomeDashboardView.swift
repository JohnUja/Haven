//
//  HomeDashboardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import AudioToolbox

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var showingCalendar = false
    @State private var currentTime = Date()
    @State private var showingAddBlock = false
    @State private var taskSortOrder: TaskSortOrder = .priority
    @State private var recentlyCompletedTasks: Set<String> = []
    
    private var currentUser: User? {
        users.first
    }
    
    private var selectedDateTasks: [Task] {
        let filteredTasks = tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
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
            sortedCompleted = (recentlyCompleted + oldCompleted).sorted { task1, task2 in
                let task1Index = priorityOrder.firstIndex(of: task1.priority) ?? 2
                let task2Index = priorityOrder.firstIndex(of: task2.priority) ?? 2
                return task1Index < task2Index
            }
        case .mostRecent:
            sortedIncomplete = incompleteTasks.sorted { $0.startTime > $1.startTime }
            sortedCompleted = (recentlyCompleted + oldCompleted).sorted { $0.startTime > $1.startTime }
        case .timeSensitive:
            let now = Date()
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            }
            sortedCompleted = (recentlyCompleted + oldCompleted).sorted { task1, task2 in
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            }
        case .category:
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                task1.category.rawValue < task2.category.rawValue
            }
            sortedCompleted = (recentlyCompleted + oldCompleted).sorted { task1, task2 in
                task1.category.rawValue < task2.category.rawValue
            }
        }
        
        return sortedIncomplete + sortedCompleted
    }
    
    enum TaskSortOrder: String, CaseIterable {
        case priority = "Priority"
        case mostRecent = "Most Recent"
        case timeSensitive = "Time Sensitive"
        case category = "Category"
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                // Dynamic background
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Navigation Bar - Fixed at top
                    topNavigationView(theme: theme)
                        .padding(.top, 0)
                        .frame(height: 60)
                    
                    // Completed Tasks Count - Fixed height
                    completedTasksCountView(theme: theme)
                        .frame(height: 50)
                    
                    // Central Time Display - Fixed height
                    centralTimeView(theme: theme)
                        .frame(height: 120)
                    
                    // Day Navigation Circles - Fixed height
                    dayNavigationView(theme: theme)
                        .frame(height: 80)
                    
                    // Current Activity - Fixed height
                    currentActivityView(theme: theme)
                        .frame(height: 50)
                    
                    // Task Ordering - Fixed height, smaller
                    taskOrderingView(theme: theme)
                        .frame(height: 40)
                    
                    // Tasks Section - Flexible but contained
                    tasksSectionView(theme: theme)
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingCalendar) {
            calendarModalView(theme: theme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddBlock) {
            AddBlockView(selectedDate: selectedDate)
                .presentationDetents([.medium])
        }
        .onAppear {
            startTimeTimer()
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationView(theme: any AppTheme) -> some View {
        HStack {
            // Calendar Dropdown (Top Left)
            Button(action: { showingCalendar = true }) {
                HStack(spacing: 4) {
                    Text(selectedDate, format: .dateTime.month(.abbreviated).day())
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Add Task/Block Buttons (Top Right)
            HStack(spacing: 12) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.square.fill")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
                
                Button(action: { showingAddBlock = true }) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title3)
                        .foregroundColor(theme.secondaryColor)
                }
                
                Button(action: {}) {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Completed Tasks Count
    private func completedTasksCountView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        
        return HStack {
            Text("\(completedCount)/\(totalCount) tasks completed")
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackground.opacity(0.8))
                )
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Central Time Display
    private func centralTimeView(theme: any AppTheme) -> some View {
        VStack(spacing: 12) {
            Text(currentTime, format: .dateTime.hour().minute())
                .font(.custom("Montserrat", size: 48).weight(.bold))
                .foregroundColor(theme.textPrimary)
        }
    }
    
    // MARK: - Day Navigation
    private func dayNavigationView(theme: any AppTheme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-7...7, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) ?? Date()
                    let dayNumber = Calendar.current.component(.day, from: date)
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = date
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(dayNumber, format: .number)
                                .font(.custom("Montserrat", size: 14).weight(.medium))
                                .foregroundColor(isSelected ? .white : theme.textPrimary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? theme.primaryColor : (isToday ? theme.accentColor.opacity(0.3) : theme.cardBackground))
                                        .shadow(color: theme.primaryColor.opacity(0.3), radius: isSelected ? 6 : 2)
                                )
                            
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .frame(width: 44)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Current Activity
    private func currentActivityView(theme: any AppTheme) -> some View {
        Group {
            if let currentTask = getCurrentTask() {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                    
                    Text("Working on: \(currentTask.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackground.opacity(0.8))
                )
            }
        }
    }
    
    // MARK: - Task Ordering
    private func taskOrderingView(theme: any AppTheme) -> some View {
        HStack {
            Text("Tasks")
                .font(.custom("Montserrat", size: 16).weight(.medium))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(TaskSortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) {
                        taskSortOrder = order
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text("\(taskSortOrder.rawValue)")
                        .font(.custom("Montserrat", size: 12).weight(.regular))
                        .foregroundColor(theme.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.cardBackground.opacity(0.6))
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tasks Section
    private func tasksSectionView(theme: any AppTheme) -> some View {
        VStack(spacing: 0) {
            // Dividing line
            Rectangle()
                .fill(theme.textSecondary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            if selectedDateTasks.isEmpty {
                emptyTasksView(theme: theme)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Group tasks by blocks
                        let groupedTasks = Dictionary(grouping: selectedDateTasks) { task in
                            task.taskBlockID ?? "individual"
                        }
                        
                        // Show incomplete tasks first
                        ForEach(Array(groupedTasks.keys.sorted()), id: \.self) { blockID in
                            if blockID == "individual" {
                                // Individual tasks
                                ForEach(groupedTasks[blockID]?.filter { !$0.isComplete } ?? [], id: \.id) { task in
                                    TaskCardView(task: task, theme: theme, onTaskCompleted: handleTaskCompleted)
                                }
                            } else {
                                // Task block
                                if let blockTasks = groupedTasks[blockID], !blockTasks.isEmpty {
                                    let incompleteTasks = blockTasks.filter { !$0.isComplete }
                                    if !incompleteTasks.isEmpty {
                                        TaskBlockCardView(tasks: blockTasks, theme: theme)
                                    }
                                }
                            }
                        }
                        
                        // Show completed tasks at bottom
                        ForEach(Array(groupedTasks.keys.sorted()), id: \.self) { blockID in
                            if blockID == "individual" {
                                // Individual completed tasks
                                ForEach(groupedTasks[blockID]?.filter { $0.isComplete } ?? [], id: \.id) { task in
                                    TaskCardView(task: task, theme: theme, onTaskCompleted: handleTaskCompleted)
                                }
                            } else {
                                // Completed task blocks
                                if let blockTasks = groupedTasks[blockID], !blockTasks.isEmpty {
                                    let allComplete = blockTasks.allSatisfy { $0.isComplete }
                                    if allComplete {
                                        TaskBlockCardView(tasks: blockTasks, theme: theme)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    // MARK: - Empty Tasks View
    private func emptyTasksView(theme: any AppTheme) -> some View {
        VStack(spacing: 16) {
            Text("No tasks for today")
                .font(.custom("Montserrat", size: 16).weight(.medium))
                .foregroundColor(theme.textSecondary)
            
            Text("Tap + to add a task")
                .font(.custom("Montserrat", size: 14).weight(.regular))
                .foregroundColor(theme.textSecondary.opacity(0.7))
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Calendar Modal View
    private func calendarModalView(theme: any AppTheme) -> some View {
        NavigationView {
            MonthCalendarView(selectedDate: $selectedDate)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingCalendar = false
                        }
                    }
                }
        }
    }
    
    // MARK: - Helper Functions
    private func getCurrentTask() -> Task? {
        let now = Date()
        return selectedDateTasks.first { task in
            now >= task.startTime && now <= task.endTime && !task.isComplete
        }
    }
    
    private func startTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func handleTaskCompleted(_ taskId: String) {
        recentlyCompletedTasks.insert(taskId)
        
        // Remove from recently completed after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            recentlyCompletedTasks.remove(taskId)
        }
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: Task
    let theme: any AppTheme
    let onTaskCompleted: ((String) -> Void)?
    @Environment(\.modelContext) private var modelContext
    
    init(task: Task, theme: any AppTheme, onTaskCompleted: ((String) -> Void)? = nil) {
        self.task = task
        self.theme = theme
        self.onTaskCompleted = onTaskCompleted
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            // Category icon
            Image(systemName: task.category.icon)
                .font(.title3)
                .foregroundColor(task.category.color())
                .frame(width: 24, height: 24)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                    .strikethrough(task.isComplete)
                    .opacity(task.isComplete ? 0.6 : 1.0)
                
                if let description = task.taskDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                        .opacity(task.isComplete ? 0.6 : 1.0)
                }
            }
            
            Spacer()
            
            // Right side with completion button and time
            VStack(alignment: .trailing, spacing: 4) {
                // Completion button
                Button(action: {
                    handleTaskCompletion()
                }) {
                    Image(systemName: completionIcon)
                        .font(.title3)
                        .foregroundColor(completionColor)
                }
                
                // Time display under tick icon
                Text(timeRangeText)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                    .opacity(task.isComplete ? 0.6 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
                .overlay(
                    // Category ring + current task highlighting
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(
                            isCurrentTask ? Color.green : task.category.color(),
                            lineWidth: isCurrentTask ? 4 : 1.5
                        )
                        .opacity(isCurrentTask ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 0.3), value: isCurrentTask)
                )
                .shadow(color: theme.primaryColor.opacity(0.1), radius: theme.shadowRadius)
        )
        .opacity(task.isComplete ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isComplete)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if Calendar.current.isDate(task.startTime, inSameDayAs: task.endTime) {
            return "\(formatter.string(from: task.startTime)) - \(formatter.string(from: task.endTime))"
        } else {
            return "Multi-day"
        }
    }
    
    private var completionIcon: String {
        if task.isComplete {
            return "checkmark.circle.fill"
        } else if isOverdue {
            return "minus.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var completionColor: Color {
        if task.isComplete {
            return .green
        } else if isOverdue {
            return .gray
        } else {
            return theme.textSecondary
        }
    }
    
    private var isOverdue: Bool {
        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        return now > endOfDay && !task.isComplete
    }
    
    private var isCurrentTask: Bool {
        let now = Date()
        return now >= task.startTime && now <= task.endTime && !task.isComplete
    }
    
    private func handleTaskCompletion() {
        // Check if task can be completed (time validation)
        if !canCompleteTask() {
            // Shake animation for invalid completion
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                // This will be handled by the parent view
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            task.isComplete.toggle()
            task.completionAnimation = true
            
            // Add to recently completed if just completed
            if task.isComplete {
                onTaskCompleted?(task.id)
                
                // Play completion sound and vibration
                AudioServicesPlaySystemSound(1104) // Tink sound (more satisfying)
                AudioServicesPlaySystemSound(1520) // Haptic feedback
            }
        }
    }
    
    private func canCompleteTask() -> Bool {
        let now = Date()
        
        // For time-sensitive tasks, check if we're within the time window
        if task.priority == .urgent || task.priority == .high {
            return now >= task.startTime
        }
        
        // For normal tasks, allow completion anytime after start time
        return now >= task.startTime
    }
}


#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}