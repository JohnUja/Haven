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

// Freeze-investigation logging was intentionally disabled after the audit cleanup.
@inline(__always)
fileprivate func debugLog(location: String, message: String, data: [String: Any] = [:], hypothesisId: String = "") {}

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager
    
    // MARK: - Data Queries
    // OPTIMIZED: Added fetch limits to prevent loading all records
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
    // REMOVED: showingDayPickerInPlan - calendar button now uses same system as Move Task
    @State private var showingCompletionRingPopup = false
    @State private var showingProgressDetails = false
    @State private var showingRecents = false
    @State private var viewMode: HomeViewMode = .tasks
    @State private var quickTaskTitle = ""
    @State private var quickTaskPriority: PriorityType = .normal
    @State private var quickTaskCategory: TaskCategory = .personal
    @State private var isQuickTaskComposerExpanded = false
    
    // Debounce date changes to prevent hangs during rapid scrolling (same as TimelineView)
    @State private var pendingDateChange: Date? = nil
    @State private var dateChangeTask: _Concurrency.Task<Void, Never>? = nil
    
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
    private func taskCardView(task: Task, theme: any AppTheme, isInPlanView: Bool = false) -> some View {
        TaskCardView(
            task: task,
            theme: theme,
            onTaskCompleted: vm.handleTaskCompleted,
            onEditTask: { task in
                if isInPlanView {
                    vm.showingEditTask = task
                } else {
                    vm.showingFloatingMenu = task
                }
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
            },
            isInPlanView: isInPlanView
        )
    }

    private func createQuickTask() {
        guard let user = currentUser else { return }

        let trimmedTitle = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let startTime = defaultQuickTaskStartTime(for: vm.selectedDate)
        let endTime = startTime.addingTimeInterval(3600)

        let task = Task(
            userID: user.id,
            title: trimmedTitle,
            startTime: startTime,
            endTime: endTime,
            priority: quickTaskPriority,
            category: quickTaskCategory
        )

        modelContext.insert(task)
        try? modelContext.save()
        quickTaskTitle = ""
        updateViewModel()
    }

    private func defaultQuickTaskStartTime(for selectedDate: Date) -> Date {
        let calendar = Calendar.current
        let baseDate = calendar.isDateInToday(selectedDate) ? Date() : selectedDate

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: baseDate)
        let minute = components.minute ?? 0
        let roundedMinute = minute <= 30 ? 30 : 0
        components.minute = roundedMinute
        if roundedMinute == 0 {
            components.hour = (components.hour ?? 8) + 1
        }

        if !calendar.isDateInToday(selectedDate) {
            components.hour = 9
            components.minute = 0
        }

        return calendar.date(from: components) ?? baseDate
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
        
        return NavigationStack { rootContent(theme: theme) }
            .onAppear {
                updateViewModel()
            }
            .onChange(of: users) { _, _ in
                // Move state modification outside view update cycle
                _Concurrency.Task { @MainActor in
                    updateViewModel()
                }
            }
            .onChange(of: routines) { _, _ in
                // Move state modification outside view update cycle
                _Concurrency.Task { @MainActor in
                    updateViewModel()
                }
            }
            .onChange(of: vm.selectedDate) { _, _ in
                // Move state modification outside view update cycle
                _Concurrency.Task { @MainActor in
                vm.onSelectedDateChanged()
                }
            }
            .sheet(isPresented: $vm.showingAddTask) {
                AddTaskView(selectedDate: vm.selectedDate)
                    .environment(themeManager)
                    .environment(authService)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $vm.showingCalendar) {
                themeCalendarView(theme: theme)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $vm.showingAddBlock) {
                AddBlockView(selectedDate: vm.selectedDate)
                    .presentationDetents([.medium])
                    .environment(themeManager)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(item: $vm.showingEditTask) { task in
                // OPTIMIZED: EditTaskView uses @Query internally, no need to fetch here
                // The allTasks parameter is optional and EditTaskView will use @Query if not provided
                EditTaskView(task: task, allTasks: nil)
                    .environment(themeManager)
                    .environmentObject(timeSettings)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(item: $vm.showingCategoryChange) { task in
                CategoryChangeView(task: task, onCategoryChanged: { [modelContext] newCategory in
                    // FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
                    task.category = newCategory
                    _Concurrency.Task { @MainActor in
                    try? modelContext.save()
                    }
                    vm.showingCategoryChange = nil
                }, onCancel: {
                    vm.showingCategoryChange = nil
                })
                .presentationDetents([.medium])
                .environment(\.modelContext, modelContext)
            }
            .sheet(item: $vm.showingMoveToDay) { task in
                MoveTaskCalendarView(task: task, onDateSelected: { date in
                    vm.moveTaskToDay(task, to: date)
                    vm.showingMoveToDay = nil
                }, onCancel: {
                    vm.showingMoveToDay = nil
                })
                .presentationDetents([.medium])
                .presentationBackground(.clear)
                .environment(\.modelContext, modelContext)
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
                    .presentationBackground(.clear)
                    .environment(\.modelContext, modelContext)
                }
            }
            .sheet(isPresented: Binding(
                get: { vm.showingEditBlock != nil },
                set: { if !$0 { vm.showingEditBlock = nil } }
            )) {
                if let editBlock = vm.showingEditBlock {
                    // CRITICAL FIX: modelContext.fetch must happen on MainActor
                    // This is safe because we're in a View body which runs on MainActor
                    let allTasks: [Task] = {
                        let descriptor = FetchDescriptor<Task>()
                        return (try? modelContext.fetch(descriptor)) ?? []
                    }()
                    EditBlockView(
                        taskBlock: editBlock.taskBlock,
                        tasksInBlock: editBlock.tasks,
                        allTasks: allTasks
                    )
                    .environment(themeManager)
                    .environmentObject(timeSettings)
                    .environment(\.modelContext, modelContext)
                }
            }
            .sheet(item: $vm.showingBlockColorPicker) { block in
                BlockColorPickerView(taskBlock: block, onSelected: { [modelContext] newColor in
                    // CRITICAL FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
                    block.color = newColor
                    _Concurrency.Task { @MainActor in
                    try? modelContext.save()
                    }
                    vm.showingBlockColorPicker = nil
                }, onCancel: {
                    vm.showingBlockColorPicker = nil
                })
                .presentationDetents([.medium])
                .environment(\.modelContext, modelContext)
            }
            .sheet(item: $vm.showingEditGoal) { goal in
                EditGoalInlineView(goal: goal)
                    .environment(themeManager)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(item: $vm.showingAddTaskToGoal) { goal in
                AddTaskToGoalView(goal: goal)
                    .environment(themeManager)
                    .environment(authService)
                    .environment(\.modelContext, modelContext)
            }
            // LinkTaskToGoalView can be implemented later if needed
            .sheet(item: $vm.selectedGoal) { goal in
                NavigationStack {
                    GoalsDetailView(goal: goal)
                }
                .environment(themeManager)
                .environment(\.modelContext, modelContext)
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
                        // CRITICAL FIX: Ensure modelContext operations happen on MainActor
                        modelContext.delete(goal)
                        _Concurrency.Task { @MainActor in
                        try? modelContext.save()
                        }
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
                        // CRITICAL FIX: Ensure modelContext operations happen on MainActor
                        goal.status = goal.status == .paused ? .active : .paused
                        _Concurrency.Task { @MainActor in
                        try? modelContext.save()
                        }
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
                    // LevelUpView doesn't need environment objects, but adding for consistency
                }
            }
            .fullScreenCover(isPresented: $vm.showingImmersiveWorkingOn) {
                if let currentTask = getCurrentTask() {
                    ImmersiveWorkingOnView(task: currentTask) {
                        vm.showingImmersiveWorkingOn = false
                    }
                    .environment(themeManager)
                    .environment(authService)
                    .environment(\.modelContext, modelContext)
                }
            }
            .overlay(floatingMenusOverlay)
            .overlay(dailySummaryOverlay)
            .overlay(undoMoveOverlay)
            .overlay(completionRingOverlay)
            .onAppear {
                updateViewModel()
                
                // Restore saved date state for sync with timeline
                if let savedDate = DatePersistenceService.shared.restoreSelectedDate() {
                    vm.selectedDate = savedDate
                    calendarManager.loadCalendarEvents(for: savedDate)
                }
                
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
            .onChange(of: vm.selectedDate) { _, _ in
                // Move state modification outside view update cycle
                _Concurrency.Task { @MainActor in
                vm.refreshSelectedDateData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingTaskCreated"))) { _ in
                // Refresh data when task is created
                vm.refreshSelectedDateData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Refresh data when SwiftData context saves (task/block created/updated/deleted)
                vm.refreshSelectedDateData()
            }
            .onDisappear {
                // Cancel any pending date change tasks to prevent hangs
                dateChangeTask?.cancel()
                dateChangeTask = nil
                pendingDateChange = nil
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
                    // Top Row: DEC 2025 button (left) and Action buttons (right) - animated
                    let isSelectedDateToday = Calendar.current.isDateInToday(vm.selectedDate)
                    
            HStack {
                        // DEC 2025 Calendar Button - left side
                    Button(action: {
                            vm.showingCalendar = true
                        }) {
                            Text(monthYearString(from: vm.selectedDate).uppercased())
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
                        
                        // Action buttons on right: Add Task icon, Add Block icon, Today button (when not today)
                        HStack(spacing: 8) {
                            // Add Task icon button - smaller size
                            Button(action: {
                                vm.showingAddTask = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 28, height: 28)
                            }
                            
                            // Add Block icon button - smaller size
                    Button(action: {
                        vm.showingAddBlock = true
                    }) {
                            Image(systemName: "square.stack.fill")
                                    .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                                    .frame(width: 28, height: 28)
                            }
                            
                            // Today Button - slides in from right when not on today
                            if !isSelectedDateToday {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        vm.selectedDate = Date()
                                        DatePersistenceService.shared.saveSelectedDate(vm.selectedDate)
                                        calendarManager.loadCalendarEvents(for: vm.selectedDate)
                                    }
                                }) {
                                    Text("Today")
                                        .font(.system(size: 12, weight: .bold))
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
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                                    removal: .move(edge: .trailing).combined(with: .opacity).animation(.spring(response: 0.25, dampingFraction: 0.8))
                                ))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelectedDateToday)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // ONLY InfiniteDaySelector (daily scroller) - synced with TimelineView
                    InfiniteDaySelector(
                        selectedDate: Binding(
                            get: { vm.selectedDate },
                            set: { newDate in
                                // Update immediately for UI responsiveness
                                vm.selectedDate = newDate
                                
                                // Debounce date changes to prevent hangs during rapid scrolling
                                pendingDateChange = newDate
                                
                                // Cancel previous task
                                dateChangeTask?.cancel()
                                
                                // Create new task with delay
                                dateChangeTask = _Concurrency.Task { @MainActor in
                                    try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
                                    
                                    // Check if this is still the pending date (not cancelled)
                                    if let pending = pendingDateChange, Calendar.current.isDate(pending, inSameDayAs: newDate) {
                                        // Persist selected date for state preservation
                                        DatePersistenceService.shared.saveSelectedDate(pending)
                                        calendarManager.loadCalendarEvents(for: pending)
                                        pendingDateChange = nil
                                    }
                                }
                            }
                        ),
                        onDateChanged: { newDate in
                            // ViewModel handles date change internally via didSet
                        },
                        hasEvents: { date in
                            // Optimize: Use cached check instead of heavy computation
                            calendarManager.hasEventsOnDate(date)
                        },
                        showMonthHeader: true
                    )
            .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // Plan vs Focus Toggle
                    modeToggleView
                        .padding(.horizontal, 20)
                    
                    // REMOVED: Date, Time Crystals, and Progression Ring section - now handled by tappable green circle in daily scroller
                    
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
                    onUnlock: { 
                        vm.showingFloatingMenu = nil
                        task.isLocked.toggle()
                        // CRITICAL FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
                        _Concurrency.Task { @MainActor in
                            try? modelContext.save()
                        }
                    },
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
                            // CRITICAL FIX: Ensure modelContext.save() happens on MainActor
                            _Concurrency.Task { @MainActor in
                            try? modelContext.save()
                            }
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
                        LinearGradient(colors: [theme.successColor, theme.successColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
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
            // REMOVED: Agenda Area - completely removed per user request
            
            Spacer() // Push content down
            
            // Dynamic Focus Box - moved lower
            VStack(spacing: 0) {
                DynamicFocusBox(
                    selectedDate: vm.selectedDate,
                    allTasks: selectedDateTasks,
                    allTaskBlocks: selectedDateTaskBlocks,
                    previewTask: $vm.previewTaskForDynamicBox,
                    isViewAllTasksMode: $vm.isViewAllTasksMode,
                    onAddTask: {
                        vm.showingAddTask = true
                    },
                    onEditTask: { task in
                        vm.showingEditTask = task
                    },
                    onDeleteTask: { task in
                        deleteTask(task)
                        vm.refreshSelectedDateData()
                    }
                )
                .padding(.horizontal, 20)
                
                // Add Task and Add Task Block buttons - below dynamic box (same size as Add Reflection)
                HStack(spacing: 12) {
                    Button(action: {
                        vm.showingAddTask = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Task")
                                .font(theme.headerFont) // Use same font as focus/plan tabs (11pt, semibold)
                        }
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16) // Same as Add Reflection (swapped)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                    }
                    
                    Button(action: {
                        vm.showingAddBlock = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 16))
                            Text("Add Block")
                                .font(theme.headerFont) // Use same font as focus/plan tabs (11pt, semibold)
                        }
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16) // Same as Add Reflection (swapped)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
                // Add Daily Journal / Reflection box - bigger (same size as old Add Task/Block)
                Button(action: {
                    // TODO: Implement reflection/journal entry
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                        Text("Add Daily Reflection")
                            .font(theme.headerFont) // Use same font as focus/plan tabs (11pt, semibold)
                    }
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20) // Increased from 16 to match old Add Task/Block size
                    .background(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .fill(theme.glassBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
            }
            .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Plan View Content
    private func planViewContent(theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
            // Filter Button - Only show "ALL TASKS"
                HStack {
                    Text("ALL TASKS")
                    .font(theme.headerFont)
                    .foregroundColor(theme.textPrimary)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: Show filter modal
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                        .font(theme.headerFont)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .padding(.horizontal, theme.sectionPadding)

            quickTaskComposer(theme: theme)
                .padding(.horizontal, 20)
                
            // Simple Chronological Task List (not grouped masterTaskListView)
            simpleChronologicalTaskListView(theme: theme)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Plan Item Helper (for unified task/block ordering)
    private struct PlanItem: Identifiable {
        let id: String
        let startTime: Date
        let isComplete: Bool
        let isBlock: Bool
    }
    
    // MARK: - Helper: Get Sorted Plan Items (tasks and blocks unified, time-sensitive order)
    // OPTIMIZED: Now uses ViewModel's cached filtered tasks
    private func getSortedPlanItems() -> ([PlanItem], [String: [Task]]) {
        // #region agent log
        let funcStartTime = Date()
        debugLog(location: "HomeDashboardView:getSortedPlanItems", message: "getSortedPlanItems started", data: [:], hypothesisId: "D")
        // #endregion
        
        let filteredTasks = vm.getFilteredTasks()
        
        // #region agent log
        debugLog(location: "HomeDashboardView:getSortedPlanItems", message: "Filtered tasks retrieved", data: ["filteredTasksCount": filteredTasks.count] as [String: Any], hypothesisId: "D")
        // #endregion
        
        // Get all items with their start times
        var allItems: [PlanItem] = []
        
        // Add standalone tasks
        let standaloneTasks = filteredTasks.filter { $0.taskBlock == nil }
        for task in standaloneTasks {
            allItems.append(PlanItem(
                id: task.id,
                startTime: task.startTime,
                isComplete: task.isComplete,
                isBlock: false
            ))
        }
        
        // Add task blocks (use earliest task start time in block)
        let tasksByBlock = Dictionary(grouping: filteredTasks) { $0.taskBlock?.id ?? "" }
        let taskBlocks = tasksByBlock.filter { $0.key != "" }
        for (blockID, blockTasks) in taskBlocks {
            if let firstTask = blockTasks.sorted(by: { $0.startTime < $1.startTime }).first {
                allItems.append(PlanItem(
                    id: blockID,
                    startTime: firstTask.startTime,
                    isComplete: blockTasks.allSatisfy { $0.isComplete },
                    isBlock: true
                ))
            }
        }
        
        // Sort by time-sensitive: incomplete first, then by start time (most approaching at top)
        // #region agent log
        let sortStartTime = Date()
        debugLog(location: "HomeDashboardView:getSortedPlanItems", message: "Starting sort operation", data: ["allItemsCount": allItems.count] as [String: Any], hypothesisId: "D")
        // #endregion
        
        let sortedItems = allItems.sorted { item1, item2 in
            // Incomplete items first
            if item1.isComplete != item2.isComplete {
                return !item1.isComplete
            }
            // Then by start time (earliest/most approaching at top)
            return item1.startTime < item2.startTime
        }
        
        // #region agent log
        let sortDuration = Date().timeIntervalSince(sortStartTime)
        debugLog(location: "HomeDashboardView:getSortedPlanItems", message: "Sort completed", data: ["sortedItemsCount": sortedItems.count, "duration": sortDuration] as [String: Any], hypothesisId: "D")
        // #endregion
        
        // #region agent log
        let totalDuration = Date().timeIntervalSince(funcStartTime)
        debugLog(location: "HomeDashboardView:getSortedPlanItems", message: "getSortedPlanItems completed", data: ["totalDuration": totalDuration] as [String: Any], hypothesisId: "D")
        // #endregion
        
        return (sortedItems, tasksByBlock)
    }
    
    // MARK: - Simple Chronological Task List (for Plan tab)
    @ViewBuilder
    private func simpleChronologicalTaskListView(theme: any AppTheme) -> some View {
        // Get sorted items and task blocks mapping (logic moved outside ViewBuilder)
        let (sortedItems, tasksByBlock) = getSortedPlanItems()
        let standaloneTasks = vm.getFilteredTasks().filter { $0.taskBlock == nil }
        
        if sortedItems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                
                Text("No tasks for today")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("Create your first task to get started")
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    vm.showingAddTask = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Task")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .fill(theme.glassBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Display items in unified order (tasks and blocks together)
                ForEach(sortedItems) { item in
                    if item.isBlock {
                        // Display task block
                        if let blockTasks = tasksByBlock[item.id], !blockTasks.isEmpty,
                           let taskBlock = vm.getTaskBlock(for: item.id) {
                            taskBlockCardView(tasks: blockTasks, taskBlock: taskBlock, theme: theme)
                                .padding(.horizontal, 20)
                        }
                    } else {
                        // Display standalone task
                        if let task = standaloneTasks.first(where: { $0.id == item.id }) {
                            taskCardView(task: task, theme: theme, isInPlanView: true)
                                .padding(.horizontal, 20)
                                .id(task.id)
                        }
                    }
                }
            }
        }
    }

    private func quickTaskComposer(theme: any AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isQuickTaskComposerExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                    
                    Text(isQuickTaskComposerExpanded ? "Hide Quick Add" : "Quick Add")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Text("1 hr default")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                    
                    Image(systemName: isQuickTaskComposerExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isQuickTaskComposerExpanded {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Add a task without opening the full editor", text: $quickTaskTitle)
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textPrimary)
                            .tint(theme.accentColor)

                        Button(action: createQuickTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        }
                        .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }

                    HStack(spacing: 10) {
                        Menu {
                            ForEach(PriorityType.allCases, id: \.self) { priority in
                                Button(priority.rawValue.capitalized) {
                                    quickTaskPriority = priority
                                }
                            }
                        } label: {
                            quickTaskPill(
                                label: quickTaskPriority.rawValue.capitalized,
                                color: colorForPriority(quickTaskPriority)
                            )
                        }

                        Menu {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                Button(category.displayName) {
                                    quickTaskCategory = category
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: quickTaskCategory.icon)
                                Text(quickTaskCategory.displayName)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(theme.glassBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                    )
                            )
                        }

                        Spacer()
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }

    private func quickTaskPill(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(themeManager.currentTheme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(themeManager.currentTheme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
    }

    private func colorForPriority(_ priority: PriorityType) -> Color {
        switch priority {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .normal:
            return .green
        case .low:
            return .blue
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
                    // CRITICAL FIX: Ensure modelContext.save() happens on MainActor
                    _Concurrency.Task { @MainActor in
                    try? modelContext.save()
                    }
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
                // #region agent log
                let toggleStartTime = Date()
                debugLog(location: "HomeDashboardView.swift:taskToggle", message: "Task toggle started", data: ["taskId": task.id, "taskTitle": task.title, "currentState": task.isComplete] as [String: Any], hypothesisId: "F")
                // #endregion
                
                // CRITICAL FIX: Ensure task has a valid id before saving (prevents SwiftData crash)
                if task.id.isEmpty {
                    // #region agent log
                    debugLog(location: "HomeDashboardView.swift:taskToggle", message: "Task ID was empty, generating new UUID", data: ["taskTitle": task.title] as [String: Any], hypothesisId: "F")
                    // #endregion
                    task.id = UUID().uuidString
                }
                
                let oldState = task.isComplete
                task.isComplete.toggle()
                let newState = task.isComplete
                
                // #region agent log
                debugLog(location: "HomeDashboardView.swift:taskToggle", message: "Task state toggled", data: ["taskId": task.id, "oldState": oldState, "newState": newState] as [String: Any], hypothesisId: "F")
                // #endregion
                
                // CRITICAL FIX: Ensure modelContext.save() happens on MainActor
                _Concurrency.Task { @MainActor in
                    // #region agent log
                    let saveStartTime = Date()
                    debugLog(location: "HomeDashboardView.swift:taskToggle", message: "Starting modelContext.save()", data: ["taskId": task.id] as [String: Any], hypothesisId: "F")
                    // #endregion
                    do {
                        try modelContext.save()
                        // #region agent log
                        let saveDuration = Date().timeIntervalSince(saveStartTime)
                        debugLog(location: "HomeDashboardView.swift:taskToggle", message: "modelContext.save() succeeded", data: ["taskId": task.id, "duration": saveDuration] as [String: Any], hypothesisId: "F")
                        // #endregion
                    } catch {
                        // #region agent log
                        let saveDuration = Date().timeIntervalSince(saveStartTime)
                        debugLog(location: "HomeDashboardView.swift:taskToggle", message: "modelContext.save() FAILED", data: ["taskId": task.id, "error": error.localizedDescription, "duration": saveDuration] as [String: Any], hypothesisId: "F")
                        // #endregion
                    }
                    // #region agent log
                    let toggleDuration = Date().timeIntervalSince(toggleStartTime)
                    debugLog(location: "HomeDashboardView.swift:taskToggle", message: "Task toggle completed", data: ["taskId": task.id, "totalDuration": toggleDuration] as [String: Any], hypothesisId: "F")
                    // #endregion
                }
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
    @ViewBuilder
    private func masterTaskListView(theme: any AppTheme) -> some View {
        let filteredTasks = vm.getFilteredTasks()
        
        if filteredTasks.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                
                Text("No tasks for today")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("Create your first task to get started")
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    vm.showingAddTask = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Task")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                            .fill(theme.glassBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        } else {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Dynamic sectioning based on filter
            let sections = groupTasksByFilter(filteredTasks)
            
            ForEach(sections.keys.sorted(), id: \.self) { sectionTitle in
                if let sectionTasks = sections[sectionTitle], !sectionTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(sectionTitle)
                            .appTextStyle(.sectionHeader, theme: theme)
                                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                        
                            // Group tasks by taskBlockID - show blocks as single cards
                            let tasksByBlock = Dictionary(grouping: sectionTasks) { $0.taskBlock?.id ?? "" }
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
                                taskCardView(task: task, theme: theme, isInPlanView: true) // Pass true for plan view
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
    }
    
    // MARK: - Task Block Card View (for Plan View)
    @ViewBuilder
    private func taskBlockCardView(tasks: [Task], taskBlock: TaskBlock, theme: any AppTheme) -> some View {
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        if let firstTask = sortedTasks.first, let lastTask = sortedTasks.last {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Square checkbox for block
                    Button(action: {
                        // #region agent log
                        let blockToggleStartTime = Date()
                        debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Task block toggle started", data: ["blockId": taskBlock.id, "blockTitle": taskBlock.title, "tasksCount": tasks.count] as [String: Any], hypothesisId: "F")
                        // #endregion
                        
                        let allComplete = tasks.allSatisfy { $0.isComplete }
                        // #region agent log
                        debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Block completion state", data: ["blockId": taskBlock.id, "allComplete": allComplete, "newState": !allComplete] as [String: Any], hypothesisId: "F")
                        // #endregion
                        
                        for task in tasks {
                            let oldState = task.isComplete
                            task.isComplete = !allComplete
                            // #region agent log
                            debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Task in block toggled", data: ["blockId": taskBlock.id, "taskId": task.id, "oldState": oldState, "newState": task.isComplete] as [String: Any], hypothesisId: "F")
                            // #endregion
                        }
                        
                        // CRITICAL FIX: Ensure modelContext.save() happens on MainActor
                        _Concurrency.Task { @MainActor in
                            // #region agent log
                            let saveStartTime = Date()
                            debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Starting block save", data: ["blockId": taskBlock.id, "tasksCount": tasks.count] as [String: Any], hypothesisId: "A")
                            // #endregion
                            do {
                                try modelContext.save()
                                // #region agent log
                                let saveDuration = Date().timeIntervalSince(saveStartTime)
                                debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Block save SUCCEEDED", data: ["blockId": taskBlock.id, "duration": saveDuration] as [String: Any], hypothesisId: "A")
                                // #endregion
                            } catch {
                                // #region agent log
                                let saveDuration = Date().timeIntervalSince(saveStartTime)
                                debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Block save FAILED", data: ["blockId": taskBlock.id, "error": error.localizedDescription, "duration": saveDuration] as [String: Any], hypothesisId: "A")
                                // #endregion
                            }
                            // #region agent log
                            let totalDuration = Date().timeIntervalSince(blockToggleStartTime)
                            debugLog(location: "HomeDashboardView:taskBlockToggle", message: "Task block toggle completed", data: ["blockId": taskBlock.id, "totalDuration": totalDuration] as [String: Any], hypothesisId: "F")
                            // #endregion
                        }
                    }) {
                        Image(systemName: tasks.allSatisfy { $0.isComplete } ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(tasks.allSatisfy { $0.isComplete } ? .green : theme.textPrimary.opacity(0.6))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Block title - use same size as "skincare" block (headerFont)
                        Text(taskBlock.title)
                            .font(theme.headerFont) // Same font as focus/plan tabs (11pt, semibold)
                            .foregroundColor(theme.textPrimary)
                            .strikethrough(tasks.allSatisfy { $0.isComplete })
                            .opacity(tasks.allSatisfy { $0.isComplete } ? 0.6 : 1.0)
                        
                        // Time span display (3PM-4PM) in BOLD all caps - use same size as "skincare" block
                        Text(formatTimeRange(from: firstTask.startTime, to: lastTask.endTime))
                            .font(theme.headerFont) // Use same font as "skincare" block
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
                    
                    // Category icon on right - NO circle/round outline, just icon (plain, no color)
                    Image(systemName: firstTask.category.icon)
                        .font(.title3)
                        .foregroundColor(theme.textPrimary.opacity(0.6)) // Plain, no category color
                        .frame(width: 24, height: 24)
                }
                .padding(16)
                .frame(maxWidth: .infinity) // Make task blocks wider/stretched
                .background(
                    // Plain white/transparent background (no colors) - like "skincare" block
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .fill(theme.glassBackground.opacity(0.5)) // Plain, no category colors
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
        }
    }
    
    // MARK: - Helper Functions for Plan View
    private func formatTimeRange(from startTime: Date, to endTime: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTimeStr = timeFormatter.string(from: startTime).uppercased()
        let endTimeStr = timeFormatter.string(from: endTime).uppercased()
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    // OPTIMIZED: Removed - now using ViewModel's getFilteredTasks() which is cached
    // This function was causing main thread blocking with multiple filters/sorts per render
    
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
    // OPTIMIZED: Use ViewModel's cached tasks instead of filtering on every render
    private func completionRingPopupView(theme: any AppTheme) -> some View {
        let tasks = vm.selectedDateTasks // Already filtered and cached
        let completedCount = tasks.filter { $0.isComplete }.count
        let totalCount = tasks.count
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
            // Left: Month/Year (NOV 2025) - Calendar Dropdown (Top Left) - THEME-CONTROLLED
            // Connected to same calendar system as Move Task long-press menu
            Button(action: {
                // Opens the same calendar modal used by Move Task
                vm.showingCalendar = true
            }) {
                Text(monthYearString(from: vm.selectedDate))
                    .font(theme.headerFont) // Use theme headerFont for consistency
                    .foregroundColor(theme.textPrimary) // Full opacity for visibility on light mode
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.glassBackground.opacity(0.5)) // Increased opacity for better visibility
                            .overlay(
                                Capsule()
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Center section - Time crystals BEFORE level ring (menu)
            HStack(spacing: 16) {
                if let user = currentUser {
                    // Time crystals first
                        CrystalCounterView(currentCrystals: user.gamificationCurrency)
                    
                    // Level ring as menu (tap to show details)
                    Menu {
                        // Level details content
                        if let user = currentUser {
                            levelRingMenuContent(user: user, theme: theme)
                        }
                    } label: {
                        completionRingView(theme: theme)
                    }
                    
                    CompactMomentumView(momentumDays: user.momentumDays)
                } else {
                    completionRingView(theme: theme)
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
    
    // MARK: - Theme-Controlled Calendar View
    @ViewBuilder
    private func themeCalendarView(theme: any AppTheme) -> some View {
        // Simple sheet with cohesive background - no NavigationView header
        VStack(spacing: 0) {
            // Month/Year navigation and calendar
            MonthCalendarView(selectedDate: Binding(
                get: { vm.selectedDate },
                set: { newDate in
                    vm.selectedDate = newDate
                    DatePersistenceService.shared.saveSelectedDate(newDate)
                    calendarManager.loadCalendarEvents(for: newDate)
                    let calendar = Calendar.current
                    if calendar.dateComponents([.day], from: Date(), to: newDate).day ?? 0 > 0 {
                        DatePersistenceService.shared.saveLastWorkedDate(newDate)
                    }
                }
            ))
            
            // Bottom buttons
            HStack(spacing: 12) {
                Button("Today") {
                    withAnimation {
                        vm.selectedDate = Date()
                        DatePersistenceService.shared.saveSelectedDate(Date())
                        vm.showingCalendar = false
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .fill(Color.white.opacity(0.2))
                                )
                
                Spacer()
                
                Button("Done") {
                    vm.showingCalendar = false
                }
                            .foregroundColor(.white)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .fill(theme.accentColor)
                )
            }
            .padding()
        }
        .background(theme.primaryGradient.ignoresSafeArea())
    }
    
    // MARK: - Helper: Month Year String
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Completion Ring
    private func completionRingView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return ZStack {
            Circle().stroke(theme.glassBorder.opacity(0.3), lineWidth: 2).frame(width: 32, height: 32)
                        Circle().trim(from: 0, to: CGFloat(progress))
                            .stroke(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
            Circle().fill(theme.textPrimary.opacity(0.3)).frame(width: 4, height: 4)
        }
        .frame(width: 32, height: 32)
    }
    
    // MARK: - Level Ring Menu Content
    @ViewBuilder
    private func levelRingMenuContent(user: User, theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        let xpProgress = LevelService.calculateProgress(user: user)
        let currentLevelXP = LevelService.xpForLevel(user.level)
        let nextLevelXP = LevelService.xpForLevel(user.level + 1)
        let xpInCurrentLevel = user.currentXP - currentLevelXP
        let xpNeeded = nextLevelXP - currentLevelXP
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(theme.headerFont)
                .foregroundColor(theme.textPrimary)
            
            // Daily Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("Today: \(completedCount)/\(totalCount) tasks")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 10, weight: .regular, design: .default)) // Use small font instead of captionFont
                    .foregroundColor(theme.textSecondary.opacity(0.7))
            }
            
            Divider()
            
            // Level Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(user.level)")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                Text("\(xpInCurrentLevel)/\(xpNeeded) XP to next level")
                    .font(.system(size: 10, weight: .regular, design: .default)) // Use small font instead of captionFont
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        }
    
    // MARK: - Calendar Modal View - REMOVED (will be reimplemented with theme)
    // MARK: - Date and Progress Section (Before Focus/Plan tabs)
    private func dateAndProgressSection(user: User, theme: any AppTheme) -> some View {
        HStack(spacing: 16) {
            // Date display (e.g., "Wednesday, October 21")
            Text(dateString(for: vm.selectedDate))
                .font(theme.titleFont)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            // Time crystals
            CrystalCounterView(currentCrystals: user.gamificationCurrency)
            
            // Progression ring with level in center (as menu)
            Menu {
                levelRingMenuContent(user: user, theme: theme)
            } label: {
                progressionRingView(user: user, theme: theme)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Progression Ring View (with level in center)
    private func progressionRingView(user: User, theme: any AppTheme) -> some View {
        let xpProgress = LevelService.calculateProgress(user: user)
        
        return ZStack {
            // Background ring
            Circle()
                .stroke(theme.glassBorder.opacity(0.3), lineWidth: 4)
                .frame(width: 50, height: 50)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(xpProgress))
                .stroke(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: xpProgress)
            
            // Level in center
            Text("\(user.level)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
        }
        .frame(width: 50, height: 50)
    }
    
    // MARK: - Helper Functions for Date Formatting
        private func timeString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        private func dateString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }

        private func deleteTask(_ task: Task) {
            // CRITICAL FIX: Ensure modelContext operations happen on MainActor
            modelContext.delete(task)
            _Concurrency.Task { @MainActor in
            try? modelContext.save()
            }
        }

        // MARK: - Missing Helper Functions (Stubbed for compilation)
        // MARK: - Removed: checkAndShowDailySummary and isFromInactiveRoutine moved to ViewModel
        // Use vm.checkAndShowDailySummary() and vm.isFromInactiveRoutine(task) instead

    private func getCurrentTask() -> Task? {
        let now = Date()
        let calendar = Calendar.current
        return selectedDateTasks.first { task in
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
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8)).cornerRadius(10)
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
    var isInPlanView: Bool = false // Indicates if this card is in plan view
        
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingReflectionPrompt: Task? = nil
    @State private var showEarlyCompletionPrompt = false
    @State private var earlyCompletionTask: Task? = nil
    @State private var earlyCompletionRewards: (xp: Int, crystals: Int) = (0, 0)
    @State private var hasShownEarlyCompletionPrompt = false // Track if prompt shown this session
    @State private var showingDeleteAlert = false
    @State private var isInlineEditing = false
    @State private var editableTitle: String
    @State private var editablePriority: PriorityType
    @State private var editableCategory: TaskCategory
    @State private var editableStartTime: Date
    @State private var editableEndTime: Date
    
    init(
        task: Task,
        theme: any AppTheme,
        onTaskCompleted: ((String) -> Void)?,
        onEditTask: ((Task) -> Void)?,
        onLevelUp: ((LevelUpResult) -> Void)?,
        dailyXPTotal: Binding<Int>,
        dailyCrystalsTotal: Binding<Int>,
        dailyBonuses: Binding<[String]>,
        onDailyTrackingUpdate: ((Int, Int, String?) -> Void)? = nil,
        isInPlanView: Bool = false
    ) {
        self.task = task
        self.theme = theme
        self.onTaskCompleted = onTaskCompleted
        self.onEditTask = onEditTask
        self.onLevelUp = onLevelUp
        self._dailyXPTotal = dailyXPTotal
        self._dailyCrystalsTotal = dailyCrystalsTotal
        self._dailyBonuses = dailyBonuses
        self.onDailyTrackingUpdate = onDailyTrackingUpdate
        self.isInPlanView = isInPlanView
        self._editableTitle = State(initialValue: task.title)
        self._editablePriority = State(initialValue: task.priority)
        self._editableCategory = State(initialValue: task.category)
        self._editableStartTime = State(initialValue: task.startTime)
        self._editableEndTime = State(initialValue: task.endTime)
    }
    
    var body: some View {
        mainContent
            .padding(16)
            .background(cardBackground)
            .opacity(task.isComplete ? 0.7 : 1.0)
            // REMOVED: Blur effect on completed tasks - keep stroke only
            // Animation will be handled by delayed transition to bottom
            // REMOVED: Old reflection overlay
            // .overlay(goalReflectionPulse, alignment: .trailing)
            .overlay(lockIconOverlay, alignment: .topTrailing)
            .onChange(of: task.isComplete) { oldValue, newValue in
                // FIX: Move state modification outside view update cycle
                // When task becomes complete, wait a few seconds then trigger reorder
                if newValue && !oldValue {
                    // Use fully qualified Task type to avoid conflict with SwiftData Task model
                    _Concurrency.Task { @MainActor in
                        try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        // Trigger view update to reorder tasks
                        // The parent view will handle the reordering via getFilteredTasks()
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.3) { // Lighter, more sensitive (reduced from default)
                guard !isInPlanView else { return }
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
            .onTapGesture {
                guard isInPlanView else { return }
                if !isInlineEditing {
                    beginInlineEditing()
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .sheet(isPresented: Binding(
                get: { showingReflectionPrompt != nil },
                set: { if !$0 { showingReflectionPrompt = nil } }
            )) {
                reflectionSheetContent
            }
            .alert("Delete Task?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove \"\(task.title)\" from your schedule.")
            }
            .alert("Completed \(earlyCompletionTask?.title ?? "task") already?", isPresented: $showEarlyCompletionPrompt) {
                Button("Cancel", role: .cancel) {
                    // Reset state so prompt can show again if user tries again
                    earlyCompletionTask = nil
                    showEarlyCompletionPrompt = false
                    hasShownEarlyCompletionPrompt = false // Allow prompt to show again
                }
                Button("Complete Anyway") {
                    guard let task = earlyCompletionTask else { return }
                    // Force complete with rewards
                    _Concurrency.Task { @MainActor in
                        task.isComplete = true
                        onTaskCompleted?(task.id)
                        try? modelContext.save()
                        earlyCompletionTask = nil
                        showEarlyCompletionPrompt = false
                        hasShownEarlyCompletionPrompt = false // Reset for next time
                    }
                }
            } message: {
                if let task = earlyCompletionTask {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This task starts at \(formatTime(task.startTime)).")
                            .font(theme.bodyFont)
                        Text("Rewards for completing:")
                            .font(theme.bodyFont)
                        Text("⭐ \(earlyCompletionRewards.xp) XP")
                            .font(theme.bodyFont)
                        Text("💎 \(earlyCompletionRewards.crystals) Crystals")
                            .font(theme.bodyFont)
                    }
                }
            }
    }
    
    private var mainContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: Checkbox at center left (same size as task blocks)
            Button(action: { handleTaskCompletion() }) {
                Image(systemName: task.isComplete ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium)) // Same size as task blocks
                    .foregroundColor(task.isComplete ? completionColor : theme.textSecondary)
            }
            
            taskContent
            
            Spacer()
            
            // Right side: Category icon and time
            VStack(alignment: .trailing, spacing: 4) {
                if isInlineEditing && isInPlanView {
                    Menu {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                editableCategory = category
                            }
                        }
                    } label: {
                        Image(systemName: editableCategory.icon)
                            .font(.title3)
                            .foregroundColor(editableCategory.color())
                            .frame(width: 24, height: 24)
                    }
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        DatePicker("", selection: $editableStartTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .tint(theme.accentColor)
                        DatePicker("", selection: $editableEndTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .tint(theme.accentColor)
                    }
                    .scaleEffect(0.92, anchor: .trailing)
                } else {
                    Image(systemName: task.category.icon)
                        .font(.title3)
                        .foregroundColor(task.category.color())
                        .frame(width: 24, height: 24)
                    
                    Text(timeSpanText)
                        .font(theme.bodyFont)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(theme.textPrimary.opacity(0.8))
                        .opacity(task.isComplete ? 0.6 : 1.0)
                }
            }
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
        VStack(alignment: .leading, spacing: 6) {
            if isInlineEditing && isInPlanView {
                TextField("Task title", text: $editableTitle)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(theme.textPrimary)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit {
                        saveInlineChanges()
                    }
                
                HStack(spacing: 8) {
                    Menu {
                        ForEach(PriorityType.allCases, id: \.self) { priority in
                            Button(priority.rawValue.capitalized) {
                                editablePriority = priority
                            }
                        }
                    } label: {
                        inlineEditPill(
                            label: editablePriority.rawValue.capitalized,
                            color: inlinePriorityColor(editablePriority)
                        )
                    }
                    
                    Text(timeSpanTextFor(editableStartTime, editableEndTime))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    Button("Done") {
                        saveInlineChanges()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.accentColor)
                }
            } else {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(theme.textPrimary)
                        .strikethrough(task.isComplete)
                        .opacity(task.isComplete ? theme.textTertiaryOpacity : 1.0)
                    if task.isRoutineTask { Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow) }
                }
                
                if task.goal != nil { goalMilestoneBadges }
                
                Text("Priority: \(task.priority.rawValue.capitalized)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(priorityColor)
                    .opacity(task.isComplete ? 0.6 : 1.0)
                if let description = task.taskDescription {
                    Text(description)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                        .opacity(task.isComplete ? 0.6 : 1.0)
                }
            }
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
        // Use empty fill (same as task blocks) for ALL tasks - NO category fill background
        // Use task block border radius (theme.cardCornerRadius) for tasks
        return RoundedRectangle(cornerRadius: theme.cardCornerRadius) // Use task block border radius
            .fill(theme.glassBackground.opacity(0.5)) // Same fill as task blocks
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
            )
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
    
    private func deleteTask() {
        modelContext.delete(task)
        _Concurrency.Task { @MainActor in
            try? modelContext.save()
        }
    }
    
    private func beginInlineEditing() {
        editableTitle = task.title
        editablePriority = task.priority
        editableCategory = task.category
        editableStartTime = task.startTime
        editableEndTime = task.endTime
        isInlineEditing = true
    }
    
    private func saveInlineChanges() {
        let trimmedTitle = editableTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard editableEndTime >= editableStartTime else {
            editableEndTime = editableStartTime.addingTimeInterval(3600)
            return
        }
        task.title = trimmedTitle
        task.priority = editablePriority
        task.category = editableCategory
        task.startTime = editableStartTime
        task.endTime = editableEndTime
        try? modelContext.save()
        isInlineEditing = false
    }
    
    private func inlineEditPill(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundColor(theme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    private func inlinePriorityColor(_ priority: PriorityType) -> Color {
        switch priority {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .normal:
            return .green
        case .low:
            return .blue
        }
    }
    
    private func timeSpanTextFor(_ start: Date, _ end: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTimeStr = timeFormatter.string(from: start).uppercased()
        let endTimeStr = timeFormatter.string(from: end).uppercased()
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
        private func handleTaskCompletion() {
            // #region agent log
            let completionStartTime = Date()
            debugLog(location: "TaskCardView:handleTaskCompletion", message: "handleTaskCompletion started", data: ["taskId": task.id, "taskTitle": task.title, "currentState": task.isComplete, "hasGoal": task.goal != nil] as [String: Any], hypothesisId: "F")
            // #endregion
            
            let calendar = Calendar.current
            let now = Date()
            let taskStart = task.startTime
            
            // If trying to complete a task that hasn't started yet
            if !task.isComplete && now < taskStart {
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Early completion detected, calculating rewards", data: ["taskId": task.id, "now": now.timeIntervalSince1970, "taskStart": taskStart.timeIntervalSince1970] as [String: Any], hypothesisId: "G")
                // #endregion
                
                // Always show prompt to provide accountability
                // Calculate potential rewards
                guard let user = users.first else {
                    // #region agent log
                    debugLog(location: "TaskCardView:handleTaskCompletion", message: "No user found, aborting", data: [:], hypothesisId: "F")
                    // #endregion
                    return
                }
                
                let goal = task.goal
                
                // #region agent log
                let momentumStartTime = Date()
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Calculating momentum bonus", data: ["userId": user.id, "momentumDays": user.momentumDays] as [String: Any], hypothesisId: "G")
                // #endregion
                let momentumBonus = GamificationService.getMomentumBonus(user: user)
                // #region agent log
                let momentumDuration = Date().timeIntervalSince(momentumStartTime)
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Momentum bonus calculated", data: ["momentumBonus": momentumBonus, "duration": momentumDuration] as [String: Any], hypothesisId: "G")
                // #endregion
                
                // #region agent log
                let rewardsStartTime = Date()
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Calculating task rewards", data: ["taskId": task.id, "hasGoal": goal != nil] as [String: Any], hypothesisId: "G")
                // #endregion
                let baseRewards = GamificationService.calculateTaskRewards(
                    task: task,
                    goal: goal,
                    momentumBonus: momentumBonus
                )
                // #region agent log
                let rewardsDuration = Date().timeIntervalSince(rewardsStartTime)
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Task rewards calculated", data: ["xp": baseRewards.xp, "crystals": baseRewards.crystals, "duration": rewardsDuration] as [String: Any], hypothesisId: "G")
                // #endregion
                
                // Store task and rewards for prompt
                earlyCompletionTask = task
                earlyCompletionRewards = (xp: baseRewards.xp, crystals: baseRewards.crystals)
                showEarlyCompletionPrompt = true
                hasShownEarlyCompletionPrompt = true // Track that we've shown it for this task
                
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Early completion prompt shown, returning", data: [:], hypothesisId: "F")
                // #endregion
                return // Don't complete yet - wait for user confirmation
            }
            
            // Normal completion - task has started or is being unchecked
            // #region agent log
            debugLog(location: "TaskCardView:handleTaskCompletion", message: "Normal completion path", data: ["taskId": task.id, "isUnchecking": task.isComplete] as [String: Any], hypothesisId: "F")
            // #endregion
            
            // CRITICAL FIX: Ensure task has a valid id before saving (prevents SwiftData crash)
            // Double-check: if ID is empty or nil, assign new UUID and verify it's set
            if task.id.isEmpty {
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Task ID was empty, generating new UUID", data: ["taskTitle": task.title] as [String: Any], hypothesisId: "F")
                // #endregion
                let newID = UUID().uuidString
                task.id = newID
                // Verify ID was actually set (defensive programming)
                guard !task.id.isEmpty else {
                    // #region agent log
                    debugLog(location: "TaskCardView:handleTaskCompletion", message: "ERROR: Failed to set task ID, aborting", data: [:], hypothesisId: "F")
                    // #endregion
                    print("ERROR: Failed to set task ID, aborting save")
                    return
                }
            }
            
            let oldState = task.isComplete
            // #region agent log
            debugLog(location: "TaskCardView:handleTaskCompletion", message: "About to toggle task state", data: ["taskId": task.id, "oldState": oldState, "hasGoal": task.goal != nil] as [String: Any], hypothesisId: "F")
            // #endregion
            
                task.isComplete.toggle()
            let newState = task.isComplete
            
            // #region agent log
            debugLog(location: "TaskCardView:handleTaskCompletion", message: "Task state toggled", data: ["taskId": task.id, "oldState": oldState, "newState": newState] as [String: Any], hypothesisId: "F")
            // #endregion
            
            // Update goal progress if task has a goal
            if let goal = task.goal {
                // #region agent log
                let goalUpdateStartTime = Date()
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Updating goal progress", data: ["taskId": task.id, "goalId": goal.id, "goalTitle": goal.title, "currentValue": goal.currentValue, "targetValue": goal.targetValue] as [String: Any], hypothesisId: "G")
                // #endregion
                
                GoalProgressUpdater.handleTaskToggle(task, context: modelContext, goals: [goal])
                
                // #region agent log
                let goalUpdateDuration = Date().timeIntervalSince(goalUpdateStartTime)
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Goal progress updated", data: ["taskId": task.id, "goalId": goal.id, "newCurrentValue": goal.currentValue, "newStatus": goal.status.rawValue, "duration": goalUpdateDuration] as [String: Any], hypothesisId: "G")
                // #endregion
            }
            
            // CRITICAL FIX: Only call closure if task is complete and has a valid ID
            // Note: task.id is non-optional String, but we check isEmpty to ensure it's valid
            if task.isComplete && !task.id.isEmpty {
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Calling onTaskCompleted closure", data: ["taskId": task.id] as [String: Any], hypothesisId: "F")
                // #endregion
                onTaskCompleted?(task.id)
            }
            
            // CRITICAL FIX: Ensure modelContext.save() happens on MainActor
            // Double-check ID is valid before attempting save
            let taskID = task.id // Capture ID to verify it's not empty
            guard !taskID.isEmpty else {
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "ERROR: Task ID is empty before save, aborting", data: [:], hypothesisId: "F")
                // #endregion
                print("ERROR: Task ID is empty before save, aborting")
                return
            }
            
            // #region agent log
            debugLog(location: "TaskCardView:handleTaskCompletion", message: "Starting async save task", data: ["taskId": task.id, "thread": Thread.isMainThread] as [String: Any], hypothesisId: "A")
            // #endregion
            
            _Concurrency.Task { @MainActor in
                // #region agent log
                let saveStartTime = Date()
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "Inside async save task", data: ["taskId": task.id, "thread": Thread.isMainThread] as [String: Any], hypothesisId: "A")
                // #endregion
                
                // Final verification before save
                guard !task.id.isEmpty else {
                    // #region agent log
                    debugLog(location: "TaskCardView:handleTaskCompletion", message: "ERROR: Task ID became empty in async context, aborting save", data: [:], hypothesisId: "A")
                    // #endregion
                    print("ERROR: Task ID became empty in async context, aborting save")
                    return
                }
                
                // #region agent log
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "About to call modelContext.save()", data: ["taskId": task.id] as [String: Any], hypothesisId: "A")
                // #endregion
                
                do {
                    try modelContext.save()
                    // #region agent log
                    let saveDuration = Date().timeIntervalSince(saveStartTime)
                    debugLog(location: "TaskCardView:handleTaskCompletion", message: "modelContext.save() SUCCEEDED", data: ["taskId": task.id, "duration": saveDuration] as [String: Any], hypothesisId: "A")
                    // #endregion
                } catch {
                    // #region agent log
                    let saveDuration = Date().timeIntervalSince(saveStartTime)
                    debugLog(location: "TaskCardView:handleTaskCompletion", message: "modelContext.save() FAILED", data: ["taskId": task.id, "error": error.localizedDescription, "errorType": String(describing: type(of: error)), "duration": saveDuration] as [String: Any], hypothesisId: "A")
                    // #endregion
                    print("Failed to save task completion: \(error)")
                }
                
                // #region agent log
                let totalDuration = Date().timeIntervalSince(completionStartTime)
                debugLog(location: "TaskCardView:handleTaskCompletion", message: "handleTaskCompletion completed", data: ["taskId": task.id, "totalDuration": totalDuration] as [String: Any], hypothesisId: "F")
                // #endregion
            }
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
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
        NavigationStack {
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
        NavigationStack {
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
        var body: some View { NavigationStack { MonthCalendarView(selectedDate: Binding(get: { targetDate }, set: { targetDate = $0; onDateSelected($0) })).navigationTitle("Move Task").navigationBarTitleDisplayMode(.inline).toolbarBackground(.hidden, for: .navigationBar).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } } } }
    }

    struct MoveTaskBlockCalendarView: View {
        let taskBlock: [Task]; let onDateSelected: (Date) -> Void; let onCancel: () -> Void; @State private var targetDate: Date
        init(taskBlock: [Task], onDateSelected: @escaping (Date) -> Void, onCancel: @escaping () -> Void) { self.taskBlock = taskBlock; self.onDateSelected = onDateSelected; self.onCancel = onCancel; self._targetDate = State(initialValue: taskBlock.first?.startTime ?? Date()) }
        var body: some View { NavigationStack { MonthCalendarView(selectedDate: Binding(get: { targetDate }, set: { targetDate = $0; onDateSelected($0) })).navigationTitle("Move Task Block").navigationBarTitleDisplayMode(.inline).toolbarBackground(.hidden, for: .navigationBar).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { onCancel() } } } } }
}

#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}
