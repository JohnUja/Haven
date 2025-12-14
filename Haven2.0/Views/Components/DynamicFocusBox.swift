//
//  DynamicFocusBox.swift
//  Haven2.0
//
//  Smart Context Aggregator - Intelligent task grouping and display
//

import SwiftUI
import SwiftData
import AudioToolbox

// MARK: - Context Block Types
enum ContextBlockType {
    case categorySprint(category: TaskCategory, tasks: [Task])
    case locationBundle(location: String, tasks: [Task])
    case criticalFocus(task: Task)
    case upcomingBlock(period: String, tasks: [Task])
    case nextAction(task: Task)
    case freeTime
    
    var displayName: String {
        switch self {
        case .categorySprint(let category, _): return "\(category.displayName) Sprint"
        case .locationBundle(let location, _): return "\(location) Run"
        case .criticalFocus: return "CRITICAL FOCUS"
        case .upcomingBlock(let period, _): return "\(period) Focus"
        case .nextAction(let task): return task.title
        case .freeTime: return "Free Time"
        }
    }
    
    var icon: String {
        switch self {
        case .categorySprint(let category, _): return category.icon
        case .locationBundle: return "mappin.circle.fill"
        case .criticalFocus: return "flame.fill"
        case .upcomingBlock: return "sun.max.fill"
        case .nextAction(let task): return task.category.icon
        case .freeTime: return "moon.fill"
        }
    }
    
    var priority: PriorityType {
        switch self {
        case .categorySprint(_, let tasks):
            return tasks.map { $0.priority }.max(by: { $0.rawValue < $1.rawValue }) ?? .normal
        case .locationBundle(_, let tasks):
            return tasks.map { $0.priority }.max(by: { $0.rawValue < $1.rawValue }) ?? .normal
        case .criticalFocus(let task): return task.priority
        case .upcomingBlock(_, let tasks): return tasks.first?.priority ?? .normal
        case .nextAction(let task): return task.priority
        case .freeTime: return .normal
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
    var onAddTask: (() -> Void)? = nil // Callback for Add Task button
    
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    
    @State private var showingImmersive = false
    @State private var selectedTask: Task? = nil
    @State private var isPreviewMode = false
    @State private var currentPage = 0 // 0 = Active Context, 1 = Next Major Block Preview
    @State private var showingContextMenu = false
    @State private var checkedTaskIDs: Set<String> = [] // Tasks checked in dynamic box
    @State private var showingProgressDetails = false
    @State private var showingTaskDetails = false
    @State private var showingSplitView = false
    @State private var splitContextGroups: [String: [Task]] = [:]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @Query private var goals: [Goal]
    
    // Fixed height
    private let fixedHeight: CGFloat = 350
    
    // MARK: - Smart Context Aggregator Logic
    private var activeContextBlock: ContextBlockType? {
        let calendar = Calendar.current
        let referenceTime = calendar.isDateInToday(selectedDate) ? Date() : calendar.startOfDay(for: selectedDate)
        let eightHoursFromNow = calendar.date(byAdding: .hour, value: 8, to: referenceTime) ?? referenceTime
        
        let upcomingTasks = allTasks.filter { task in
            let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
            guard isSameDay && !task.isComplete else { return false }
            if calendar.isDateInToday(selectedDate) {
                let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: referenceTime) ?? referenceTime
                return task.startTime >= oneHourAgo && task.startTime <= eightHoursFromNow
            } else {
                return task.startTime >= calendar.startOfDay(for: selectedDate) && task.startTime <= eightHoursFromNow
            }
        }
        
        guard !upcomingTasks.isEmpty else {
            let allDayTasks = allTasks.filter { task in
                let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
                return isSameDay && !task.isComplete
            }
            if let nextTask = allDayTasks.sorted(by: { $0.startTime < $1.startTime }).first {
                return .nextAction(task: nextTask)
            }
            return .freeTime
        }
        
        // Rule 1: Category Sprint
        let categoryGroups = Dictionary(grouping: upcomingTasks) { $0.category }
        for (category, tasks) in categoryGroups where tasks.count >= 2 {
            return .categorySprint(category: category, tasks: tasks)
        }
        
        // Rule 3: Critical Focus
        let activeWindow = 15.0 * 60.0
        for task in upcomingTasks {
            let timeUntilStart = task.startTime.timeIntervalSince(referenceTime)
            if abs(timeUntilStart) <= activeWindow && task.priority == .urgent {
                return .criticalFocus(task: task)
            }
        }
        
        // Rule 4: Upcoming Block
        let clustered = findTemporalClusters(tasks: upcomingTasks)
        if let cluster = clustered.first, cluster.count >= 2 {
            let period = getTimePeriod(for: cluster.first?.startTime ?? referenceTime)
            return .upcomingBlock(period: period, tasks: cluster)
        }
        
        // Rule 5: Next Action
        let ninetyMinutesFromNow = calendar.date(byAdding: .minute, value: 90, to: referenceTime) ?? referenceTime
        let next90MinTasks = upcomingTasks.filter { $0.startTime <= ninetyMinutesFromNow }
        if next90MinTasks.count == 1, let task = next90MinTasks.first {
            return .nextAction(task: task)
        }
        
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
        
        let activeTaskIds = Set(activeBlock.tasks.map { $0.id })
        let remainingTasks = allTasks.filter { task in
            let isSameDay = calendar.isDate(task.startTime, inSameDayAs: selectedDate)
            guard isSameDay && !task.isComplete else { return false }
            guard !activeTaskIds.contains(task.id) else { return false }
            return task.startTime >= now && task.startTime <= eightHoursFromNow
        }
        
        guard !remainingTasks.isEmpty else { return nil }
        
        let clustered = findTemporalClusters(tasks: remainingTasks)
        if let cluster = clustered.first, cluster.count >= 2 {
            let period = getTimePeriod(for: cluster.first?.startTime ?? now)
            return .upcomingBlock(period: period, tasks: cluster)
        }
        
        if let nextTask = remainingTasks.sorted(by: { $0.startTime < $1.startTime }).first {
            return .nextAction(task: nextTask)
        }
        
        return nil
    }
    
    private func findTemporalClusters(tasks: [Task]) -> [[Task]] {
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        let totalTasks = allTasks.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) && !$0.isComplete
        }.count
        
