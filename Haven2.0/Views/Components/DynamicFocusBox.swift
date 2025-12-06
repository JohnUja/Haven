//
//  DynamicFocusBox.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Smart Context Aggregator - Intelligent task grouping and display
//

import SwiftUI
import SwiftData
import AudioToolbox

// MARK: - Context Block Types
enum ContextBlockType {
    case categorySprint(category: TaskCategory, tasks: [Task])
    case locationBundle(location: String, tasks: [Task]) // Note: Location not in Task model yet
    case criticalFocus(task: Task)
    case upcomingBlock(period: String, tasks: [Task])
    case nextAction(task: Task)
    case freeTime
    
    var displayName: String {
        switch self {
        case .categorySprint(let category, _):
            return "\(category.displayName) Sprint"
        case .locationBundle(let location, _):
            return "\(location) Run"
        case .criticalFocus:
            return "CRITICAL FOCUS"
        case .upcomingBlock(let period, _):
            return "\(period) Focus"
        case .nextAction(let task):
            return task.title
        case .freeTime:
            return "Free Time"
        }
    }
    
    var icon: String {
        switch self {
        case .categorySprint(let category, _):
            return category.icon
        case .locationBundle:
            return "mappin.circle.fill"
        case .criticalFocus:
            return "flame.fill"
        case .upcomingBlock:
            return "sun.max.fill"
        case .nextAction(let task):
            return task.category.icon
        case .freeTime:
            return "moon.fill"
        }
    }
    
    var priority: PriorityType {
        switch self {
        case .categorySprint(_, let tasks):
            return tasks.map { $0.priority }.max(by: { $0.rawValue < $1.rawValue }) ?? .normal
        case .locationBundle(_, let tasks):
            return tasks.map { $0.priority }.max(by: { $0.rawValue < $1.rawValue }) ?? .normal
        case .criticalFocus(let task):
            return task.priority
        case .upcomingBlock(_, let tasks):
            return tasks.first?.priority ?? .normal
        case .nextAction(let task):
            return task.priority
        case .freeTime:
            return .normal
        }
    }
    
    var tasks: [Task] {
        switch self {
        case .categorySprint(_, let tasks), .locationBundle(_, let tasks), .upcomingBlock(_, let tasks):
            return tasks
        case .criticalFocus(let task), .nextAction(let task):
            return [task]
        case .freeTime:
            return []
        }
    }
}

struct DynamicFocusBox: View {
    let selectedDate: Date
    let allTasks: [Task]
    let allTaskBlocks: [TaskBlock]
    @Binding var previewTask: Task? // For Preview Mode from Agenda
    @Binding var isViewAllTasksMode: Bool // Expose mode to parent
    @State private var showingImmersive = false
    @State private var selectedTask: Task? = nil
    @State private var isPreviewMode = false
    @State private var currentPage = 0 // 0 = Active Context, 1 = Next Major Block Preview
    @State private var showingContextMenu = false
    @State private var checkedTaskIDs: Set<String> = [] // Tasks checked in dynamic box (not completed yet)
    @State private var showingProgressDetails = false
    @State private var showingTaskDetails = false
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @Query private var goals: [Goal]
    
    // Computed property to get current single task (for Complete/Snooze buttons)
    var currentSingleTask: Task? {
        guard !isViewAllTasksMode, let block = displayedBlock else { return nil }
        if block.tasks.count == 1 {
            return block.tasks.first
        }
        return nil
    }
    
    // MARK: - Smart Context Aggregator
    private var activeContextBlock: ContextBlockType? {
        let calendar = Calendar.current
        let referenceTime = calendar.isDateInToday(selectedDate) ? Date() : calendar.startOfDay(for: selectedDate)
        let eightHoursFromNow = calendar.date(byAdding: .hour, value: 8, to: referenceTime) ?? referenceTime
        
        // Get incomplete tasks for selected date (including tasks in blocks and past tasks)
        let upcomingTasks = allTasks.filter { task in
            let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
            // Include all incomplete tasks for the day, regardless of time or block status
            guard isSameDay && !task.isComplete else { return false }
            // For today, show tasks from now. For other dates, show all tasks
            if calendar.isDateInToday(selectedDate) {
                // Include tasks that are upcoming or recently past (within last hour)
                let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: referenceTime) ?? referenceTime
                return task.startTime >= oneHourAgo && task.startTime <= eightHoursFromNow
            } else {
                // For other dates, show all tasks in the day
                return task.startTime >= calendar.startOfDay(for: selectedDate) && task.startTime <= eightHoursFromNow
            }
        }
        
