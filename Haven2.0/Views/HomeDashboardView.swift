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
    @EnvironmentObject private var timeSettings: TimeSettingsManager
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
    @State private var showingCompletionRingPopup = false
    @State private var showingCategoryChange: Task? = nil
    @State private var showingEditBlock: (taskBlock: TaskBlock, tasks: [Task])? = nil
    @State private var showingBlockColorPicker: TaskBlock? = nil
    @State private var pendingDeleteBlockTasks: [Task]? = nil
    @State private var showDeleteBlockAlert: Bool = false
    
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
                // Theme-aware home background (using primary gradient)
                theme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Navigation Bar - Fixed at top
                    topNavigationView(theme: theme)
                        .padding(.top, 0)
                        .frame(height: 60)
                    
                    // Add spacing after top nav
                    Spacer()
                        .frame(height: 20)
                    
                    // Central Time Display - Fixed height
                    centralTimeView(theme: theme)
                        .frame(height: 120)
                    
                    // Add spacing after time
                    Spacer()
                        .frame(height: 20)
                    
                    // Infinite Day Selector - Without duplicate month header
                    daySelectorSection
                    
                    // Current Activity - Fixed persistent height
                    currentActivityViewWithPersistentSpace(theme: theme)
                    
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
            EditTaskView(task: task, allTasks: tasks)
        }
        .sheet(item: $showingCategoryChange) { task in
            CategoryChangeView(task: task, onCategoryChanged: { newCategory in
                task.category = newCategory
                try? modelContext.save()
                showingCategoryChange = nil
            }, onCancel: {
                showingCategoryChange = nil
            })
            .presentationDetents([.medium])
        }
        .sheet(item: $showingMoveToDay) { task in
            MoveTaskCalendarView(task: task, onDateSelected: { date in
                moveTaskToDay(task, to: date)
                showingMoveToDay = nil
            }, onCancel: {
                showingMoveToDay = nil
            })
            .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(
            get: { showingMoveToDayBlock != nil },
            set: { if !$0 { showingMoveToDayBlock = nil } }
        )) {
            if let taskBlock = showingMoveToDayBlock {
                MoveTaskBlockCalendarView(taskBlock: taskBlock, onDateSelected: { date in
                    moveTaskBlockToDay(taskBlock, to: date)
                    showingMoveToDayBlock = nil
                }, onCancel: {
                    showingMoveToDayBlock = nil
                })
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: Binding(
            get: { showingEditBlock != nil },
            set: { if !$0 { showingEditBlock = nil } }
        )) {
            if let editBlock = showingEditBlock {
                EditBlockView(
                    taskBlock: editBlock.taskBlock,
                    tasksInBlock: editBlock.tasks,
                    allTasks: tasks
                )
            }
        }
        .sheet(item: $showingBlockColorPicker) { block in
            BlockColorPickerView(taskBlock: block, onSelected: { newColor in
                block.color = newColor
                try? modelContext.save()
                showingBlockColorPicker = nil
            }, onCancel: {
                showingBlockColorPicker = nil
            })
            .presentationDetents([.medium])
        }
        .alert("Delete Task Block?", isPresented: $showDeleteBlockAlert) {
            Button("Delete Block + Tasks", role: .destructive) {
                if let blockTasks = pendingDeleteBlockTasks {
                    deleteTaskBlock(blockTasks)
                }
                pendingDeleteBlockTasks = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteBlockTasks = nil
            }
        } message: {
            Text("This will delete the task block and all tasks inside it.")
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
                                showingCategoryChange = task
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
                                deleteTask(task)
                            },
                            onUnlock: {
                                showingFloatingMenu = nil
                                // Toggle lock status
                                task.isLocked.toggle()
                                try? modelContext.save()
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
                        // Resolve the TaskBlock object and locked state
                        let _blockObj: TaskBlock? = {
                            if let firstTask = taskBlock.first,
                               let blockID = firstTask.taskBlockID {
                                return taskBlocks.first(where: { $0.id == blockID })
                            }
                            return nil
                        }()

                        FloatingActionMenu(
                            taskBlock: taskBlock,
                            theme: themeManager.currentTheme,
                            blockLocked: _blockObj?.isLocked ?? false,
                            onEdit: {
                                showingFloatingMenuForBlock = nil
                                // Find the TaskBlock for these tasks
                                if let firstTask = taskBlock.first,
                                   let blockID = firstTask.taskBlockID,
                                   let taskBlockObj = taskBlocks.first(where: { $0.id == blockID }) {
                                    showingEditBlock = (taskBlockObj, taskBlock)
                                }
                            },
                            onChangeCategory: {
                                // Repurposed as Change Color for blocks
                                showingFloatingMenuForBlock = nil
                                if let firstTask = taskBlock.first,
                                   let blockID = firstTask.taskBlockID,
                                   let taskBlockObj = taskBlocks.first(where: { $0.id == blockID }) {
                                    showingBlockColorPicker = taskBlockObj
                                }
                            },
                            onAddToGoal: {
                                // Hidden for blocks (no-op)
                                showingFloatingMenuForBlock = nil
                            },
                            onMove: {
                                showingFloatingMenuForBlock = nil
                                showingMoveToDayBlock = taskBlock
                            },
                            onDelete: {
                                showingFloatingMenuForBlock = nil
                                pendingDeleteBlockTasks = taskBlock
                                showDeleteBlockAlert = true
                            },
                            onUnlock: {
                                showingFloatingMenuForBlock = nil
                                if let firstTask = taskBlock.first,
                                   let blockID = firstTask.taskBlockID,
                                   let taskBlockObj = taskBlocks.first(where: { $0.id == blockID }) {
                                    taskBlockObj.isLocked.toggle()
                                    try? modelContext.save()
                                }
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
        // Removed legacy black overlay selector to avoid double calendars during Move actions
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
                
                // Completion Ring Popup - Positioned below navigation bar
                if showingCompletionRingPopup {
                    VStack {
                        HStack {
                            Spacer()
                            completionRingPopupView(theme: theme)
                                .transition(.scale.combined(with: .opacity))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.top, 70) // Position just below nav bar
                    .background(
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingCompletionRingPopup = false
                                }
                            }
                    )
                }
            }
        )
    }
    
    // MARK: - Completion Ring Popup View
    private func completionRingPopupView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        // Guard clause to prevent type-checking errors
        guard let user = currentUser else {
            return AnyView(
                Text("No user data")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.9))
            )
        }
        
        return AnyView(popupContentView(user: user, completedCount: completedCount, totalCount: totalCount, progress: progress))
    }
    
    @ViewBuilder
    private func popupContentView(user: User, completedCount: Int, totalCount: Int, progress: Double) -> some View {
        VStack(spacing: 12) {
            // Header text
            Text("\(completedCount) out of \(totalCount) tasks completed for the day")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                // Completion ring on the left
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                            .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    VStack(spacing: 0) {
                        Text("\(completedCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("/\(totalCount)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 40)
                
                // Progress bars on the right (narrower)
                VStack(spacing: 8) {
                    progressBarView(title: "XP", value: Double(user.currentXP), maxValue: Double(user.nextLevelXP), color: .purple)
                    progressBarView(title: "Crystals", value: Double(user.gamificationCurrency), maxValue: 100, color: .yellow)
                    progressBarView(title: "Themes", value: 0, maxValue: 5, color: .cyan)
                }
                .frame(width: 120) // Narrower progress bars
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
        .frame(width: 500) // Max width for better spacing
    }
    
    // Helper function for progress bars
    private func progressBarView(title: String, value: Double, maxValue: Double, color: Color) -> some View {
        let progress = maxValue > 0 ? min(value / maxValue, 1.0) : 0.0
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("\(Int(value))/\(Int(maxValue))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationView(theme: any AppTheme) -> some View {
        HStack {
            // Calendar Dropdown (Top Left)
            Button(action: { showingCalendar = true }) {
                Text(monthYearString(from: selectedDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            
            Spacer()
            
            // Center section: Completion Ring + Time Crystals
            HStack(spacing: 12) {
                completionRingView(theme: theme)
                
            if let user = currentUser {
                HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        .font(.caption)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.8), radius: 3)
                    Text("\(user.gamificationCurrency)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                )
                }
            }
            
            Spacer()
            
            // Cleaner Action Buttons (Top Right)
            HStack(spacing: 8) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.accentColor.opacity(0.3))
                        )
                }
                
                Button(action: { showingAddBlock = true }) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.secondaryColor.opacity(0.3))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Extracted Views (Performance Optimization)
    
    @ViewBuilder
    private var daySelectorSection: some View {
        VStack(spacing: 12) {
            InfiniteDaySelector(
                selectedDate: $selectedDate,
                onDateChanged: { _ in },
                hasEvents: { _ in false },
                showMonthHeader: false
            )
            .frame(height: 70)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Completion Ring
    private func completionRingView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return HStack(spacing: 6) {
            // Task count text on the left
            Text("\(completedCount)/\(totalCount)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Completion ring
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingCompletionRingPopup.toggle()
                }
            }) {
                ZStack {
                    // Outer ring (white/clear base)
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    // Progress ring (green fill)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    // Center dot (white)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
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
            Text(timeSettings.formatTime(currentTime))
                .font(.custom("Montserrat", size: 48).weight(.bold))
                .foregroundColor(.white) // White for contrast on all gradients
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
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: .orange.opacity(0.8), radius: 4)
                        .overlay(
                            Circle()
                                .fill(Color.orange)
                                .blur(radius: 3)
                                .opacity(0.6)
                        )
                    
                    Text("Working on: \(currentTask.title)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground.opacity(0.6))
                )
            }
        }
    }
    
    // MARK: - Current Activity With Persistent Space
    private func currentActivityViewWithPersistentSpace(theme: any AppTheme) -> some View {
        ZStack {
            // Always reserve the space with a transparent container
            Rectangle()
                .fill(Color.clear)
                .frame(height: 50)
            
            // Show content only if there's a current task
            if let currentTask = getCurrentTask() {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: .orange.opacity(0.8), radius: 4)
                        .overlay(
                            Circle()
                                .fill(Color.orange)
                                .blur(radius: 3)
                                .opacity(0.6)
                        )
                    
                    Text("Working on: \(currentTask.title)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground.opacity(0.6))
                )
            }
        }
    }
    
    // MARK: - Task Ordering
    private func taskOrderingView(theme: any AppTheme) -> some View {
        HStack {
            Text("Tasks")
                .font(.custom("Montserrat", size: 16).weight(.medium))
                .foregroundColor(.white)
            
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
                .fill(Color.white.opacity(0.3))
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
        VStack(spacing: 20) {
            // Fun icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Nothing scheduled yet!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Get started by adding your first task")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            // Add Task Shortcut Button
            Button(action: { showingAddTask = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Task")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor, theme.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).uppercased()
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
    
    // MARK: - Move Task Calendar View
    private func moveTaskCalendarView(task: Task) -> some View {
        @State var targetDate = task.startTime
        
        return NavigationView {
            MonthCalendarView(selectedDate: Binding(
                get: { targetDate },
                set: { newDate in
                    targetDate = newDate
                    moveTaskToDay(task, to: newDate)
                    showingMoveToDay = nil
                }
            ))
            .navigationTitle("Move Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingMoveToDay = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Move Task Block Calendar View
    private func moveTaskBlockCalendarView(taskBlock: [Task]) -> some View {
        @State var targetDate = taskBlock.first?.startTime ?? Date()
        
        return NavigationView {
            MonthCalendarView(selectedDate: Binding(
                get: { targetDate },
                set: { newDate in
                    targetDate = newDate
                    moveTaskBlockToDay(taskBlock, to: newDate)
                    showingMoveToDayBlock = nil
                }
            ))
            .navigationTitle("Move Task Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingMoveToDayBlock = nil
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
        
        try? modelContext.save()
        
        // Auto-hide undo after 5 seconds
        undoMoveTimer?.invalidate()
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
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
        
        try? modelContext.save()
        
        // Auto-hide undo after 5 seconds
        undoMoveTimer?.invalidate()
        undoMoveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
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
    
    // MARK: - Delete Functions
    private func deleteTask(_ task: Task) {
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    private func deleteTaskBlock(_ tasks: [Task]) {
        for task in tasks {
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
}

// MARK: - Floating Action Menu
struct FloatingActionMenu: View {
    let task: Task?
    let taskBlock: [Task]?
    let theme: any AppTheme
    let blockLocked: Bool?
    let onEdit: () -> Void
    let onChangeCategory: () -> Void
    let onAddToGoal: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let onUnlock: () -> Void
    let onDismiss: () -> Void
    @Environment(\..modelContext) private var modelContext
    
    init(task: Task? = nil, taskBlock: [Task]? = nil, theme: any AppTheme, blockLocked: Bool? = nil, onEdit: @escaping () -> Void, onChangeCategory: @escaping () -> Void, onAddToGoal: @escaping () -> Void, onMove: @escaping () -> Void, onDelete: @escaping () -> Void, onUnlock: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.task = task
        self.taskBlock = taskBlock
        self.theme = theme
        self.blockLocked = blockLocked
        self.onEdit = onEdit
        self.onChangeCategory = onChangeCategory
        self.onAddToGoal = onAddToGoal
        self.onMove = onMove
        self.onDelete = onDelete
        self.onUnlock = onUnlock
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
                .foregroundColor(.white) // WHITE text for contrast
                .padding(.horizontal, 10) // SMALLER padding
                .padding(.vertical, 6) // SMALLER padding
                .background(Color.gray.opacity(0.8)) // METALLIC GREY button background
                .cornerRadius(10) // SMALLER corner radius
            }
            
            // Change Category for tasks OR Change Color for blocks
            if task != nil {
                Button(action: onChangeCategory) {
                    VStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.title2)
                        Text("Category")
                            .font(.caption)
                    }
                    .foregroundColor(.white) // WHITE text for contrast
                    .padding(.horizontal, 10) // SMALLER padding
                    .padding(.vertical, 6) // SMALLER padding
                    .background(Color.gray.opacity(0.8)) // METALLIC GREY button background
                    .cornerRadius(10) // SMALLER corner radius
                }
            } else if taskBlock != nil {
                Button(action: onChangeCategory) {
                    VStack(spacing: 4) {
                        Image(systemName: "paintpalette")
                            .font(.title2)
                        Text("Color")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
            }
            
            // Add to Goal - hide for blocks
            if task != nil {
                Button(action: onAddToGoal) {
                    VStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.title2)
                        Text("Goal")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
            }
            
            // Move or Unlock (conditional)
            if let task = task, task.isLocked {
                Button(action: onUnlock) {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.open")
                            .font(.title2)
                        Text("Unlock")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10) // SMALLER padding
                    .padding(.vertical, 6) // SMALLER padding
                    .background(Color.gray.opacity(0.8)) // METALLIC GREY button background
                    .cornerRadius(10) // SMALLER corner radius
                }
            } else if let t = task { // unlocked task: show Lock + Move
                Button(action: onUnlock) {
                    VStack(spacing: 4) {
                        Image(systemName: "lock")
                            .font(.title2)
                        Text("Lock")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
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
                // Removed series-wide lock options from task quick menu per request
            } else if taskBlock != nil {
                // For blocks: show Lock/Unlock button and Move button
                Button(action: onUnlock) {
                    VStack(spacing: 4) {
                        Image(systemName: (blockLocked ?? false) ? "lock.open" : "lock")
                            .font(.title2)
                        Text((blockLocked ?? false) ? "Unlock" : "Lock")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
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
                .padding(.horizontal, 10) // SMALLER padding
                .padding(.vertical, 6) // SMALLER padding
                .background(Color.gray.opacity(0.8)) // METALLIC GREY button background
                .cornerRadius(10) // SMALLER corner radius
            }
        }
        .padding(12) // SMALLER padding
        .background(
            RoundedRectangle(cornerRadius: 16) // SMALLER corner radius
                .fill(Color.gray.opacity(0.9)) // METALLIC GREY background
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
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
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
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
                        .foregroundColor(.white) // WHITE TEXT
                        .strikethrough(task.isComplete)
                        .opacity(task.isComplete ? 0.6 : 1.0)
                    
                    // Priority text - MATCH PRIORITY COLOR
                    Text("Priority: \(task.priority.rawValue.capitalized)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(priorityColor) // MATCH PRIORITY COLOR (Green/Blue/Orange/Red)
                        .opacity(task.isComplete ? 0.6 : 1.0)
                    
                    if let description = task.taskDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7)) // WHITE TEXT
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
                    .foregroundColor(.white.opacity(0.7)) // WHITE TEXT
                    .opacity(task.isComplete ? 0.6 : 1.0)
            }
        }
        .padding(16)
        .background(
            ZStack {
                // MUCH PALER category color background with HIGH transparency
                RoundedRectangle(cornerRadius: 12) // REDUCED corner radius from theme.cardCornerRadius
                    .fill(task.category.color().opacity(0.25)) // LESS TRANSPARENT background
                    .overlay(
                        // Subtle category color stroke - Original + 1px
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                task.category.color().opacity(0.6),
                                lineWidth: 1.5
                            )
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
                    .shadow(color: theme.primaryColor.opacity(0.05), radius: theme.shadowRadius)
            }
        )
        .opacity(task.isComplete ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isComplete)
        .overlay(
            // Lock icon for locked tasks
            Group {
                if task.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.7))
                        )
                        .offset(x: 60, y: -60) // Top-right corner
                }
            },
            alignment: .topTrailing
        )
        .onLongPressGesture {
            // Haptic feedback on long press
            AudioServicesPlaySystemSound(1520) // Haptic vibration
            AudioServicesPlaySystemSound(1057) // Click sound
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
        if Calendar.current.isDate(task.startTime, inSameDayAs: task.endTime) {
            return "\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))"
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
}

// MARK: - Move Task Calendar Views
struct MoveTaskCalendarView: View {
    let task: Task
    let onDateSelected: (Date) -> Void
    let onCancel: () -> Void
    @State private var targetDate: Date
    
    init(task: Task, onDateSelected: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self.onDateSelected = onDateSelected
        self.onCancel = onCancel
        self._targetDate = State(initialValue: task.startTime)
    }
    
    var body: some View {
        NavigationView {
            MonthCalendarView(selectedDate: Binding(
                get: { targetDate },
                set: { newDate in
                    targetDate = newDate
                    onDateSelected(newDate)
                }
            ))
            .navigationTitle("Move Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct MoveTaskBlockCalendarView: View {
    let taskBlock: [Task]
    let onDateSelected: (Date) -> Void
    let onCancel: () -> Void
    @State private var targetDate: Date
    
    init(taskBlock: [Task], onDateSelected: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.taskBlock = taskBlock
        self.onDateSelected = onDateSelected
        self.onCancel = onCancel
        self._targetDate = State(initialValue: taskBlock.first?.startTime ?? Date())
    }
    
    var body: some View {
        NavigationView {
            MonthCalendarView(selectedDate: Binding(
                get: { targetDate },
                set: { newDate in
                    targetDate = newDate
                    onDateSelected(newDate)
                }
            ))
            .navigationTitle("Move Task Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Block Color Picker View
struct BlockColorPickerView: View {
    let taskBlock: TaskBlock
    let onSelected: (String) -> Void
    let onCancel: () -> Void
    
    private let availableColors = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "mint", "cyan", "indigo", "brown"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableColors, id: \.self) { color in
                    Button(action: { onSelected(color) }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorFromString(color))
                                .frame(width: 24, height: 24)
                            Text(color.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            if color == taskBlock.color { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                    }
                }
            }
            .navigationTitle("Change Block Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
}
// MARK: - Category Change View
struct CategoryChangeView: View {
    let task: Task
    let onCategoryChanged: (TaskCategory) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Button(action: {
                        onCategoryChanged(category)
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color())
                                .frame(width: 30)
                            
                            Text(category.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if task.category == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Change Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}