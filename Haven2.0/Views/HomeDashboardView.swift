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
    @Query private var taskBlocks: [TaskBlock]
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var showingCalendar = false
    @State private var currentTime = Date()
    @State private var showingAddBlock = false
    @State private var taskSortOrder: TaskSortOrder = .priority
    @State private var recentlyCompletedTasks: Set<String> = []
    @State private var showingEditTask: Task? = nil
    @State private var showingProgressDetails = false
    @State private var showingFloatingMenu: Task? = nil
    @State private var showingFloatingMenuForBlock: [Task]? = nil
    @State private var showingMoveToDay: Task? = nil
    @State private var showingMoveToDayBlock: [Task]? = nil
    @State private var showingUndoMove: Task? = nil
    @State private var showingUndoMoveBlock: [Task]? = nil
    @State private var undoMoveTimer: Timer? = nil
    @State private var originalTaskDates: [String: Date] = [:]
    @State private var originalBlockDates: [String: [Date]] = [:]
    
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
    
    private func getTaskBlock(for blockID: String) -> TaskBlock? {
        return taskBlocks.first { $0.id == blockID }
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
        .sheet(item: $showingEditTask) { task in
            EditTaskView(task: task)
        }
        .overlay(
            // Floating Action Menu
            Group {
                if let task = showingFloatingMenu {
                    ZStack {
                        // Background overlay
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingFloatingMenu = nil
                            }
                        
                        // Floating menu for task
                        FloatingActionMenu(
                            task: task,
                            theme: themeManager.currentTheme,
                            onEdit: {
                                showingFloatingMenu = nil
                                showingEditTask = task
                            },
                            onChangeCategory: {
                                showingFloatingMenu = nil
                                // TODO: Implement category change
                            },
                            onAddToGoal: {
                                showingFloatingMenu = nil
                                // TODO: Implement add to goal
                            },
                            onMove: {
                                showingFloatingMenu = nil
                                showingMoveToDay = task
                            },
                            onDelete: {
                                showingFloatingMenu = nil
                                // TODO: Implement delete task
                            },
                            onDismiss: {
                                showingFloatingMenu = nil
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                if let taskBlock = showingFloatingMenuForBlock {
                    ZStack {
                        // Background overlay
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingFloatingMenuForBlock = nil
                            }
                        
                        // Floating menu for task block
                        FloatingActionMenu(
                            taskBlock: taskBlock,
                            theme: themeManager.currentTheme,
                            onEdit: {
                                showingFloatingMenuForBlock = nil
                                // TODO: Implement edit task block
                            },
                            onChangeCategory: {
                                showingFloatingMenuForBlock = nil
                                // TODO: Implement category change
                            },
                            onAddToGoal: {
                                showingFloatingMenuForBlock = nil
                                // TODO: Implement add to goal
                            },
                            onMove: {
                                showingFloatingMenuForBlock = nil
                                showingMoveToDayBlock = taskBlock
                            },
                            onDelete: {
                                showingFloatingMenuForBlock = nil
                                // TODO: Implement delete task block
                            },
                            onDismiss: {
                                showingFloatingMenuForBlock = nil
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        )
        .onAppear {
            startTimeTimer()
        }
        .overlay(
            // Move to Day Selection
            Group {
                if let task = showingMoveToDay {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingMoveToDay = nil
                            }
                        
                        VStack(spacing: 16) {
                            Text("Move Task to Day")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Select a day to move this task to:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Day selection (simplified - just show next 7 days)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(0..<7, id: \.self) { dayOffset in
                                    let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate) ?? selectedDate
                                    let isToday = Calendar.current.isDate(targetDate, inSameDayAs: selectedDate)
                                    
                                    Button(action: {
                                        moveTaskToDay(task, to: targetDate)
                                        showingMoveToDay = nil
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(dayOffset == 0 ? "Today" : "\(dayOffset)")
                                                .font(.caption)
                                                .fontWeight(isToday ? .bold : .regular)
                                            
                                            Text(targetDate, format: .dateTime.weekday(.abbreviated))
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isToday ? Color.blue : Color.white.opacity(0.2))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Button("Cancel") {
                                showingMoveToDay = nil
                            }
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.horizontal, 40)
                    }
                }
                
                if let taskBlock = showingMoveToDayBlock {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingMoveToDayBlock = nil
                            }
                        
                        VStack(spacing: 16) {
                            Text("Move Task Block to Day")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Select a day to move this task block to:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Day selection (simplified - just show next 7 days)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(0..<7, id: \.self) { dayOffset in
                                    let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate) ?? selectedDate
                                    let isToday = Calendar.current.isDate(targetDate, inSameDayAs: selectedDate)
                                    
                                    Button(action: {
                                        moveTaskBlockToDay(taskBlock, to: targetDate)
                                        showingMoveToDayBlock = nil
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(dayOffset == 0 ? "Today" : "\(dayOffset)")
                                                .font(.caption)
                                                .fontWeight(isToday ? .bold : .regular)
                                            
                                            Text(targetDate, format: .dateTime.weekday(.abbreviated))
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isToday ? Color.blue : Color.white.opacity(0.2))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Button("Cancel") {
                                showingMoveToDayBlock = nil
                            }
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.horizontal, 40)
                    }
                }
            }
        )
        .overlay(
            // Undo Move Notification
            Group {
                if let task = showingUndoMove {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text("Task moved to another day")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Undo") {
                                undoMoveTask(task)
                                showingUndoMove = nil
                                undoMoveTimer?.invalidate()
                                undoMoveTimer = nil
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                if let taskBlock = showingUndoMoveBlock {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text("Task block moved to another day")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Undo") {
                                undoMoveTaskBlock(taskBlock)
                                showingUndoMoveBlock = nil
                                undoMoveTimer?.invalidate()
                                undoMoveTimer = nil
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        )
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
            
            // Time Crystals Display (Center)
            if let user = currentUser {
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("\(user.gamificationCurrency)")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackground.opacity(0.8))
                )
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
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return VStack(spacing: 8) {
            // Completion counter with fill-up bar background (smaller)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingProgressDetails.toggle()
                }
            }) {
                ZStack(alignment: .leading) {
                    // Background fill-up bar
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground.opacity(0.8))
                        .overlay(
                            // Green fill-up bar
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.3), .green.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .scaleEffect(x: progress, y: 1.0, anchor: .leading)
                                .animation(.easeInOut(duration: 0.5), value: progress)
                        )
                    
                    // Text content
                    HStack {
                        Text("\(completedCount)/\(totalCount) tasks completed")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .zIndex(1)
                        
                        Spacer()
                        
                        Image(systemName: showingProgressDetails ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                            .zIndex(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable progress details (only when clicked)
            if showingProgressDetails && totalCount > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("\(Int(progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
                                    TaskCardView(task: task, theme: theme, onTaskCompleted: handleTaskCompleted, onEditTask: { task in
                                        showingFloatingMenu = task
                                    })
                                }
                            } else {
                                // Task block
                                if let blockTasks = groupedTasks[blockID], !blockTasks.isEmpty {
                                    let incompleteTasks = blockTasks.filter { !$0.isComplete }
                                    if !incompleteTasks.isEmpty {
                                        TaskBlockCardView(tasks: blockTasks, taskBlock: getTaskBlock(for: blockID), theme: theme, onEditBlock: { tasks in
                                            showingFloatingMenuForBlock = tasks
                                        }, onAddSubtask: {
                                            // TODO: Implement add subtask
                                        }, onRemoveSubtask: { task in
                                            // TODO: Implement remove subtask
                                        })
                                    }
                                }
                            }
                        }
                        
                        // Show completed tasks at bottom
                        ForEach(Array(groupedTasks.keys.sorted()), id: \.self) { blockID in
                            if blockID == "individual" {
                                // Individual completed tasks
                                ForEach(groupedTasks[blockID]?.filter { $0.isComplete } ?? [], id: \.id) { task in
                                    TaskCardView(task: task, theme: theme, onTaskCompleted: handleTaskCompleted, onEditTask: { task in
                                        showingFloatingMenu = task
                                    })
                                }
                            } else {
                                // Completed task blocks
                                if let blockTasks = groupedTasks[blockID], !blockTasks.isEmpty {
                                    let allComplete = blockTasks.allSatisfy { $0.isComplete }
                                    if allComplete {
                                        TaskBlockCardView(tasks: blockTasks, taskBlock: getTaskBlock(for: blockID), theme: theme, onEditBlock: { tasks in
                                            showingFloatingMenuForBlock = tasks
                                        }, onAddSubtask: {
                                            // TODO: Implement add subtask
                                        }, onRemoveSubtask: { task in
                                            // TODO: Implement remove subtask
                                        })
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
        
        // Remove from recently completed after 4 seconds (3-5 second range)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            recentlyCompletedTasks.remove(taskId)
        }
    }
    
    private func moveTaskToDay(_ task: Task, to targetDate: Date) {
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
        
        // Auto-hide undo after 10 seconds
        undoMoveTimer?.invalidate()
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            showingUndoMove = nil
            originalTaskDates.removeValue(forKey: task.id)
        }
    }
    
    private func moveTaskBlockToDay(_ taskBlock: [Task], to targetDate: Date) {
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
        
        // Auto-hide undo after 10 seconds
        undoMoveTimer?.invalidate()
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            showingUndoMoveBlock = nil
            originalBlockDates.removeValue(forKey: blockId)
        }
    }
    
    private func undoMoveTask(_ task: Task) {
        guard let originalDate = originalTaskDates[task.id] else { return }
        
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
    }
    
    private func undoMoveTaskBlock(_ taskBlock: [Task]) {
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
    }
}

// MARK: - Floating Action Menu
struct FloatingActionMenu: View {
    let task: Task?
    let taskBlock: [Task]?
    let theme: any AppTheme
    let onEdit: () -> Void
    let onChangeCategory: () -> Void
    let onAddToGoal: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    init(task: Task? = nil, taskBlock: [Task]? = nil, theme: any AppTheme, onEdit: @escaping () -> Void, onChangeCategory: @escaping () -> Void, onAddToGoal: @escaping () -> Void, onMove: @escaping () -> Void, onDelete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.task = task
        self.taskBlock = taskBlock
        self.theme = theme
        self.onEdit = onEdit
        self.onChangeCategory = onChangeCategory
        self.onAddToGoal = onAddToGoal
        self.onMove = onMove
        self.onDelete = onDelete
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Edit
            Button(action: onEdit) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.title2)
                    Text("Edit")
                        .font(.caption)
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
            
            // Change Category
            Button(action: onChangeCategory) {
                VStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.title2)
                    Text("Category")
                        .font(.caption)
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
            
            // Add to Goal
            Button(action: onAddToGoal) {
                VStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.title2)
                    Text("Goal")
                        .font(.caption)
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
            
            // Move
            Button(action: onMove) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title2)
                    Text("Move")
                        .font(.caption)
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
            
            // Delete
            Button(action: onDelete) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
                .shadow(color: theme.primaryColor.opacity(0.3), radius: 15, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.primaryColor.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: Task
    let theme: any AppTheme
    let onTaskCompleted: ((String) -> Void)?
    let onEditTask: ((Task) -> Void)?
    @Environment(\.modelContext) private var modelContext
    @State private var showCompletionAnimation = false
    @State private var ringProgress: CGFloat = 0
    
    init(task: Task, theme: any AppTheme, onTaskCompleted: ((String) -> Void)? = nil, onEditTask: ((Task) -> Void)? = nil) {
        self.task = task
        self.theme = theme
        self.onTaskCompleted = onTaskCompleted
        self.onEditTask = onEditTask
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
                    
                    // Priority text
                    Text("Priority: \(task.priority.rawValue.capitalized)")
                        .font(.caption2)
                        .foregroundColor(priorityColor)
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
            ZStack {
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.cardBackground)
                    .overlay(
                        // Category ring + current task highlighting
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .stroke(
                                task.category.color(),
                                lineWidth: 1.5
                            )
                            .opacity(0.6)
                    )
                    .overlay(
                        // Current task indicator - subtle pulsing dot
                        VStack {
                            HStack {
                                Spacer()
                                if isCurrentTask {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isCurrentTask ? 1.2 : 1.0)
                                        .opacity(isCurrentTask ? 0.8 : 0.0)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCurrentTask)
                                        .padding(.top, 8)
                                        .padding(.trailing, 8)
                                }
                            }
                            Spacer()
                        }
                    )
                    .shadow(color: theme.primaryColor.opacity(0.1), radius: theme.shadowRadius)
                
                // Completion ring animation
                if showCompletionAnimation {
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(
                            AngularGradient(
                                colors: [.green, .blue, .purple, .pink, .green],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: 3
                        )
                        .opacity(ringProgress)
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 1.5), value: ringProgress)
                }
            }
        )
        .opacity(task.isComplete ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isComplete)
        .onLongPressGesture {
            // Long press to show floating menu
            onEditTask?(task)
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
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
                    
                    // Trigger completion animation
                    triggerCompletionAnimation()
                    
                    // Play completion sound and vibration - better "dinggg" sound
                    AudioServicesPlaySystemSound(1057) // Glass sound (more satisfying "dinggg")
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
    
        private func triggerCompletionAnimation() {
            showCompletionAnimation = true
            
            // Ring animation that traverses the circumference
            withAnimation(.easeInOut(duration: 2.0)) {
                ringProgress = 1.0
            }
            
            // Hide animation after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    ringProgress = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletionAnimation = false
                }
            }
        }
}


#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}