        guard !upcomingTasks.isEmpty else {
            // Rule 6: FREE TIME - but show next task if available (check all day tasks, including past ones)
            let allDayTasks = allTasks.filter { task in
                let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
                return isSameDay && !task.isComplete
            }
            if let nextTask = allDayTasks.sorted(by: { $0.startTime < $1.startTime }).first {
                return .nextAction(task: nextTask) // Show next task instead of free time
            }
            return .freeTime
        }
        
        // Rule 1: CATEGORY SPRINT - 2+ tasks share same Category in next 8 hours
        let categoryGroups = Dictionary(grouping: upcomingTasks) { $0.category }
        for (category, tasks) in categoryGroups where tasks.count >= 2 {
            return .categorySprint(category: category, tasks: tasks)
        }
        
        // Rule 2: LOCATION BUNDLE - 2+ tasks share same Location (not implemented - no location field)
        // TODO: Implement when location field is added to Task model
        
        // Rule 3: CRITICAL FOCUS - 1 task currently active (+/- 15 mins) AND HIGH PRIORITY
        let activeWindow = 15.0 * 60.0 // 15 minutes in seconds
        for task in upcomingTasks {
            let timeUntilStart = task.startTime.timeIntervalSince(referenceTime)
            if abs(timeUntilStart) <= activeWindow && task.priority == .urgent {
                return .criticalFocus(task: task)
            }
        }
        
        // Rule 4: UPCOMING BLOCK - 2+ tasks clustered within Adaptive Temporal Clustering Window
        let clustered = findTemporalClusters(tasks: upcomingTasks)
        if let cluster = clustered.first, cluster.count >= 2 {
            let period = getTimePeriod(for: cluster.first?.startTime ?? referenceTime)
            return .upcomingBlock(period: period, tasks: cluster)
        }
        
        // Rule 5: NEXT ACTION - Only one task upcoming in next 90 minutes
        let ninetyMinutesFromNow = calendar.date(byAdding: .minute, value: 90, to: referenceTime) ?? referenceTime
        let next90MinTasks = upcomingTasks.filter { $0.startTime <= ninetyMinutesFromNow }
        if next90MinTasks.count == 1, let task = next90MinTasks.first {
            return .nextAction(task: task)
        }
        
        // Fallback: Use first task
        if let firstTask = upcomingTasks.sorted(by: { $0.startTime < $1.startTime }).first {
            return .nextAction(task: firstTask)
        }
        