        let maxGapMinutes: Int = totalTasks >= 8 ? 30 : (totalTasks >= 4 ? 60 : 90)
        
        var clusters: [[Task]] = []
        var currentCluster: [Task] = []
        
        for task in sortedTasks {
            if currentCluster.isEmpty {
                currentCluster.append(task)
            } else {
                let lastTask = currentCluster.last!
                let gap = task.startTime.timeIntervalSince(lastTask.endTime) / 60.0
                
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
    
    private var displayedBlock: ContextBlockType? {
        if isPreviewMode, let preview = previewTask {
            return .nextAction(task: preview)
        }
        return currentPage == 0 ? activeContextBlock : nextMajorBlock
    }
    
    // MARK: - Body
    var body: some View {
        mainContent
            .background(cardBackground)
            .contextMenu {
                contextMenuItems(theme: themeManager.currentTheme)
            }
            .fullScreenCover(isPresented: $showingImmersive, content: immersiveView)
            .sheet(isPresented: $showingProgressDetails, content: progressDetailsSheet)
            .sheet(isPresented: $showingTaskDetails, content: taskDetailsSheet)
            .sheet(isPresented: $showingSplitView) { splitViewSheet }
            .onChange(of: showingSplitView) { _, newValue in
                if newValue {
                    let allDayTasks = allTasks.filter { task in
                        Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
                    }.sorted { $0.startTime < $1.startTime }
                    splitContextGroups = initializeContextGroups(allDayTasks: allDayTasks)
                }
            }
    }
    
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
    
    @ViewBuilder
    private var cardBackground: some View {
        let theme = themeManager.currentTheme
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .stroke(theme.cardStroke, lineWidth: theme.cardBorderWidth)
    }
    
    // MARK: - Header
    private func focusBoxHeader(theme: any AppTheme) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let dateString = dateFormatter.string(from: selectedDate)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateString)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Only show 3-dot menu (removed "check all" box)
                if !isViewAllTasksMode && !isPreviewMode {
                    Menu {
                        contextMenuItems(theme: theme)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            
            HStack {
                if let block = displayedBlock, !isViewAllTasksMode {
                    HStack(spacing: 8) {
                        Image(systemName: block.icon)
                            .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.textPrimary)
                            .symbolRenderingMode(.hierarchical)
                        
                        if currentPage == 1 {
                            // Upcoming page: "Upcoming (time) - Category icon task name"
                            if case .categorySprint(let category, let tasks) = block, let firstTask = tasks.first {
                                HStack(spacing: 6) {
                                    Text("Upcoming")
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Text(formatTimeWithAMPM(firstTask.startTime))
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Text("-")
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Image(systemName: firstTask.category.icon)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(theme.textPrimary)
                                        .symbolRenderingMode(.hierarchical)
                                    
                                    Text(firstTask.title)
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                            } else if block.tasks.count == 1, let task = block.tasks.first {
                                HStack(spacing: 6) {
                                    Text("Upcoming")
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Text(formatTimeWithAMPM(task.startTime))
                    .font(theme.headerFont)
                    .foregroundColor(theme.textPrimary)
                
                                    Text("-")
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Image(systemName: task.category.icon)
                                        .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textPrimary)
                                        .symbolRenderingMode(.hierarchical)
                                    
                                    Text(task.title)
                                        .font(theme.headerFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                            } else {
                                Text("Upcoming")
                                    .font(theme.headerFont)
                        .foregroundColor(theme.textPrimary)
                            }
                        } else {
                            // Normal page: task title or context name
                    if block.tasks.count == 1, let task = block.tasks.first {
                                Text(task.title)
                                    .font(theme.headerFont)
                            .foregroundColor(theme.textPrimary)
                    } else {
                                Text(block.displayName)
                                    .font(theme.headerFont)
                            .foregroundColor(theme.textPrimary)
                            }
                    }
                }
            } else if isViewAllTasksMode {
                    Text("All Tasks")
                        .font(theme.headerFont)
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
            
                if isPreviewMode {
                    Button(action: { exitPreviewMode() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                            .frame(width: 28, height: 28)
                    }
                }
            }
        }
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding)
    }
    
    // MARK: - Dynamic Mode Content
    private func dynamicModeContent(theme: any AppTheme) -> some View {
        VStack(spacing: 0) {
            if let block = displayedBlock {
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        VStack(spacing: 0) {
                            // Task list content
                            contextBlockView(block: block, theme: theme)
                            
                            // Progress bar and percentage BELOW task list, ABOVE pagination (for multiple tasks)
                            if block.tasks.count > 1 {
                                multiTaskProgressView(block: block, theme: theme)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                            }
                        }
                        .tag(0)
                        
                        if let nextBlock = nextMajorBlock {
                            VStack(spacing: 0) {
                                contextBlockView(block: nextBlock, theme: theme)
                                
                                if nextBlock.tasks.count > 1 {
                                    multiTaskProgressView(block: nextBlock, theme: theme)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                        .padding(.bottom, 4)
                                }
                            }
                            .tag(1)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: nextMajorBlock != nil ? .always : .never)) // Hide pagination when only one page
                    .frame(minHeight: 200)
                    
                    // Bottom: Due time and total XP at bottom left, Info button and Toggle button at bottom right
                    HStack(alignment: .bottom) {
                        // Left: Due time and total XP (left aligned)
                        VStack(alignment: .leading, spacing: 4) {
                            if block.tasks.count == 1, let task = block.tasks.first {
                                // Single task: Due time and XP
                                Text("Due: \(formatTimeWithAMPM(task.endTime))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(theme.textSecondary.opacity(0.7))
                                
                                let xpGained = calculateXPForTask(task)
                                Text("\(xpGained) XP")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(theme.accentColor)
                            } else {
                                // Multiple tasks: Due time and total XP
                                let contextEndTime = block.tasks.map { $0.endTime }.max() ?? Date()
                                Text("Due: \(formatTimeWithAMPM(contextEndTime))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(theme.textSecondary.opacity(0.7))
                                
                                let totalXP = block.tasks.reduce(0) { $0 + calculateXPForTask($1) }
                                Text("\(totalXP) XP")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Toggle button only (info moved to 3-dot menu)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isViewAllTasksMode.toggle()
                                if isViewAllTasksMode { exitPreviewMode() }
                            }
                        }) {
                            Image(systemName: isViewAllTasksMode ? "sparkles" : "list.bullet")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(theme.glassBackground.opacity(0.5))
                                        .overlay(Circle().stroke(theme.glassBorder, lineWidth: 1))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            } else {
                // Empty state - NO footer/content, just empty state view
                emptyStateView(theme: theme)
            }
        }
        .frame(height: fixedHeight - 60)
    }
    
    private func multiTaskProgressView(block: ContextBlockType, theme: any AppTheme) -> some View {
        let checkedCount = block.tasks.filter { checkedTaskIDs.contains($0.id) }.count
        let totalCount = block.tasks.count
        let progress = totalCount > 0 ? CGFloat(checkedCount) / CGFloat(totalCount) : 0.0
        let percentage = Int(progress * 100)
        
        return HStack(alignment: .center, spacing: 8) {
            // Progress bar on left
            GeometryReader { geometry in
                let progressBarWidth = geometry.size.width * 0.4
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(theme.textPrimary.opacity(0.2))
                        .frame(width: progressBarWidth, height: 4)
                    Rectangle()
                        .fill(theme.textPrimary.opacity(0.5))
                        .frame(width: progressBarWidth * progress, height: 4)
                }
                .frame(height: 4)
            }
            .frame(height: 4)
            
            // Percentage on right of progress bar
            Text("\(percentage)%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.textPrimary)
        }
    }
    
    // MARK: - Context Block View
    private func contextBlockView(block: ContextBlockType, theme: any AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                switch block {
                case .categorySprint(_, let tasks), .locationBundle(_, let tasks), .upcomingBlock(_, let tasks):
                    ForEach(tasks) { task in
                        checklistItemView(task: task, theme: theme)
                    }
                    
                case .criticalFocus(let task), .nextAction(let task):
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .appTextStyle(.sectionHeader, theme: theme)
                                .multilineTextAlignment(.leading)
                            
                            if isPreviewMode {
                                timeInfoView(for: task, theme: theme)
                            } else {
                                if isTaskActive(task) {
                                    countdownView(for: task, theme: theme)
                                } else {
                                    timeInfoView(for: task, theme: theme)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: task.category.icon)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(theme.textPrimary.opacity(0.6))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if isPreviewMode {
                        startNowButton(theme: theme)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    
                case .freeTime:
                    freeTimeView(theme: theme)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private func freeTimeView(theme: any AppTheme) -> some View {
        // Use the same empty state as Plan view (basket icon, text, Add Task button)
        return emptyStateView(theme: theme)
    }
    
    // MARK: - View All Tasks Content
    private func viewAllTasksContent(theme: any AppTheme) -> some View {
        let allTasksForDate = allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
        
        return ScrollView {
            VStack(spacing: 12) {
                if allTasksForDate.isEmpty {
                    emptyStateView(theme: theme)
                } else {
                    ForEach(allTasksForDate) { task in
                        viewAllTaskRow(task: task, theme: theme)
                    }
                    HStack(alignment: .bottom) {
                        // Total XP with square border on extreme left
                        xpSummaryView(tasks: allTasksForDate, theme: theme)
                        
                        Spacer()
                        
                        // Toggle button on extreme right
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isViewAllTasksMode.toggle()
                            }
                        }) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(theme.glassBackground.opacity(0.5))
                                        .overlay(Circle().stroke(theme.glassBorder, lineWidth: 1))
                                )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private func viewAllTaskRow(task: Task, theme: any AppTheme) -> some View {
        let xpGained = calculateXPForTask(task)
        let isCurrentDay = Calendar.current.isDate(selectedDate, inSameDayAs: Date())
        
        return HStack(alignment: .top, spacing: 12) {
            // Left: Checkbox at center left (not top left)
            Button(action: { 
                if isCurrentDay {
                    toggleTaskCompletion(task)
                }
            }) {
                Image(systemName: task.isComplete ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(task.isComplete ? theme.accentColor : theme.textPrimary.opacity(0.6))
                    .opacity(isCurrentDay ? 1.0 : 0.3) // Disabled for non-current days
            }
            .disabled(!isCurrentDay) // Cannot check off tasks on non-current days
            
            // Middle: Task title (same font as plan view)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(theme.headerFont) // Same font as plan view (11pt, semibold)
                    .foregroundColor(theme.textPrimary)
                    .strikethrough(task.isComplete)
                    .opacity(task.isComplete ? 0.6 : 1.0)
                
                Text(timeRangeString(for: task))
                    .appTextStyle(.caption, theme: theme)
                    .opacity(0.7)
            }
            
            Spacer()
            
            // Right side: Category icon above XP (with spacing)
            VStack(alignment: .trailing, spacing: 8) {
                // Category icon on right, above XP
                Image(systemName: task.category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textPrimary.opacity(0.6))
                
                // XP below category icon
                Text("+\(xpGained) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(task.isComplete ? .gray : theme.accentColor) // Theme-controlled
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(task.isComplete ? Color.gray.opacity(0.5) : theme.accentColor, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(theme.glassBackground.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth * 1.5)
                )
        )
    }

    // MARK: - Helpers & Subviews
    private func checklistItemView(task: Task, theme: any AppTheme) -> some View {
        let isChecked = checkedTaskIDs.contains(task.id)
        let isCurrentDay = Calendar.current.isDate(selectedDate, inSameDayAs: Date())
        let xpGained = calculateXPForTask(task)
        
        return HStack(spacing: 12) {
            Button(action: {
                // Only allow checking on current day
                if isCurrentDay {
                    if isChecked { checkedTaskIDs.remove(task.id) }
                    else { checkedTaskIDs.insert(task.id) }
                AudioServicesPlaySystemSound(1520)
                }
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isChecked ? .white : theme.textPrimary.opacity(0.6))
                    .opacity(isCurrentDay ? 1.0 : 0.3) // Disabled for non-current days
            }
            .disabled(!isCurrentDay) // Cannot check off tasks on non-current days
            
            Text(task.title)
                .font(theme.headerFont)
                .foregroundColor(isChecked ? theme.textPrimary.opacity(0.5) : theme.textPrimary)
                .strikethrough(isChecked)
            
            Spacer()
            
            // XP before time interval - REDUCED SIZE
            HStack(spacing: 6) {
                Text("\(xpGained) XP")
                    .font(.system(size: 9, weight: .semibold)) // Reduced from 11 to 9
                    .foregroundColor(theme.accentColor) // Theme-controlled
                
            Text(formatTimeWithAMPM(task.startTime) + " - " + formatTimeWithAMPM(task.endTime))
                    .font(theme.headerFont)
                .foregroundColor(theme.textPrimary.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func timeInfoView(for task: Task, theme: any AppTheme) -> some View {
        Text(timeRangeString(for: task))
            .font(theme.bodyFont)
            .foregroundColor(theme.textSecondary)
    }
    
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
                Text("\(hours)h \(minutes)m remaining").appTextStyle(.caption, theme: theme)
            } else {
                Text("\(minutes)m remaining").appTextStyle(.caption, theme: theme)
            }
        }
    }

    private func startNowButton(theme: any AppTheme) -> some View {
        Button(action: {}) {
            Text("Start Now")
                .padding()
                .background(theme.accentColor)
                .cornerRadius(8)
        }
    }
    
    private func emptyStateView(theme: any AppTheme) -> some View {
        // EXACT same as Plan view empty state - matching font sizes and layout
        VStack(spacing: 16) {
            // Basket icon (tray icon like Plan view)
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(theme.textSecondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            // "No tasks for today" - same font as Plan view (theme.bodyFont)
            Text("No tasks for today")
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
            
            // "Create your first task to get started" - same font size as Plan view
            Text("Create your first task to get started")
                .font(.system(size: 10, weight: .regular, design: .default))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            // "+ Add Task" button - same styling as Plan view
            Button(action: { onAddTask?() }) {
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
    }

    // MARK: - Logic Helpers
    private func xpSummaryView(tasks: [Task], theme: any AppTheme) -> some View {
        let totalXP = tasks.reduce(0) { $0 + calculateXPForTask($1) }
        return Text("Total XP Available: \(totalXP)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4) // Square border (small corner radius)
                    .stroke(theme.accentColor, lineWidth: 1.5)
            )
    }
    
    private func calculateXPForTask(_ task: Task) -> Int {
        let goal = task.goal
        let momentumBonus = 1.0
        let rewards = GamificationService.calculateTaskRewards(task: task, goal: goal, momentumBonus: momentumBonus)
        return rewards.xp
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
    
    private func toggleTaskCompletion(_ task: Task) {
        // Implement completion logic here
    }
    
    private func exitPreviewMode() {
        withAnimation {
            isPreviewMode = false
            previewTask = nil
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(theme: any AppTheme) -> some View {
        // Info button (i) - show task/block details
        if let block = displayedBlock {
            Button(action: {
                showingTaskDetails = true
            }) {
                Label("Info", systemImage: "info.circle")
            }
        }
        
        if let block = displayedBlock, !block.tasks.isEmpty {
            Button(action: {
                if let firstTask = block.tasks.first {
                    selectedTask = firstTask
                    showingImmersive = true
                    // ActivityKit logic here
                }
            }) {
                Label("Start Focus", systemImage: "play.circle.fill")
            }
        }
        if let block = displayedBlock, block.tasks.count > 1 {
            Button(action: { showingSplitView = true }) {
                Label("Split", systemImage: "rectangle.split.2x1")
            }
        }
        Button(action: { onAddTask?() }) {
            Label("Add Task", systemImage: "plus.circle.fill")
        }
    }
    
    // MARK: - Initialize Context Groups
    private func initializeContextGroups(allDayTasks: [Task]) -> [String: [Task]] {
        var groups: [String: [Task]] = [:]
        var assignedTaskIDs: Set<String> = []

        for block in allTaskBlocks.filter({ Calendar.current.isDate($0.createdDate, inSameDayAs: selectedDate) }) {
            let tasksInBlock = allDayTasks.filter { $0.taskBlock?.id == block.id }
            if !tasksInBlock.isEmpty {
                groups[block.title] = tasksInBlock
                assignedTaskIDs.formUnion(tasksInBlock.map { $0.id })
            }
        }
        let standaloneTasks = allDayTasks.filter { !assignedTaskIDs.contains($0.id) }
        if !standaloneTasks.isEmpty {
            groups["Standalone"] = standaloneTasks
        }
        for (key, value) in groups {
            groups[key] = value.sorted { $0.startTime < $1.startTime }
        }
        if let standalone = groups["Standalone"] {
            groups.removeValue(forKey: "Standalone")
            groups["Standalone"] = standalone
        }
        return groups
    }
    
    // MARK: - Sheets (Immersive, Details, etc.)
    @ViewBuilder private func immersiveView() -> some View {
        if let task = selectedTask {
            ImmersiveWorkingOnView(task: task, onDismiss: {
                showingImmersive = false
                selectedTask = nil
            })
            .environment(themeManager)
            .environment(authService)
        }
    }
    
    @ViewBuilder private func progressDetailsSheet() -> some View {
        if let block = displayedBlock {
            let theme = themeManager.currentTheme
            let tasks = block.tasks
            let checkedCount = tasks.filter { checkedTaskIDs.contains($0.id) }.count
            let totalCount = tasks.count
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
                        Button("Done") { showingProgressDetails = false }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private func progressDetailsContent(checkedCount: Int, totalCount: Int, progress: CGFloat, theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
            Text("\(checkedCount) of \(totalCount) tasks completed")
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
            
            if totalCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(theme.glassBorder.opacity(0.3)).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4).fill(theme.textPrimary).frame(width: geometry.size.width * progress, height: 8)
                    }
                }.frame(height: 8).padding(.horizontal)
                
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
    
    @ViewBuilder private func taskDetailsSheet() -> some View {
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
                        Button("Done") { showingTaskDetails = false }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private func taskDetailsContent(task: Task, theme: any AppTheme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TITLE").font(theme.headerFont).foregroundColor(theme.textSecondary)
                    Text(task.title).font(theme.titleFont).foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, theme.cardPadding)
                .padding(.vertical, theme.cardVerticalPadding)
                .background(RoundedRectangle(cornerRadius: theme.smallCornerRadius).fill(theme.glassBackground.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: theme.smallCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)))
                
                if let description = task.taskDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION").font(theme.headerFont).foregroundColor(theme.textSecondary)
                        Text(description).font(theme.bodyFont).foregroundColor(theme.textPrimary)
                    }
                    .padding(.horizontal, theme.cardPadding)
                    .padding(.vertical, theme.cardVerticalPadding)
                    .background(RoundedRectangle(cornerRadius: theme.smallCornerRadius).fill(theme.glassBackground.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: theme.smallCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DETAILS").font(theme.headerFont).foregroundColor(theme.textSecondary)
                    HStack { Text("Category:").font(theme.bodyFont).foregroundColor(theme.textSecondary); Text(task.category.displayName).font(theme.bodyFont).foregroundColor(theme.textPrimary) }
                    HStack { Text("Priority:").font(theme.bodyFont).foregroundColor(theme.textSecondary); Text(task.priority.rawValue.capitalized).font(theme.bodyFont).foregroundColor(theme.textPrimary) }
                    HStack { Text("Time:").font(theme.bodyFont).foregroundColor(theme.textSecondary); Text(timeRangeString(for: task)).font(theme.bodyFont).foregroundColor(theme.textPrimary) }
                }
                .padding(.horizontal, theme.cardPadding)
                .padding(.vertical, theme.cardVerticalPadding)
                .background(RoundedRectangle(cornerRadius: theme.smallCornerRadius).fill(theme.glassBackground.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: theme.smallCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)))
            }
            .padding()
        }
    }
    
    @ViewBuilder private var splitViewSheet: some View {
        let theme = themeManager.currentTheme
        if splitContextGroups.isEmpty {
            // Logic handled in onChange, but safe fallback
        }
        NavigationView {
            ZStack {
                theme.primaryGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Split Tasks into Contexts").font(theme.titleFont).foregroundColor(theme.textPrimary).padding(.top, 20)
                        Text("Group your tasks by context. Drag tasks between contexts or tap to make them standalone.").font(theme.bodyFont).foregroundColor(theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(Array(splitContextGroups.keys.sorted()), id: \.self) { contextName in
                                contextGroupView(
                                    contextName: contextName,
                                    tasks: splitContextGroups[contextName] ?? [],
                                    theme: theme,
                                    onEditContext: { newName in
                                        let tasks = splitContextGroups[contextName] ?? []
                                        splitContextGroups.removeValue(forKey: contextName)
                                        if newName.isEmpty { splitContextGroups["Standalone", default: []].append(contentsOf: tasks) }
                                        else { splitContextGroups[newName] = tasks }
                                    },
                                    onMoveTask: { task, toContext in
                                        splitContextGroups[contextName]?.removeAll { $0.id == task.id }
                                        if splitContextGroups[contextName]?.isEmpty == true { splitContextGroups.removeValue(forKey: contextName) }
                                        splitContextGroups[toContext, default: []].append(task)
                                    },
                                    onMakeStandalone: { task in
                                        splitContextGroups[contextName]?.removeAll { $0.id == task.id }
                                        if splitContextGroups[contextName]?.isEmpty == true { splitContextGroups.removeValue(forKey: contextName) }
                                        splitContextGroups["Standalone", default: []].append(task)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
        Button(action: {
                            let newContext = "New Context \(splitContextGroups.count + 1)"
                            splitContextGroups[newContext] = []
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Context")
                            }
                            .font(theme.bodyFont)
                            .foregroundColor(theme.accentColor)
                            .frame(maxWidth: .infinity)
                .padding()
                            .background(RoundedRectangle(cornerRadius: theme.smallCornerRadius).fill(theme.glassBackground.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: theme.smallCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Split Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContextGroupings(contextGroups: splitContextGroups)
                        showingSplitView = false
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingSplitView = false }
                }
            }
        }
    }
    
    private func saveContextGroupings(contextGroups: [String: [Task]]) {
        let nonEmptyContexts = contextGroups.filter { !$0.value.isEmpty }
        let existingBlocksForDay = allTaskBlocks.filter { Calendar.current.isDate($0.createdDate, inSameDayAs: selectedDate) }
        for block in existingBlocksForDay { modelContext.delete(block) }

        for (contextName, tasks) in nonEmptyContexts {
            if contextName == "Standalone" {
                for task in tasks { task.taskBlock = nil }
            } else if !tasks.isEmpty {
                let newBlock = TaskBlock(
                    id: UUID().uuidString,
                    userID: authService.currentUser?.uid ?? "",
                    title: contextName,
                    color: tasks.first?.category.rawValue ?? "blue",
                    priority: tasks.map { $0.priority }.max(by: { $0.rawValue < $1.rawValue }) ?? .normal
                )
                newBlock.createdDate = selectedDate
                modelContext.insert(newBlock)
                for task in tasks { task.taskBlock = newBlock }
            }
        }
        try? modelContext.save()
    }
    
    @ViewBuilder
    private func contextGroupView(
        contextName: String,
        tasks: [Task],
        theme: any AppTheme,
        onEditContext: @escaping (String) -> Void,
        onMoveTask: @escaping (Task, String) -> Void,
        onMakeStandalone: @escaping (Task) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EditableContextNameField(initialName: contextName, onEdit: onEditContext, theme: theme)
            ForEach(tasks) { task in
                HStack {
                    Image(systemName: "line.3.horizontal").foregroundColor(theme.textSecondary)
                    Text(task.title).font(theme.bodyFont).foregroundColor(theme.textPrimary)
                    Spacer()
                    Menu {
                        ForEach(Array(splitContextGroups.keys.sorted()), id: \.self) { targetContext in
                            if targetContext != contextName {
                                Button("Move to \(targetContext)") { onMoveTask(task, targetContext) }
                            }
                        }
                        Button("Make Standalone") { onMakeStandalone(task) }
                    } label: {
                        Image(systemName: "chevron.right").foregroundColor(theme.textSecondary)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: theme.smallCornerRadius).fill(theme.glassBackground.opacity(0.5)))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: theme.cardCornerRadius).fill(theme.glassBackground.opacity(0.3)).overlay(RoundedRectangle(cornerRadius: theme.cardCornerRadius).stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)))
    }

} // End of DynamicFocusBox

// MARK: - Editable Context Name Field (MOVED OUTSIDE)
private struct EditableContextNameField: View {
    let initialName: String
    let onEdit: (String) -> Void
    let theme: any AppTheme
    
    @State private var editableName: String
    
    init(initialName: String, onEdit: @escaping (String) -> Void, theme: any AppTheme) {
        self.initialName = initialName
        self.onEdit = onEdit
        self.theme = theme
        _editableName = State(initialValue: initialName)
    }
    
    var body: some View {
        HStack {
            TextField("Context name", text: $editableName)
                .font(theme.titleFont)
                .foregroundColor(theme.textPrimary)
                .textFieldStyle(.plain)
                .onSubmit { onEdit(editableName) }
            
            Spacer()
            
            Menu {
                Button("Rename", role: .none) { onEdit(editableName) }
                Button("Delete Context", role: .destructive) { onEdit("") }
            } label: {
                Image(systemName: "ellipsis")
            .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(theme.glassBackground.opacity(0.3))
        )
    }
}
