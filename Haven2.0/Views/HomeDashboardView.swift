//
//  HomeDashboardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import AudioToolbox
import FirebaseAuth
import Combine

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    // MARK: - Data Queries
    // Only query small datasets (users, routines)
    // Tasks, taskBlocks, and goals are queried on-demand in ViewModel with predicates
    @Query private var users: [User]
    @Query private var routines: [DailyRoutine]
    
    // MARK: - ViewModel
    @State private var vm = HomeDashboardViewModel()
    
    // MARK: - Computed Properties
    private var currentUser: User? { vm.currentUser }
    private var userRoutines: [DailyRoutine] { vm.userRoutines }
    private var selectedDateTasks: [Task] { vm.selectedDateTasks }
    private var selectedDateTaskBlocks: [TaskBlock] { vm.selectedDateTaskBlocks }
    private var sortedGoals: [Goal] { vm.sortedGoals }
    
    // MARK: - FIXED: Missing State Variables
    @State private var currentTime = Date()
    @State private var showingDayPickerInPlan = false
    @State private var showingCompletionRingPopup = false
    @State private var showingProgressDetails = false
    @State private var showingRecents = false
    @State private var viewMode: HomeViewMode = .tasks
    
    // Undo/Move Logic State
    @State private var undoMoveTimer: Timer?
    @State private var originalTaskDates: [String: Date] = [:]
    @State private var originalBlockDates: [String: [Date]] = [:]
    
    // UI State
    @State private var recentlyCompletedTasks: Set<String> = []
    @State private var showingLevelUp: LevelUpResult? = nil
    @State private var showingFloatingMenuForBlock: [Task]? = nil
    
    // MARK: - View Lifecycle
    private func updateViewModel() {
        vm.modelContext = modelContext
        vm.updateData(users: users, routines: routines)
        vm.refreshSelectedDateData()
    }
    
    // MARK: - Task Card View Helper
    private func taskCardView(task: Task, theme: any AppTheme) -> some View {
        TaskCardView(
            task: task,
            theme: theme,
            onTaskCompleted: vm.handleTaskCompleted,
            onEditTask: { task in
                vm.showingFloatingMenu = task
            },
            onLevelUp: { levelUp in
                vm.handleLevelUp(levelUp: levelUp)
            },
            dailyXPTotal: $vm.dailyXPTotal,
            dailyCrystalsTotal: $vm.dailyCrystalsTotal,
            dailyBonuses: $vm.dailyBonuses,
            onDailyTrackingUpdate: { xp, crystals, action in
                if let action = action, action == "checkSummary" {
                    vm.checkAndShowDailySummary()
                }
            }
        )
    }
    
    enum HomeViewMode: String, CaseIterable {
        case tasks = "Tasks"
        case goals = "Goals"
    }
    
    enum TaskSortOrder: String, CaseIterable {
        case priority = "Priority"
        case mostRecent = "Most Recent"
        case timeSensitive = "Time Sensitive"
        case category = "Category"
        case goal = "Goal"
    }
    
    var body: some View {
        let theme: any AppTheme = themeManager.currentTheme
        
        return NavigationView { rootContent(theme: theme) }
            .onAppear {
                updateViewModel()
            }
            .onChange(of: users) { _, _ in updateViewModel() }
            .onChange(of: routines) { _, _ in updateViewModel() }
            .onChange(of: vm.selectedDate) { _, _ in
                vm.onSelectedDateChanged()
            }
            .sheet(isPresented: $vm.showingAddTask) {
                AddTaskView(selectedDate: vm.selectedDate)
            }
            .sheet(isPresented: $vm.showingCalendar) {
                calendarModalView(theme: theme)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.showingAddBlock) {
                AddBlockView(selectedDate: vm.selectedDate)
                    .presentationDetents([.medium])
            }
            .sheet(item: $vm.showingEditTask) { task in
                // Query all tasks on demand for EditTaskView (needed for overlap checking)
                let allTasks: [Task] = {
                    guard let modelContext = modelContext else { return [] }
                    let descriptor = FetchDescriptor<Task>()
                    return (try? modelContext.fetch(descriptor)) ?? []
                }()
                EditTaskView(task: task, allTasks: allTasks)
            }
            .sheet(item: $vm.showingCategoryChange) { task in
                CategoryChangeView(task: task, onCategoryChanged: { newCategory in
                    task.category = newCategory
                    try? modelContext.save()
                    vm.showingCategoryChange = nil
                }, onCancel: {
                    vm.showingCategoryChange = nil
                })
                .presentationDetents([.medium])
            }
            .sheet(item: $vm.showingMoveToDay) { task in
                MoveTaskCalendarView(task: task, onDateSelected: { date in
                    vm.moveTaskToDay(task, to: date)
                    vm.showingMoveToDay = nil
                }, onCancel: {
                    vm.showingMoveToDay = nil
                })
                .presentationDetents([.medium])
            }
            .sheet(isPresented: Binding(
                get: { vm.showingMoveToDayBlock != nil },
                set: { if !$0 { vm.showingMoveToDayBlock = nil } }
            )) {
                if let taskBlock = vm.showingMoveToDayBlock {
                    MoveTaskBlockCalendarView(taskBlock: taskBlock, onDateSelected: { date in
                        vm.moveTaskBlockToDay(taskBlock, to: date)
                        vm.showingMoveToDayBlock = nil
                    }, onCancel: {
                        vm.showingMoveToDayBlock = nil
                    })
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: Binding(
                get: { vm.showingEditBlock != nil },
                set: { if !$0 { vm.showingEditBlock = nil } }
            )) {
                if let editBlock = vm.showingEditBlock {
                    EditBlockView(
                        taskBlock: editBlock.taskBlock,
                        tasksInBlock: editBlock.tasks,
                        allTasks: tasks
                    )
                }
            }
            .sheet(item: $vm.showingBlockColorPicker) { block in
                BlockColorPickerView(taskBlock: block, onSelected: { newColor in
                    block.color = newColor
                    try? modelContext.save()
                    vm.showingBlockColorPicker = nil
                }, onCancel: {
                    vm.showingBlockColorPicker = nil
                })
                .presentationDetents([.medium])
            }
            .sheet(item: $vm.showingEditGoal) { goal in
                EditGoalInlineView(goal: goal)
            }
            .sheet(item: $vm.showingAddTaskToGoal) { goal in
                AddTaskToGoalView(goal: goal)
            }
            .sheet(item: $vm.showingLinkTaskToGoal) { task in
                LinkTaskToGoalView(task: task)
            }
            .sheet(item: $vm.selectedGoal) { goal in
                NavigationView {
                    GoalsDetailView(goal: goal)
                }
            }
            .alert("Delete Task Block?", isPresented: $vm.showDeleteBlockAlert) {
                Button("Delete Block + Tasks", role: .destructive) {
                    if let blockTasks = vm.pendingDeleteBlockTasks {
                        vm.deleteTaskBlock(blockTasks)
                    }
                    vm.pendingDeleteBlockTasks = nil
                }
                Button("Cancel", role: .cancel) {
                    vm.pendingDeleteBlockTasks = nil
                }
            } message: {
                Text("This will delete the task block and all tasks inside it.")
            }
            .alert(item: $vm.showingDeleteGoalConfirmation) { goal in
                Alert(
                    title: Text("Delete Goal?"),
                    message: Text("This will remove the goal but keep all linked tasks."),
                    primaryButton: .destructive(Text("Delete")) {
                        modelContext.delete(goal)
                        try? modelContext.save()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $vm.showingPauseGoalConfirmation) { goal in
                Alert(
                    title: Text(goal.status == .paused ? "Resume Goal?" : "Pause Goal?"),
                    message: Text(goal.status == .paused 
                        ? "This will add the goal and its tasks back to your workflow."
                        : "This will temporarily hide the goal and all its tasks from your workflow."),
                    primaryButton: .default(Text(goal.status == .paused ? "Resume" : "Pause")) {
                        goal.status = goal.status == .paused ? .active : .paused
                        try? modelContext.save()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: Binding(
                get: { showingLevelUp != nil },
                set: { if !$0 { showingLevelUp = nil } }
            )) {
                if let levelUp = showingLevelUp {
                    LevelUpView(levelUpResult: levelUp, isPresented: Binding(
                        get: { showingLevelUp != nil },
                        set: { if !$0 { showingLevelUp = nil } }
                    ))
                    .interactiveDismissDisabled(true)
                }
            }
            .fullScreenCover(isPresented: $vm.showingImmersiveWorkingOn) {
                if let currentTask = getCurrentTask() {
                    ImmersiveWorkingOnView(task: currentTask) {
                        vm.showingImmersiveWorkingOn = false
                    }
                }
            }
            .overlay(floatingMenusOverlay)
            .overlay(dailySummaryOverlay)
            .overlay(undoMoveOverlay)
            .overlay(completionRingOverlay)
            .onAppear {
                updateViewModel()
                vm.checkEarnedRewardsOnAppOpen()
                
                if let user = currentUser {
                    if userRoutines.isEmpty {
                        _ = RoutineService.shared.createDefaultRoutines(userID: user.id, in: modelContext)
                    }
                    RoutineService.shared.archiveExpiredRoutines(in: modelContext)
                }
                
                NotificationCenter.default.publisher(for: NSNotification.Name("DeveloperTestLevelUp"))
                    .sink { [weak vm] notification in
                        if let userInfo = notification.userInfo,
                           let newLevel = userInfo["newLevel"] as? Int,
                           let unlockedThemes = userInfo["unlockedThemes"] as? [String],
                           let unlockedFeatures = userInfo["unlockedFeatures"] as? [String] {
                            
                            let levelUpResult = LevelUpResult(
                                newLevel: newLevel,
                                unlockedThemes: unlockedThemes,
                                unlockedFeatures: unlockedFeatures
                            )
                            
                            vm?.handleLevelUp(levelUp: levelUpResult)
                        }
                    }
                    .store(in: &vm.levelUpNotificationObserver)
            }
    }
    // MARK: - Root Content
    @ViewBuilder
    private func rootContent(theme: any AppTheme) -> some View {
        ZStack {
            // Theme-aware home background (using primary gradient)
            theme.primaryGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                        // Top Navigation Bar
                    topNavigationView(theme: theme)
                        .padding(.top, 0)
                    
                    // Plan vs Focus Toggle - Always visible at top
                    modeToggleView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Content based on mode
                    if vm.homeMode == .focus {
                        focusViewContent(theme: theme)
                    } else {
                        planViewContent(theme: theme)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Overlay Computed Properties
    @ViewBuilder
    private var floatingMenusOverlay: some View {
        Group {
            taskFloatingMenu
            taskBlockFloatingMenu
            goalFloatingMenu
        }
    }
    
    @ViewBuilder
    private var taskFloatingMenu: some View {
        if let task = vm.showingFloatingMenu {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.showingFloatingMenu = nil
                        }
                    }
                
                FloatingActionMenu(
                    task: task,
                    taskBlock: nil,
                    theme: themeManager.currentTheme,
                    blockLocked: nil,
                    onEdit: { vm.showingFloatingMenu = nil; vm.showingEditTask = task },
                    onChangeCategory: { vm.showingFloatingMenu = nil; vm.showingCategoryChange = task },
                    onAddToGoal: { vm.showingFloatingMenu = nil; vm.showingLinkTaskToGoal = task },
                    onMove: { vm.showingFloatingMenu = nil; vm.showingMoveToDay = task },
                    onDelete: { vm.showingFloatingMenu = nil; deleteTask(task) },
                    onUnlock: { vm.showingFloatingMenu = nil; task.isLocked.toggle(); try? modelContext.save() },
                    onDismiss: { vm.showingFloatingMenu = nil }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                    removal: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                ))
            }
        }
    }
    
    @ViewBuilder
    private var taskBlockFloatingMenu: some View {
        if let taskBlock = showingFloatingMenuForBlock {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingFloatingMenuForBlock = nil
                        }
                    }
                
                let _blockObj: TaskBlock? = {
                    if let firstTask = taskBlock.first, let block = firstTask.taskBlock {
                        return block
                    }
                    return nil
                }()
                
                FloatingActionMenu(
                    task: nil,
                    taskBlock: taskBlock,
                    theme: themeManager.currentTheme,
                    blockLocked: _blockObj?.isLocked ?? false,
                    onEdit: {
                        showingFloatingMenuForBlock = nil
                        if let firstTask = taskBlock.first, let taskBlockObj = firstTask.taskBlock {
                            vm.showingEditBlock = (taskBlockObj, taskBlock)
                        }
                    },
                    onChangeCategory: {
                        showingFloatingMenuForBlock = nil
                        if let firstTask = taskBlock.first, let taskBlockObj = firstTask.taskBlock {
                            vm.showingBlockColorPicker = taskBlockObj
                        }
                    },
                    onAddToGoal: { showingFloatingMenuForBlock = nil },
                    onMove: { showingFloatingMenuForBlock = nil; vm.showingMoveToDayBlock = taskBlock },
                    onDelete: { showingFloatingMenuForBlock = nil; vm.pendingDeleteBlockTasks = taskBlock; vm.showDeleteBlockAlert = true },
                    onUnlock: {
                        showingFloatingMenuForBlock = nil
                        if let firstTask = taskBlock.first, let taskBlockObj = firstTask.taskBlock {
                            taskBlockObj.isLocked.toggle()
                            try? modelContext.save()
                        }
                    },
                    onDismiss: { showingFloatingMenuForBlock = nil }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                    removal: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                ))
            }
        }
    }
    
    @ViewBuilder
    private var goalFloatingMenu: some View {
        if let goal = vm.showingGoalFloatingMenu {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.showingGoalFloatingMenu = nil
                        }
                    }
                
                GoalFloatingActionMenu(
                    goal: goal,
                    onEdit: { vm.showingGoalFloatingMenu = nil; vm.showingEditGoal = goal },
                    onAddTask: { vm.showingGoalFloatingMenu = nil; vm.showingAddTaskToGoal = goal },
                    onPause: { vm.showingGoalFloatingMenu = nil; vm.showingPauseGoalConfirmation = goal },
                    onDelete: { vm.showingGoalFloatingMenu = nil; vm.showingDeleteGoalConfirmation = goal },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.showingGoalFloatingMenu = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                    removal: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                ))
            }
        }
    }
    
    @ViewBuilder
    private var dailySummaryOverlay: some View {
        Group {
            if let summary = vm.showingDailySummary {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            vm.showingDailySummary = nil
                        }
                    
                    DailySummaryPopUpView(summary: summary) {
                        vm.showingDailySummary = nil
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var undoMoveOverlay: some View {
        Group {
            if let task = vm.showingUndoMove {
                VStack {
                    Spacer()
                    HStack {
                        Text("Task moved to another day")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Undo") {
                            vm.undoMoveTask(task)
                            vm.showingUndoMove = nil
                            vm.undoMoveTimer?.invalidate()
                            vm.undoMoveTimer = nil
                        }
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            
            if let taskBlock = vm.showingUndoMoveBlock {
                VStack {
                    Spacer()
                    HStack {
                        Text("Task block moved to another day")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Undo") {
                            vm.undoMoveTaskBlock(taskBlock)
                            vm.showingUndoMoveBlock = nil
                            vm.undoMoveTimer?.invalidate()
                            vm.undoMoveTimer = nil
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
    }
    
    @ViewBuilder
    private var completionRingOverlay: some View {
        Group {
            if showingCompletionRingPopup {
                VStack {
                    HStack {
                        Spacer()
                        completionRingPopupView(theme: themeManager.currentTheme)
                            .transition(.scale.combined(with: .opacity))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 70)
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
    }
    
    // MARK: - Hero Section (Date/Level) - Focus View Only
    private func heroSection(user: User, theme: any AppTheme) -> some View {
        VStack(spacing: 12) {
                // Day Scroller
            InteractiveDateHeader(
                    selectedDate: $vm.selectedDate,
                user: user
            )
            
            // Date Container with Level Ring
            HStack(spacing: 16) {
                // Date Text
                VStack(alignment: .leading, spacing: 4) {
                        Text(dateString(for: vm.selectedDate))
                        .font(AppStyleSheet.font(for: .title))
                        .foregroundColor(.white)
                        .appTextStyle(.title, theme: themeManager.currentTheme)
                }
                
                Spacer()
                
                // Level Ring (tappable to toggle)
                Button(action: {
                        vm.showingLevelToggle.toggle()
                }) {
                        levelRingView(user: user, showDailyProgress: vm.showingLevelToggle)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Level Ring View (with toggle)
    private func levelRingView(user: User, showDailyProgress: Bool) -> some View {
        let theme = themeManager.currentTheme
        
        return ZStack {
            if showDailyProgress {
                // Daily Progress Ring
                let completedCount = selectedDateTasks.filter { $0.isComplete }.count
                let totalCount = selectedDateTasks.count
                let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(.white)
                }
            } else {
                // Overall Level Ring
                let xpProgress = LevelService.calculateProgress(user: user)
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: xpProgress)
                    .stroke(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(user.level)")
                        .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Mode Toggle (Bubble Bounce Animation, 1/3 Width)
    private var modeToggleView: some View {
        let theme = themeManager.currentTheme
        
        return HStack(spacing: 0) {
            // Focus Button - Fixed Width (1/3 of total)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                    vm.homeMode = .focus
                }
            }) {
                Text("Focus")
                    .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                    .foregroundColor(vm.homeMode == .focus ? theme.textPrimary : theme.textPrimary.opacity(0.6))
                    .frame(width: UIScreen.main.bounds.width / 6) // 1/3 width total (1/6 each)
                    .frame(height: 40)
                    .background(
                        Group {
                    if vm.homeMode == .focus {
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .fill(theme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    }
                        }
                    )
            }
            
            // Plan Button - Fixed Width (1/3 of total)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                    vm.homeMode = .plan
                }
            }) {
                Text("Plan")
                    .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                    .foregroundColor(vm.homeMode == .plan ? theme.textPrimary : theme.textPrimary.opacity(0.6))
                    .frame(width: UIScreen.main.bounds.width / 6) // 1/3 width total (1/6 each)
                    .frame(height: 40)
                    .background(
                        Group {
                            if vm.homeMode == .plan {
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .fill(theme.glassBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                    )
                            }
                        }
                    )
            }
        }
        .frame(width: UIScreen.main.bounds.width / 3) // Total width is 1/3 of screen
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(theme.glassBackground.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .stroke(theme.glassBorder.opacity(0.5), lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Focus View Content
    private func focusViewContent(theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
            // Agenda Area - MOVED ABOVE Dynamic Box
            if !vm.isViewAllTasksMode && !selectedDateTasks.isEmpty {
                agendaAreaView(theme: theme)
                    .padding(.horizontal, 20)
            }
            
            // Dynamic Focus Box (hero section removed)
            VStack(spacing: 0) {
                DynamicFocusBox(
                    selectedDate: vm.selectedDate,
                    allTasks: selectedDateTasks,
                    allTaskBlocks: selectedDateTaskBlocks,
                    previewTask: $vm.previewTaskForDynamicBox,
                    isViewAllTasksMode: $vm.isViewAllTasksMode
                )
                .padding(.horizontal, 20)
                
                // Complete/Snooze buttons (only for single tasks in dynamic mode, not in preview)
                if !vm.isViewAllTasksMode,
                   let previewTask = vm.previewTaskForDynamicBox,
                   selectedDateTasks.filter({ $0.id == previewTask.id }).count == 1 {
                    completeSnoozeButtons(task: previewTask, theme: theme)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                } else if !vm.isViewAllTasksMode,
                          vm.previewTaskForDynamicBox == nil,
                          let singleTask = getCurrentSingleTask() {
                    completeSnoozeButtons(task: singleTask, theme: theme)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
            }
        }
    }
    
    // MARK: - Plan View Content
    private func planViewContent(theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
                // Day Scroller
            if showingDayPickerInPlan {
                InfiniteDaySelector(
                        selectedDate: $vm.selectedDate,
                    onDateChanged: { date in
                            vm.selectedDate = date
                        DatePersistenceService.shared.saveSelectedDate(date)
                    },
                    hasEvents: { _ in false },
                    showMonthHeader: true
                )
                .frame(height: 120)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
                // Date Container - REMOVED (month/year is now in topNavigationView only)
            
            // Summary Card - REMOVED per user request
            // summaryCardView(theme: theme)
            //     .padding(.horizontal, 20)
            
                // Filter Button - Only show "ALL TASKS" (removed secondary "All Tasks" text)
                HStack {
                    Text("ALL TASKS")
                        .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(theme.textPrimary)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: Show filter modal
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(theme.headerFont) // Use theme headerFont (11pt, semibold)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .padding(.horizontal, theme.sectionPadding)
                
                // Master Task List
            masterTaskListView(theme: theme)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Agenda Area (Focus View)
    private func agendaAreaView(theme: any AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Calendar.current.isDateInToday(vm.selectedDate) ? "TODAY'S AGENDA" : "DAY'S AGENDA")
                .font(.system(size: 10, weight: .semibold, design: .default)) // Reduced by 2
                .foregroundColor(theme.textPrimary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            
            // Show only tasks in current focus period
            let currentPeriod = FocusPeriod.currentPeriod()
            let agendaTasks = selectedDateTasks.filter { task in
                let calendar = Calendar.current
                let taskHour = calendar.component(.hour, from: task.startTime)
                let periodRange = currentPeriod.timeRange
                
                if currentPeriod == .lateNight {
                    return taskHour >= periodRange.start || taskHour < periodRange.end
                } else {
                    return taskHour >= periodRange.start && taskHour < periodRange.end
                }
            }
            .sorted { $0.startTime < $1.startTime } // Chronological
            .sorted { task1, task2 in
                // Then by priority if same time
                let priorityOrder: [PriorityType] = [.urgent, .high, .normal, .low]
                let p1 = priorityOrder.firstIndex(of: task1.priority) ?? 999
                let p2 = priorityOrder.firstIndex(of: task2.priority) ?? 999
                if task1.startTime == task2.startTime {
                    return p1 < p2
                }
                return false
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(agendaTasks, id: \.id) { task in
                        agendaTaskCard(task: task, theme: theme) {
                            // Enter Preview Mode with animation
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                vm.previewTaskForDynamicBox = task
                            }
                        }
                        .id(task.id)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Get Current Single Task (for Complete/Snooze buttons)
    private func getCurrentSingleTask() -> Task? {
        // Get tasks in next 8 hours
        let now = Date()
        let calendar = Calendar.current
        let eightHoursFromNow = calendar.date(byAdding: .hour, value: 8, to: now) ?? now
        
        let upcomingTasks = selectedDateTasks.filter { task in
            let isSameDay = calendar.isDate(task.startTime, inSameDayAs: vm.selectedDate)
            guard isSameDay && !task.isComplete else { return false }
            return task.startTime >= now && task.startTime <= eightHoursFromNow
        }
        
        // If only one task, return it
        if upcomingTasks.count == 1 {
            return upcomingTasks.first
        }
        
        return nil
    }
    
        // MARK: - Complete/Snooze Buttons - smaller, not capitalized, outline only
    private func completeSnoozeButtons(task: Task, theme: any AppTheme) -> some View {
        HStack(spacing: 16) {
            // Complete Button - smaller, not capitalized, outline only
            Button(action: {
                vm.handleTaskCompleted(task.id)
            }) {
                Text("Complete") // Removed .uppercase()
                    .font(.system(size: 14, weight: .regular, design: .default)) // Smaller font
                    .foregroundColor(buttonTextColor(for: theme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10) // Reduced padding
                    .background(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .stroke(buttonOutlineColor(for: theme), lineWidth: theme.cardBorderWidth) // Outline only
                    )
            }
            
            // Snooze Button - smaller, not capitalized, outline only
            Button(action: {
                // Push task 15 minutes
                let calendar = Calendar.current
                if let newStart = calendar.date(byAdding: .minute, value: 15, to: task.startTime),
                   let newEnd = calendar.date(byAdding: .minute, value: 15, to: task.endTime) {
                    task.startTime = newStart
                    task.endTime = newEnd
                    try? modelContext.save()
                }
            }) {
                Text("Snooze") // Removed .uppercase()
                    .font(.system(size: 14, weight: .regular, design: .default)) // Smaller font
                    .foregroundColor(buttonTextColor(for: theme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10) // Reduced padding
                    .background(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .stroke(buttonOutlineColor(for: theme), lineWidth: theme.cardBorderWidth) // Outline only
                    )
            }
        }
    }
    
    // Helper functions for button styling - use theme properties directly
    private func buttonOutlineColor(for theme: any AppTheme) -> Color {
        // Use theme's existing cardStroke for outline
        return theme.cardStroke
    }
    
    private func buttonTextColor(for theme: any AppTheme) -> Color {
        // Use theme's textPrimary - themes already handle text colors correctly
        return theme.textPrimary
    }
    
        // MARK: - Agenda Task Card - Bigger pills, fix cutting off
    private func agendaTaskCard(task: Task, theme: any AppTheme, onTap: @escaping () -> Void) -> some View {
        // Use category color from TaskCategory's built-in color() method
        let categoryColor = task.category.color()
        
        return Button(action: onTap) {
            HStack {
                // Left: Task name and priority
                VStack(alignment: .leading, spacing: 6) { // Increased spacing
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold, design: .default)) // Increased from 11
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(2) // Allow 2 lines to prevent cutting off
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priorityColor(for: task.priority))
                            .frame(width: 8, height: 8) // Increased from 6
                        Text(task.priority.rawValue.capitalized)
                            .font(.system(size: 10, weight: .regular, design: .default)) // Increased from 8
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Right: Time and checkmark if completed
                HStack(spacing: 6) {
                    Text(timeString(for: task.startTime))
                        .font(.system(size: 11, weight: .regular, design: .default)) // Increased from 9
                        .foregroundColor(theme.textPrimary.opacity(0.7))
                    
                    if task.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16)) // Increased from 14
                    }
                }
            }
            .padding(.horizontal, theme.cardPadding)
            .padding(.vertical, theme.cardVerticalPadding) // Increased from /2
            .frame(minWidth: 140) // Minimum width to prevent cutting off
            .background(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                task.isComplete.toggle()
                try? modelContext.save()
            }) {
                Label(task.isComplete ? "Uncheck as done" : "Mark as done", 
                      systemImage: task.isComplete ? "xmark.circle" : "checkmark.circle")
            }
        }
        .scaleEffect(vm.previewTaskForDynamicBox?.id == task.id ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.previewTaskForDynamicBox?.id)
    }
    
        // MARK: - Summary Card
    private func summaryCardView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return VStack(spacing: 16) {
            // Daily Progress Ring
            ZStack {
                Circle()
                        .stroke(theme.textPrimary.opacity(0.2), lineWidth: 16)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 8) {
                    Text("\(completedCount)/\(totalCount)")
                        .appTextStyle(.gamifiedNumber, theme: theme)
                    
                    Text("Tasks Completed Today")
                        .font(AppStyleSheet.font(for: .body))
                            .foregroundColor(theme.textPrimary.opacity(theme.textSecondaryOpacity))
                }
            }
        }
            .padding(theme.sectionSpacing)
        .background(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.glassBackground)
                .overlay(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                    )
            )
        }
        
        // MARK: - Master Task List
    private func masterTaskListView(theme: any AppTheme) -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Dynamic sectioning based on filter
            let filteredTasks = getFilteredTasks()
            let sections = groupTasksByFilter(filteredTasks)
            
            ForEach(sections.keys.sorted(), id: \.self) { sectionTitle in
                if let sectionTasks = sections[sectionTitle], !sectionTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(sectionTitle)
                            .appTextStyle(.sectionHeader, theme: theme)
                                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                        
                        // Group tasks by taskBlockID - show blocks as single cards
                        let tasksByBlock = Dictionary(grouping: sectionTasks) { $0.taskBlockID ?? "" }
                        let standaloneTasks = tasksByBlock[""] ?? []
                        let taskBlocks = tasksByBlock.filter { $0.key != "" }
                        
                        // Display task blocks first
                        ForEach(Array(taskBlocks.keys), id: \.self) { blockID in
                            if let blockTasks = taskBlocks[blockID], !blockTasks.isEmpty,
                               let taskBlock = vm.getTaskBlock(for: blockID) {
                                taskBlockCardView(tasks: blockTasks, taskBlock: taskBlock, theme: theme)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Then display standalone tasks
                        ForEach(standaloneTasks, id: \.id) { task in
                            // Category-colored card
                            taskCardView(task: task, theme: theme)
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                        vm.showingEditTask = task
                                }
                                .id(task.id)
                        }
                    }
                    .id(sectionTitle)
                }
            }
        }
    }
    
    // MARK: - Task Block Card View (for Plan View)
    private func taskBlockCardView(tasks: [Task], taskBlock: TaskBlock, theme: any AppTheme) -> some View {
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        guard let firstTask = sortedTasks.first, let lastTask = sortedTasks.last else {
            return AnyView(EmptyView())
        }
        
        // Calculate time span - BOLD all caps format
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTimeStr = timeFormatter.string(from: firstTask.startTime).uppercased()
        let endTimeStr = timeFormatter.string(from: lastTask.endTime).uppercased()
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Square checkbox for block
                    Button(action: {
                        let allComplete = tasks.allSatisfy { $0.isComplete }
                        for task in tasks {
                            task.isComplete = !allComplete
                        }
                        try? modelContext.save()
                    }) {
                        Image(systemName: tasks.allSatisfy { $0.isComplete } ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(tasks.allSatisfy { $0.isComplete } ? .green : theme.textPrimary.opacity(0.6))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Block title
                        Text(taskBlock.title)
                            .font(theme.headerFont)
                            .foregroundColor(theme.textPrimary)
                            .strikethrough(tasks.allSatisfy { $0.isComplete })
                            .opacity(tasks.allSatisfy { $0.isComplete } ? 0.6 : 1.0)
                        
                        // Time span display (3PM-4PM) in BOLD all caps - using theme smallFontSize (7-8pt)
                        Text("\(startTimeStr) - \(endTimeStr)")
                            .font(theme.bodyFont) // Using theme bodyFont
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(theme.textPrimary.opacity(0.8))
                            .opacity(tasks.allSatisfy { $0.isComplete } ? 0.6 : 1.0)
                        
                        Text("\(tasks.count) tasks")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                            .opacity(tasks.allSatisfy { $0.isComplete } ? 0.6 : 1.0)
                    }
                    
                    Spacer()
                    
                    // Category icon on right - with contrasting outline
                    Image(systemName: firstTask.category.icon)
                        .font(.title3)
                        .foregroundColor(firstTask.category.color())
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    Circle()
                                        .stroke(firstTask.category.color().opacity(0.6), lineWidth: 1.5)
                                )
                        )
                        .frame(width: 32, height: 32)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .fill(theme.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                        )
                )
            }
            .onLongPressGesture(minimumDuration: 0.3) { // Lighter, more sensitive
                // Lighter haptic feedback - similar to goal element
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                
                // Smooth selection haptic
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.prepare()
                selectionGenerator.selectionChanged()
                
                showingFloatingMenuForBlock = tasks
            }
        )
    }
    
    // MARK: - Helper Functions for Plan View
    private func getFilteredTasks() -> [Task] {
            switch vm.selectedFilter {
        case .all:
            return selectedDateTasks
        case .category:
            return selectedDateTasks.sorted { $0.category.rawValue < $1.category.rawValue }
        case .goals:
            return selectedDateTasks.filter { $0.goalID != nil }
        case .priority:
            return selectedDateTasks.sorted { task1, task2 in
                let priorityOrder: [PriorityType] = [.urgent, .high, .normal, .low]
                let p1 = priorityOrder.firstIndex(of: task1.priority) ?? 999
                let p2 = priorityOrder.firstIndex(of: task2.priority) ?? 999
                return p1 < p2
            }
        case .timePeriod:
                return selectedDateTasks
        case .status:
            let incomplete = selectedDateTasks.filter { !$0.isComplete }
            let complete = selectedDateTasks.filter { $0.isComplete }
            return incomplete + complete
        case .dateRange:
            return selectedDateTasks
        }
    }
    
    private func groupTasksByFilter(_ tasks: [Task]) -> [String: [Task]] {
            switch vm.selectedFilter {
        case .timePeriod:
            var groups: [String: [Task]] = [:]
            let calendar = Calendar.current
            
            for task in tasks {
                let hour = calendar.component(.hour, from: task.startTime)
                let period: String
                if hour >= 5 && hour < 12 {
                    period = "Morning Tasks"
                } else if hour >= 12 && hour < 17 {
                    period = "Afternoon Tasks"
                } else if hour >= 17 && hour < 22 {
                    period = "Evening Tasks"
                } else {
                    period = "Night Tasks"
                }
                groups[period, default: []].append(task)
            }
            return groups
        default:
            return ["All Tasks": tasks]
        }
    }
    
    // MARK: - Completion Ring Popup View
    private func completionRingPopupView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        guard let user = currentUser else {
                return AnyView(Text("No user data").foregroundColor(.white))
        }
        
        return AnyView(popupContentView(user: user, completedCount: completedCount, totalCount: totalCount, progress: progress))
    }
    
    @ViewBuilder
    private func popupContentView(user: User, completedCount: Int, totalCount: Int, progress: Double) -> some View {
        VStack(spacing: 12) {
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
                
                    // Progress bars on the right
                VStack(spacing: 8) {
                    let currentLevelXP = LevelService.xpForLevel(user.level)
                    let nextLevelXP = LevelService.xpForLevel(user.level + 1)
                    let xpInCurrentLevel = user.currentXP - currentLevelXP
                    let xpNeeded = nextLevelXP - currentLevelXP
                    
                    progressBarView(title: "XP", value: Double(xpInCurrentLevel), maxValue: Double(xpNeeded), color: .purple)
                    progressBarView(title: "Level", value: Double(user.level), maxValue: 50, color: .blue)
                    
                    HStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 16))
                        Text("\(user.gamificationCurrency)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                                .fill(LinearGradient(colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                                .overlay(Capsule().stroke(LinearGradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5))
                        )
                    }
                    .frame(width: 150)
                }
            }
            .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
                )
            .frame(width: 600)
    }
    
    private func progressBarView(title: String, value: Double, maxValue: Double, color: Color) -> some View {
        let progress = maxValue > 0 ? min(value / maxValue, 1.0) : 0.0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                    Text(title).font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.9))
                Spacer()
                    Text("\(Int(value))/\(Int(maxValue))").font(.caption).foregroundColor(.white.opacity(0.7))
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.2)).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    }
                }.frame(height: 8)
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationView(theme: any AppTheme) -> some View {
        HStack {
            // Left: Month/Year (NOV 2025) - Calendar Dropdown (Top Left) - ORIGINAL IMPLEMENTATION
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingDayPickerInPlan.toggle()
                }
            }) {
                Text(monthYearString(from: vm.selectedDate))
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
            
            // Center section
            HStack(spacing: 16) {
                completionRingView(theme: theme)
                if let user = currentUser {
                    HStack(spacing: 12) {
                        CrystalCounterView(currentCrystals: user.gamificationCurrency)
                        CompactMomentumView(momentumDays: user.momentumDays)
                    }
                    .frame(minWidth: 150)
                }
            }
            
            Spacer()
            
            // Action Buttons - use theme colors, not individual colors
            HStack(spacing: 8) {
                Button(action: { vm.showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.textPrimary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.glassBackground.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                }
                
                Button(action: { vm.showingAddBlock = true }) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title2)
                        .foregroundColor(theme.textPrimary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.glassBackground.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Completion Ring
    private func completionRingView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return HStack(spacing: 6) {
            Text("\(completedCount)/\(totalCount)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingCompletionRingPopup.toggle()
                }
            }) {
                ZStack {
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 2).frame(width: 32, height: 32)
                        Circle().trim(from: 0, to: CGFloat(progress))
                            .stroke(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                        Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                    }
                }
            }
        }
    
    // MARK: - Calendar Modal View
    private func calendarModalView(theme: any AppTheme) -> some View {
        NavigationView {
            VStack(spacing: 0) {
                MonthCalendarView(selectedDate: Binding(
                        get: { vm.selectedDate },
                    set: { newDate in
                            vm.selectedDate = newDate
                        DatePersistenceService.shared.saveSelectedDate(newDate)
                        let calendar = Calendar.current
                        if calendar.dateComponents([.day], from: Date(), to: newDate).day ?? 0 > 0 {
                            DatePersistenceService.shared.saveLastWorkedDate(newDate)
                        }
                    }
                ))
                
                HStack(spacing: 12) {
                    Button("Today") {
                        withAnimation {
                                vm.selectedDate = Date()
                            DatePersistenceService.shared.saveSelectedDate(Date())
                                vm.showingCalendar = false
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                        Button("Done") {
                            vm.showingCalendar = false
                        }
                    .buttonStyle(.borderedProminent)
                    }
                .padding()
                }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
                .background(Color(.systemBackground))
            }
        }
    // MARK: - Helper Functions for Date Formatting
        private func monthYearString(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date) // Removed .uppercased() for normal text
        }
        
        private func timeString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        private func dateString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }

        private func deleteTask(_ task: Task) {
            modelContext.delete(task)
            try? modelContext.save()
        }

        // MARK: - Missing Helper Functions (Stubbed for compilation)
        // MARK: - Removed: checkAndShowDailySummary and isFromInactiveRoutine moved to ViewModel
        // Use vm.checkAndShowDailySummary() and vm.isFromInactiveRoutine(task) instead

    private func getCurrentTask() -> Task? {
        let now = Date()
        let calendar = Calendar.current
        return tasks.first { task in
            let isToday = calendar.isDateInToday(task.startTime)
                let isSelectedDate = calendar.isDate(task.startTime, inSameDayAs: vm.selectedDate)
            let isActive = now >= task.startTime && now <= task.endTime
            let isIncomplete = !task.isComplete
            let notFromPausedGoal = task.goal == nil || task.goal?.status != .paused
            let notFromInactiveRoutine = !vm.isFromInactiveRoutine(task)
            
            return (isToday || isSelectedDate) && isActive && isIncomplete && notFromPausedGoal && notFromInactiveRoutine
        }
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
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onEdit) {
                VStack(spacing: 4) {
                        Image(systemName: "pencil").font(.title2)
                        Text("Edit").font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8)).cornerRadius(10)
                }
                
                Button(action: onChangeCategory) {
                    VStack(spacing: 4) {
                        Image(systemName: task != nil ? "tag" : "paintpalette").font(.title2)
                        Text(task != nil ? "Category" : "Color").font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8)).cornerRadius(10)
                }
                
            if task != nil {
                Button(action: onAddToGoal) {
                    VStack(spacing: 4) {
                            Image(systemName: "target").font(.title2)
                            Text("Goal").font(.caption)
                    }
                    .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.gray.opacity(0.8)).cornerRadius(10)
                    }
                }
                
                Button(action: onUnlock) {
                    VStack(spacing: 4) {
                        Image(systemName: (task?.isLocked ?? blockLocked ?? false) ? "lock.open" : "lock").font(.title2)
                        Text((task?.isLocked ?? blockLocked ?? false) ? "Unlock" : "Lock").font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8)).cornerRadius(10)
                }
                
                Button(action: onMove) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down").font(.title2)
                        Text("Move").font(.caption)
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(theme.cardBackground).cornerRadius(12)
                }
                
            Button(action: onDelete) {
                VStack(spacing: 4) {
                        Image(systemName: "trash").font(.title2)
                        Text("Delete").font(.caption)
                }
                .foregroundColor(.red)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8)).cornerRadius(10)
                }
            }
            .padding(12)
        .background(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.glassBackground)
                    .overlay(RoundedRectangle(cornerRadius: theme.cardCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth))
        )
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: Task
    let theme: any AppTheme
    let onTaskCompleted: ((String) -> Void)?
    let onEditTask: ((Task) -> Void)?
    let onLevelUp: ((LevelUpResult) -> Void)?
    @Binding var dailyXPTotal: Int
    @Binding var dailyCrystalsTotal: Int
    @Binding var dailyBonuses: [String]
        var onDailyTrackingUpdate: ((Int, Int, String?) -> Void)?
        
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingReflectionPrompt: Task? = nil
    
    var body: some View {
        mainContent
            .padding(16)
            .background(cardBackground)
            .opacity(task.isComplete ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: task.isComplete)
            // REMOVED: Old reflection overlay
            // .overlay(goalReflectionPulse, alignment: .trailing)
            .overlay(lockIconOverlay, alignment: .topTrailing)
            .onLongPressGesture(minimumDuration: 0.3) { // Lighter, more sensitive (reduced from default)
                // Lighter haptic feedback - similar to goal element
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                
                // Smooth selection haptic
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.prepare()
                selectionGenerator.selectionChanged()
                
                onEditTask?(task)
            }
            .sheet(isPresented: Binding(
                get: { showingReflectionPrompt != nil },
                set: { if !$0 { showingReflectionPrompt = nil } }
            )) {
                reflectionSheetContent
            }
    }
    
    private var mainContent: some View {
        HStack(spacing: 12) {
            // Square tick on left
            Button(action: { handleTaskCompletion() }) {
                Image(systemName: task.isComplete ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(task.isComplete ? completionColor : theme.textSecondary)
            }
            
            taskContent
            
            Spacer()
            
            // Category icon on right - with contrasting outline
            Image(systemName: task.category.icon)
                .font(.title3)
                .foregroundColor(task.category.color())
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(theme.glassBackground.opacity(0.5))
                        .overlay(
                            Circle()
                                .stroke(task.category.color().opacity(0.6), lineWidth: 1.5)
                        )
                )
                .frame(width: 32, height: 32)
        }
        .frame(maxWidth: .infinity) // Take up more width
    }
    
    // Computed property for time span text (outside ViewBuilder)
    private var timeSpanText: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTimeStr = timeFormatter.string(from: task.startTime).uppercased()
        let endTimeStr = timeFormatter.string(from: task.endTime).uppercased()
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    private var taskContent: some View {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                    Text(task.title).appTextStyle(.taskTitle, theme: theme).strikethrough(task.isComplete).opacity(task.isComplete ? theme.textTertiaryOpacity : 1.0)
                    if task.isRoutineTask { Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow) }
                }
                if task.goal != nil { goalMilestoneBadges }
            
            // Time span display (3PM-4PM) in BOLD all caps - using theme smallFontSize
            Text(timeSpanText)
                .font(theme.bodyFont) // Using theme bodyFont
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(theme.textPrimary.opacity(0.8))
                .opacity(task.isComplete ? 0.6 : 1.0)
            
                Text("Priority: \(task.priority.rawValue.capitalized)").font(.system(size: 11)).foregroundColor(priorityColor).opacity(task.isComplete ? 0.6 : 1.0)
                if let description = task.taskDescription { Text(description).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(2).opacity(task.isComplete ? 0.6 : 1.0) }
            }
        }
        
        @ViewBuilder
    private var goalMilestoneBadges: some View {
                        HStack(spacing: 6) {
                if let milestone = task.milestone, let goal = task.goal {
                    Text(milestone.title).font(.caption2).fontWeight(.medium).foregroundColor(.pink).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.white.opacity(0.15)))
                }
                if let goal = task.goal {
                    HStack(spacing: 4) { Image(systemName: "target").font(.caption2); Text(goal.title).font(.caption2) }.foregroundColor(.pink.opacity(0.8)).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.white.opacity(0.12)))
            }
        }
    }
    
    // REMOVED: taskActionButtons moved to mainContent
    
    private var cardBackground: some View {
            let useGlassmorphism = theme.id == "light" || theme.id == "dark"
            // Reduced corner radius (from 16 to 8)
            let cornerRadius: CGFloat = 8
            return ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(useGlassmorphism ? theme.glassBackground : task.category.color().opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(useGlassmorphism ? theme.glassBorder : task.category.color().opacity(0.6), lineWidth: theme.cardBorderWidth))
            }
        }
        
        // REMOVED: Old reflection implementation
        // @ViewBuilder private var goalReflectionPulse: some View { if task.goalID != nil && !task.isComplete { GoalReflectionPulseView() } }
        @ViewBuilder private var lockIconOverlay: some View { if task.isLocked { Image(systemName: "lock.fill").font(.caption).foregroundColor(.white).padding(6).background(Circle().fill(Color.black.opacity(0.7))).offset(x: 60, y: -60) } }
        @ViewBuilder private var reflectionSheetContent: some View { if let task = showingReflectionPrompt, let goal = task.goal { GoalReflectionView(goalID: goal.id, milestoneID: task.milestone?.id, taskID: task.id, goalTitle: goal.title) } }
        
        // Mini Progress Ring Helper
        @ViewBuilder private func miniProgressRing() -> some View {
        ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 3).frame(width: 20, height: 20)
                Circle().trim(from: 0, to: 0.5).stroke(.green, style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 20, height: 20)
            }
        }
    
    private var priorityColor: Color {
            switch task.priority { case .urgent: return .red; case .high: return .orange; case .normal: return .green; case .low: return .blue }
        }
        private var timeRangeText: String { Calendar.current.isDate(task.startTime, inSameDayAs: task.endTime) ? "\(TaskCardView.formatTime(task.startTime)) - \(TaskCardView.formatTime(task.endTime))" : "Multi-day" }
        private var completionIcon: String { task.isComplete ? "checkmark.square.fill" : "square" }
        private var completionColor: Color { task.isComplete ? .green : theme.textSecondary }
        private static func formatTime(_ date: Date) -> String { let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date) }
    
        private func handleTaskCompletion() {
            // Simple toggle for now
                task.isComplete.toggle()
            if task.isComplete { onTaskCompleted?(task.id) }
                    try? modelContext.save()
        }
        
    private func syncUserStatsToFirestore(user: User) {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else { return }
        // Note: This function is now in ViewModel - use vm.syncUserStatsToFirestore(user: user) instead
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
                                Circle().fill(colorFromString(color)).frame(width: 24, height: 24)
                                Text(color.capitalized).foregroundColor(.primary)
                            Spacer()
                            if color == taskBlock.color { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                    }
                }
            }
            .navigationTitle("Change Block Color")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } }
                }
            }
    private func colorFromString(_ colorString: String) -> Color {
            switch colorString { case "red": return .red; case "orange": return .orange; case "yellow": return .yellow; case "green": return .green; case "blue": return .blue; case "purple": return .purple; case "pink": return .pink; case "mint": return .mint; case "cyan": return .cyan; case "indigo": return .indigo; case "brown": return .brown; default: return .blue }
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
                        Button(action: { onCategoryChanged(category) }) {
                        HStack {
                                Image(systemName: category.icon).foregroundColor(category.color()).frame(width: 30)
                                Text(category.displayName).foregroundColor(.primary)
                            Spacer()
                                if task.category == category { Image(systemName: "checkmark").foregroundColor(.blue) }
                            }
                    }
                }
            }
            .navigationTitle("Change Category")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } }
            }
        }
    }

    // MARK: - Helper Functions
    private func priorityColor(for priority: PriorityType) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    // MARK: - Calendar Move Views
    struct MoveTaskCalendarView: View {
        let task: Task; let onDateSelected: (Date) -> Void; let onCancel: () -> Void; @State private var targetDate: Date
        init(task: Task, onDateSelected: @escaping (Date) -> Void, onCancel: @escaping () -> Void) { self.task = task; self.onDateSelected = onDateSelected; self.onCancel = onCancel; self._targetDate = State(initialValue: task.startTime) }
        var body: some View { NavigationView { MonthCalendarView(selectedDate: Binding(get: { targetDate }, set: { targetDate = $0; onDateSelected($0) })).navigationTitle("Move Task").toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } } } }
    }

    struct MoveTaskBlockCalendarView: View {
        let taskBlock: [Task]; let onDateSelected: (Date) -> Void; let onCancel: () -> Void; @State private var targetDate: Date
        init(taskBlock: [Task], onDateSelected: @escaping (Date) -> Void, onCancel: @escaping () -> Void) { self.taskBlock = taskBlock; self.onDateSelected = onDateSelected; self.onCancel = onCancel; self._targetDate = State(initialValue: taskBlock.first?.startTime ?? Date()) }
        var body: some View { NavigationView { MonthCalendarView(selectedDate: Binding(get: { targetDate }, set: { targetDate = $0; onDateSelected($0) })).navigationTitle("Move Task Block").toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } } } }
}

#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}