        return .freeTime
    }
    
    private var nextMajorBlock: ContextBlockType? {
        guard let activeBlock = activeContextBlock else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let eightHoursFromNow = calendar.date(byAdding: .hour, value: 8, to: now) ?? now
        
        // Get tasks after the active block
        let activeTaskIds = Set(activeBlock.tasks.map { $0.id })
        let remainingTasks = allTasks.filter { task in
            let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
            guard isSameDay && !task.isComplete else { return false }
            guard !activeTaskIds.contains(task.id) else { return false }
            return task.startTime >= now && task.startTime <= eightHoursFromNow
        }
        
        guard !remainingTasks.isEmpty else { return nil }
        
        // Find next cluster
        let clustered = findTemporalClusters(tasks: remainingTasks)
        if let cluster = clustered.first, cluster.count >= 2 {
            let period = getTimePeriod(for: cluster.first?.startTime ?? now)
            return .upcomingBlock(period: period, tasks: cluster)
        }
        
        // Or next single task
        if let nextTask = remainingTasks.sorted(by: { $0.startTime < $1.startTime }).first {
            return .nextAction(task: nextTask)
        }
        
        return nil
    }
    
    // Adaptive Temporal Clustering Window
    private func findTemporalClusters(tasks: [Task]) -> [[Task]] {
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        let totalTasks = allTasks.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) && !$0.isComplete
        }.count
        
        // Determine max gap based on day density
        let maxGapMinutes: Int
        if totalTasks >= 8 {
            maxGapMinutes = 30 // High density
        } else if totalTasks >= 4 {
            maxGapMinutes = 60 // Medium density
        } else {
            maxGapMinutes = 90 // Low density
        }
        
        var clusters: [[Task]] = []
        var currentCluster: [Task] = []
        
        for task in sortedTasks {
            if currentCluster.isEmpty {
                currentCluster.append(task)
            } else {
                let lastTask = currentCluster.last!
                let gap = task.startTime.timeIntervalSince(lastTask.endTime) / 60.0 // Gap in minutes
                
                if gap <= Double(maxGapMinutes) {
                    currentCluster.append(task)
                } else {
                    if currentCluster.count >= 2 {
                        clusters.append(currentCluster)
                    }
                    currentCluster = [task]
                }
            }
        }
        
        if currentCluster.count >= 2 {
            clusters.append(currentCluster)
        }
        
        return clusters
    }
    
    private func getTimePeriod(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    // Current displayed block (based on page)
    private var displayedBlock: ContextBlockType? {
        if isPreviewMode, let preview = previewTask {
            return .nextAction(task: preview)
        }
        
        if currentPage == 0 {
            return activeContextBlock
        } else {
            return nextMajorBlock
        }
    }
    
    // Priority-based gradient
    private var priorityGradient: LinearGradient {
        guard let block = displayedBlock else {
            return LinearGradient(colors: [Color.gray, Color.gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        let priority = block.priority
        switch priority {
        case .urgent:
            return LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .high:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .normal:
            return LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .low:
            return LinearGradient(colors: [Color.teal, Color.green], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // Fixed height - Made shorter per user request
    private let fixedHeight: CGFloat = 280 // Reduced from 380
    
    var body: some View {
        mainContent
            .background(cardBackground)
            .contextMenu {
                contextMenuItems(theme: themeManager.currentTheme)
            }
            .fullScreenCover(isPresented: $showingImmersive, content: immersiveView)
            .sheet(isPresented: $showingProgressDetails, content: progressDetailsSheet)
            .sheet(isPresented: $showingTaskDetails, content: taskDetailsSheet)
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        let theme = themeManager.currentTheme
        
        VStack(spacing: 0) {
            focusBoxHeader(theme: theme)
            
            if isViewAllTasksMode {
                viewAllTasksContent(theme: theme)
            } else {
                dynamicModeContent(theme: theme)
            }
        }
        .frame(minHeight: isViewAllTasksMode ? nil : fixedHeight)
    }
    
    // MARK: - Background
    @ViewBuilder
    private var cardBackground: some View {
        let theme = themeManager.currentTheme
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .stroke(theme.cardStroke, lineWidth: theme.cardBorderWidth)
    }
    
    // MARK: - Immersive View
    @ViewBuilder
    private func immersiveView() -> some View {
        if let task = selectedTask {
            ImmersiveWorkingOnView(task: task, onDismiss: {
                showingImmersive = false
                selectedTask = nil
            })
        }
    }
    
    // MARK: - Progress Details Sheet
    @ViewBuilder
    private func progressDetailsSheet() -> some View {
        if let block = displayedBlock {
            
            let theme = themeManager.currentTheme
            let tasks = block.tasks
            let checkedCount = tasks.filter { checkedTaskIDs.contains($0.id) }.count
            let totalCount = tasks.count
            // Safe progress calculation: avoid division by zero (NaN)
            let progress = totalCount > 0 ? CGFloat(checkedCount) / CGFloat(totalCount) : 0.0
            
            NavigationStack {
                ZStack {
                    theme.primaryGradient.ignoresSafeArea()
                    progressDetailsContent(checkedCount: checkedCount, totalCount: totalCount, progress: progress, theme: theme)
                }
                .navigationTitle("Progress")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingProgressDetails = false
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func progressDetailsContent(checkedCount: Int, totalCount: Int, progress: CGFloat, theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
            Text("\(checkedCount) of \(totalCount) tasks completed")
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
            
            if totalCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.glassBorder.opacity(0.3))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.textPrimary)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal)
                
                // Safe progress percentage: ensure progress is valid and not NaN
                let safeProgress = progress.isFinite && !progress.isNaN ? progress : 0.0
                Text("\(Int(safeProgress * 100))% Complete")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
            } else {
                Text("No tasks to complete")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Task Details Sheet
    @ViewBuilder
    private func taskDetailsSheet() -> some View {
        if let task = selectedTask {
            
            let theme = themeManager.currentTheme
            
            NavigationStack {
                ZStack {
                    theme.primaryGradient.ignoresSafeArea()
                    taskDetailsContent(task: task, theme: theme)
                }
                .navigationTitle("Task Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingTaskDetails = false
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func taskDetailsContent(task: Task, theme: any AppTheme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(task.title)
                    .font(theme.headerFont)
                    .foregroundColor(theme.textPrimary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category: \(task.category.displayName)")
                    Text("Priority: \(task.priority.rawValue.capitalized)")
                    Text("Time: \(formatTimeWithAMPM(task.startTime)) - \(formatTimeWithAMPM(task.endTime))")
                }
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
            }
            .padding()
        }
    }
    
    // MARK: - Header
    private func focusBoxHeader(theme: any AppTheme) -> some View {
        HStack {
            // Left: Dynamic name with icon - REGULAR TEXT NOT CAPITALIZED
            if let block = displayedBlock, !isViewAllTasksMode {
                HStack(spacing: 8) {
                    // Show "Upcoming" on page 2 - regular text
                    if currentPage == 1 {
                        Text("Upcoming")
                            .font(.system(size: 10, weight: .light, design: .default))
                            .foregroundColor(theme.textPrimary.opacity(0.6))
                    }
                    
                    Image(systemName: block.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    // Context-aware heading: single task shows title, group shows context name - regular text
                    if block.tasks.count == 1, let task = block.tasks.first {
                        Text(task.title) // Removed .uppercased()
                            .font(.system(size: 16, weight: .regular, design: .default)) // Changed to .regular
                            .foregroundColor(theme.textPrimary)
                    } else {
                        Text(block.displayName) // Removed .uppercased()
                            .font(.system(size: 16, weight: .regular, design: .default)) // Changed to .regular
                            .foregroundColor(theme.textPrimary)
                    }
                }
            } else if isViewAllTasksMode {
                Text("All Tasks") // Removed "ALL TASKS"
                    .font(.system(size: 16, weight: .regular, design: .default)) // Changed to .regular
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
            
            // Right: Toggle button + Cancel preview + Complete All + 3-dot menu
            HStack(spacing: 12) {
                // Toggle button (moved to right)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isViewAllTasksMode.toggle()
                        if isViewAllTasksMode {
                            exitPreviewMode()
                        }
                    }
                }) {
                    Image(systemName: isViewAllTasksMode ? "sparkles" : "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    Circle()
                                        .stroke(theme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                // Cancel preview button
                if isPreviewMode {
                    Button(action: {
                        exitPreviewMode()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                            .frame(width: 28, height: 28)
                    }
                }
                
                // Complete All button (square) - for groups
                if let block = displayedBlock, block.tasks.count > 1, !isViewAllTasksMode {
                    let uncheckedTasks = block.tasks.filter { !checkedTaskIDs.contains($0.id) }
                    if !uncheckedTasks.isEmpty {
                        Button(action: {
                            for task in uncheckedTasks {
                                checkedTaskIDs.insert(task.id)
                            }
                            AudioServicesPlaySystemSound(1520)
                        }) {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.accentColor)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                
                // 3-dot menu (moved to right) - only in dynamic mode - IMPLEMENT LOGIC
                if !isViewAllTasksMode && !isPreviewMode {
                    Menu {
                        Button(action: {
                            // Show progress details
                            showingProgressDetails = true
                        }) {
                            Label("View Progress", systemImage: "chart.bar.fill")
                        }
                        
                        Button(action: {
                            // Show task details
                            if let block = displayedBlock, let firstTask = block.tasks.first {
                                selectedTask = firstTask
                                showingTaskDetails = true
                            }
                        }) {
                            Label("Task Details", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding)
    }
    
    // MARK: - View All Tasks Content
    private func viewAllTasksContent(theme: any AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Show ALL tasks for selected date (including completed)
                let allTasksForDate = allTasks.filter { task in
                    Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
                }.sorted { $0.startTime < $1.startTime }
                
                if allTasksForDate.isEmpty {
                    emptyStateView(theme: theme)
                } else {
                    ForEach(allTasksForDate) { task in
                        viewAllTaskRow(task: task, theme: theme)
                    }
                    
                    // XP Summary at bottom
                    xpSummaryView(tasks: allTasksForDate, theme: theme)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - View All Task Row
    private func viewAllTaskRow(task: Task, theme: any AppTheme) -> some View {
        let xpGained = calculateXPForTask(task)
        
        return HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(task.isComplete ? theme.accentColor : theme.textPrimary.opacity(0.6))
            }
            
            // XP Badge (before category icon)
            if task.isComplete {
                // Grey XP for completed tasks
                Text("+\(xpGained) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            } else {
                // Purple with glow for incomplete tasks
                Text("+\(xpGained) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.accentColor.opacity(0.2))
                    .cornerRadius(4)
                    .shadow(color: theme.accentColor.opacity(0.5), radius: 4)
            }
            
            // Category icon
                    Image(systemName: task.category.icon)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textPrimary.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .appTextStyle(.body, theme: theme)
                    .strikethrough(task.isComplete)
                    .opacity(task.isComplete ? 0.6 : 1.0)
                    
                    Text(timeRangeString(for: task))
                        .appTextStyle(.caption, theme: theme)
                        .opacity(0.7)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(theme.glassBackground.opacity(0.3))
        )
    }
    
    // MARK: - XP Summary View
    private func xpSummaryView(tasks: [Task], theme: any AppTheme) -> some View {
        let totalXP = tasks.reduce(0) { $0 + calculateXPForTask($1) }
        
        return HStack {
            Text("Total XP Available: \(totalXP)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.accentColor)
            Spacer()
        }
        .padding()
        .background(theme.accentColor.opacity(0.1))
        .cornerRadius(theme.smallCornerRadius)
    }
    
    // MARK: - Helper: Calculate XP for Task
    private func calculateXPForTask(_ task: Task) -> Int {
        // Use GamificationService to calculate XP
        let goal = task.goal
        let momentumBonus = 1.0 // Default, could get from user if needed
        let rewards = GamificationService.calculateTaskRewards(
            task: task,
            goal: goal,
            momentumBonus: momentumBonus
        )
        return rewards.xp
    }
    
    // MARK: - Dynamic Mode Content
    private func dynamicModeContent(theme: any AppTheme) -> some View {
        VStack(spacing: 0) {
            // Content with Pagination (2 pages)
            if let block = displayedBlock {
                TabView(selection: $currentPage) {
                    // Page 0: Active Context Block
                    contextBlockView(block: block, theme: theme)
                        .tag(0)
                    
                    // Page 1: Next Major Block Preview (only if exists)
                    if let nextBlock = nextMajorBlock {
                        contextBlockView(block: nextBlock, theme: theme)
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(minHeight: 250) // Increased height to prevent cutoff
            } else {
                emptyStateView(theme: theme)
            }
            
            // Progress Bar - Plain (only show when there are tasks)
            if let block = displayedBlock, !block.tasks.isEmpty {
                let checkedCount = block.tasks.filter { checkedTaskIDs.contains($0.id) }.count
                let totalCount = block.tasks.count
                let progress = totalCount > 0 ? CGFloat(checkedCount) / CGFloat(totalCount) : 0.0
                
            HStack {
                GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background - plain grey
                    Rectangle()
                                .fill(theme.textPrimary.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress - plain grey (no accent color)
                            Rectangle()
                                .fill(theme.textPrimary.opacity(0.5))
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                }
                .frame(height: 4)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            }
        }
        .frame(height: fixedHeight - 60) // Subtract header height
    }
    
    // MARK: - Context Block View
    private func contextBlockView(block: ContextBlockType, theme: any AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                switch block {
                case .categorySprint(_, let tasks), .locationBundle(_, let tasks), .upcomingBlock(_, let tasks):
                    // Full Checklist with checkmarks
                    ForEach(tasks) { task in
                        checklistItemView(task: task, theme: theme)
                    }
                    
                case .criticalFocus(let task), .nextAction(let task):
                    // Single Task Details
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .appTextStyle(.sectionHeader, theme: theme)
                                .multilineTextAlignment(.leading)
                            
                            // Preview Mode: Show static info + Start Now button
                            if isPreviewMode {
                                timeInfoView(for: task, theme: theme)
                            } else {
                                // Normal mode: Countdown if active, else time info
                                if isTaskActive(task) {
                                    countdownView(for: task, theme: theme)
                                } else {
                                    timeInfoView(for: task, theme: theme)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Category icon on right side
                        Image(systemName: task.category.icon)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(theme.accentColor.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Preview Mode: Start Now button with shimmer
                    if isPreviewMode {
                        startNowButton(theme: theme)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    
                case .freeTime:
                    let calendar = Calendar.current
                    let referenceTime = calendar.isDateInToday(selectedDate) ? Date() : calendar.startOfDay(for: selectedDate)
                    let nextTask = allTasks.filter {
                        Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) &&
                        $0.startTime > referenceTime && !$0.isComplete
                    }.sorted { $0.startTime < $1.startTime }.first
                    
                    VStack(spacing: 16) {
                        Text("No tasks for now")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Enjoy your free time")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                        
                        if let nextTask = nextTask {
                            VStack(spacing: 4) {
                                Text("Next: \(nextTask.title)")
                                    .font(.system(size: 14, weight: .semibold, design: .default))
                                    .foregroundColor(theme.textPrimary)
                                Text("at \(formatTimeWithAMPM(nextTask.startTime))")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundColor(theme.textPrimary.opacity(0.7))
                            }
                                .padding(.top, 8)
                        }
                    }
                    .padding(40)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Checklist Item
    private func checklistItemView(task: Task, theme: any AppTheme) -> some View {
        let isChecked = checkedTaskIDs.contains(task.id)
        
        return HStack(spacing: 12) {
            Button(action: {
                if isChecked {
                    checkedTaskIDs.remove(task.id)
                } else {
                    checkedTaskIDs.insert(task.id)
                }
                AudioServicesPlaySystemSound(1520)
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isChecked ? .white : theme.textPrimary.opacity(0.6))
            }
            
            Text(task.title)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(isChecked ? theme.textPrimary.opacity(0.5) : theme.textPrimary)
                .strikethrough(isChecked)
            
            Spacer()
            
            // Time on right (7PM - 7:15PM format)
            Text(formatTimeWithAMPM(task.startTime) + " - " + formatTimeWithAMPM(task.endTime))
                .font(.system(size: 7, weight: .bold, design: .default))
                .foregroundColor(theme.textPrimary.opacity(0.7))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Countdown View
    private func countdownView(for task: Task, theme: any AppTheme) -> some View {
        let now = Date()
        let timeRemaining = task.endTime.timeIntervalSince(now)
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        return HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary.opacity(0.7))
            
            if hours > 0 {
                Text("\(hours)h \(minutes)m remaining")
                    .appTextStyle(.caption, theme: theme)
            } else {
                Text("\(minutes)m remaining")
                    .appTextStyle(.caption, theme: theme)
            }
        }
    }
    
    // MARK: - Helper Functions & Placeholders
    // Added these to fix the "Cannot find in scope" errors.
    // If you have these defined in another file, you can delete them here.
    
    private func contextMenuItems(theme: any AppTheme) -> some View {
        Group {
            Button(action: {
                showingProgressDetails = true
            }) {
                Label("View Progress", systemImage: "chart.bar.fill")
            }
            
            if let task = currentSingleTask {
                Button(action: {
                    showingTaskDetails = true
                    selectedTask = task
                }) {
                    Label("Task Details", systemImage: "info.circle.fill")
                }
            }
        }
    }
    
    private func formatTimeWithAMPM(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func timeRangeString(for task: Task) -> String {
        "\(formatTimeWithAMPM(task.startTime)) - \(formatTimeWithAMPM(task.endTime))"
    }
    
    private func isTaskActive(_ task: Task) -> Bool {
        let now = Date()
        return now >= task.startTime && now <= task.endTime
    }
    
    private func exitPreviewMode() {
        withAnimation {
            isPreviewMode = false
            previewTask = nil
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        // Add your completion logic here, e.g.:
        // task.isComplete.toggle()
    }
    
    private func emptyStateView(theme: any AppTheme) -> some View {
        Text("No Tasks Found")
            .foregroundColor(theme.textSecondary)
            .padding()
    }
    
    private func progressBarView(theme: any AppTheme) -> some View {
        // Only show progress bar when there are tasks
        guard let block = displayedBlock, !block.tasks.isEmpty else {
            return AnyView(EmptyView())
        }
        
        let checkedCount = block.tasks.filter { checkedTaskIDs.contains($0.id) }.count
        let totalCount = block.tasks.count
        let progress = totalCount > 0 ? CGFloat(checkedCount) / CGFloat(totalCount) : 0.0
        
        return AnyView(
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background - plain grey
            Rectangle()
                        .fill(theme.textPrimary.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress - plain grey (no accent color)
                    Rectangle()
                        .fill(theme.textPrimary.opacity(0.5))
                        .frame(width: geometry.size.width * progress, height: 4)
                }
        }
        .frame(height: 4)
        )
    }
    
    private func startNowButton(theme: any AppTheme) -> some View {
        Button(action: {
            // Start logic
        }) {
            Text("Start Now")
                .padding()
                .background(theme.accentColor)
                .cornerRadius(8)
        }
    }
    
    private func timeInfoView(for task: Task, theme: any AppTheme) -> some View {
        Text(timeRangeString(for: task))
            .font(theme.bodyFont)
            .foregroundColor(theme.textSecondary)
    }
}
