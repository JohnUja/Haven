//
//  ContinuousTimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import EventKit
import AudioToolbox

// MARK: - Custom Timeline Shape
struct TimelineShape: Shape {
    let pointsPerHour: CGFloat
    let textHeight: CGFloat
    let textPadding: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let totalTextGap = textHeight + textPadding
        let segmentHeight = (pointsPerHour - totalTextGap) / 2
        let x = rect.midX

        for hour in 0..<24 {
            let hourY = CGFloat(hour) * pointsPerHour
            
            // Top segment
            path.move(to: CGPoint(x: x, y: hourY))
            path.addLine(to: CGPoint(x: x, y: hourY + segmentHeight))
            
            // Bottom segment
            let bottomStart = hourY + segmentHeight + totalTextGap
            path.move(to: CGPoint(x: x, y: bottomStart))
            path.addLine(to: CGPoint(x: x, y: bottomStart + segmentHeight))
        }
        return path
    }
}

// MARK: - Main Timeline View
struct ContinuousTimelineView: View {
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager
    @Environment(ThemeManager.self) private var themeManager
    
    // Data Inputs
    let tasks: [Task]
    let taskBlocks: [TaskBlock]
    let calendarEvents: [EKEvent]
    let selectedDate: Date
    let currentTime: Date
    
    // OPTIMIZED: Pre-computed groups (optional - if provided, avoids O(N²) computation during render)
    // Note: Using TimelineItem from TimelineViewModel (shared enum)
    let workItemGroups: [[TimelineItem]]?
    let personalItemGroups: [[TimelineItem]]?
    
    // Closures
    let getTasksForBlock: (TaskBlock, Int) -> [Task]
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let getOverlappingTasks: ([Task]) -> [[Task]]
    let updateTaskTime: (Task, Date, Date) -> Void
    let updateTaskSide: (Task, TaskTimelineBlock.TimelineSide) -> Void
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Task, Date, Date) -> Void
    let viewMode: TimelineViewMode?
    
    enum TimelineViewMode {
        case collapsible
        case fullView
    }
    
    @Environment(\.modelContext) private var modelContext
    @State private var scrollOffset: CGFloat = 0
    @State private var isAnyTaskDragging: Bool = false
    @State private var showingTaskDetails: Task? = nil
    @State private var showingTaskBlockDetails: TaskBlock? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastHapticHour: Int = -1 // Debounce haptic feedback
    
    // Constants
    private let pointsPerHour: CGFloat = 120
    private let pointsPerMinute: CGFloat = 2
    private let totalHeight: CGFloat = 24 * 120
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // 1. Scroll Proxy Helper
                            Color.clear
                                .onAppear { scrollProxy = proxy }
                                .frame(height: 0)
                            
                            // 2. Touch Capture Layer
                            Color.clear
                                .frame(height: totalHeight)
                                .contentShape(Rectangle())
                                .allowsHitTesting(false)
                            
                            // 3. Background Lines
                            timelineBackground
                            
                            // 4. Dynamic Ticks
                            if isAnyTaskDragging {
                                dynamicTickMarks
                                    .frame(width: 60)
                                    .position(x: geometry.size.width / 2, y: totalHeight / 2)
                            }
                            
                            // 5. Optimized Task Layer
                            TimelineTaskLayer(
                                tasks: tasks,
                                taskBlocks: taskBlocks,
                                selectedDate: selectedDate,
                                totalHeight: totalHeight,
                                geometryWidth: geometry.size.width,
                                isAnyTaskDragging: $isAnyTaskDragging,
                                showingTaskDetails: $showingTaskDetails,
                                showingTaskBlockDetails: $showingTaskBlockDetails,
                                scrollProxy: scrollProxy,
                                workItemGroups: workItemGroups,
                                personalItemGroups: personalItemGroups,
                                getAllTasksForBlock: getAllTasksForBlock,
                                updateTaskTime: updateTaskTime,
                                updateTaskSide: updateTaskSide,
                                updateTaskBlockTime: updateTaskBlockTime,
                                updateTaskBlockSide: updateTaskBlockSide,
                                handleTaskCollision: handleTaskCollision
                            )
                            .id(selectedDate)
                            
                            // 6. Central Column
                            centralTimelineColumn
                                .frame(width: 60)
                                .position(x: geometry.size.width / 2, y: totalHeight / 2)
                        }
                        .frame(height: totalHeight)
                        .drawingGroup()
                    }
                    .coordinateSpace(name: "timeline")
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("timeline")).minY
                            )
                        }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // CRITICAL FIX: Infinite Loop Prevention - only update if change is significant
                        if abs(scrollOffset - value) > 2.0 {
                            handleScrollUpdate(oldValue: scrollOffset, newValue: value)
                            scrollOffset = value
                        }
                    }
                    .onAppear {
                        let hourToScroll = Calendar.current.component(.hour, from: Date())
                        proxy.scrollTo(max(0, hourToScroll - 1), anchor: .top)
                    }
                }
            }
        }
        .sheet(item: $showingTaskDetails) { task in
            NavigationStack {
                TimelineTaskDetailView(task: task, onSave: { [modelContext] updatedNotes in
                    // FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
                    task.taskDescription = updatedNotes.isEmpty ? nil : updatedNotes
                    _Concurrency.Task { @MainActor in
                        try? modelContext.save()
                    }
                    showingTaskDetails = nil
                }, onCancel: { showingTaskDetails = nil })
            }
            .presentationDetents([.medium, .large])
            .environmentObject(timeSettings)
            .environmentObject(calendarManager)
            .environment(themeManager)
            .environment(\.modelContext, modelContext)
        }
        .sheet(item: $showingTaskBlockDetails) { block in
            NavigationStack {
                TimelineTaskBlockDetailView(
                    taskBlock: block,
                    tasks: getAllTasksForBlock(block),
                    onDismiss: { showingTaskBlockDetails = nil }
                )
            }
            .presentationDetents([.medium, .large])
            .environmentObject(timeSettings)
            .environment(themeManager)
            .environment(\.modelContext, modelContext)
        }
    }
    
    // MARK: - Logic Helpers
    private func handleScrollUpdate(oldValue: CGFloat, newValue: CGFloat) {
        let currentHour = Int(abs(newValue) / 120)
        // Only play haptic if the hour actually changed and is valid
        if currentHour != lastHapticHour && currentHour >= 0 && currentHour < 24 {
            lastHapticHour = currentHour
            HapticSoundPlayer.shared.playTimePickerSound()
        }
    }
    
    private var timelineBackground: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: pointsPerHour)
            }
        }
    }
    
    private var centralTimelineColumn: some View {
        ZStack(alignment: .top) {
            ForEach(0..<24, id: \.self) { hour in
                Text(timeSettings.formatHour(hour))
                    .appTextStyle(.caption, theme: themeManager.currentTheme)
                    .id(hour)
                    .position(x: 30, y: CGFloat(hour) * pointsPerHour + 10)
            }
            if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
                let currentHour = Calendar.current.component(.hour, from: currentTime)
                let currentMinute = Calendar.current.component(.minute, from: currentTime)
                let currentPosition = CGFloat(currentHour) * pointsPerHour + CGFloat(currentMinute) * pointsPerMinute + 10
                TimelineTimeIndicatorView(
                    position: CGPoint(x: 30, y: currentPosition),
                    currentTime: currentTime
                )
                .environmentObject(timeSettings)
            }
        }
    }
    
    private var dynamicTickMarks: some View {
        let theme = themeManager.currentTheme
        let tickColor = theme.id == "light" ? Color.black.opacity(0.6) : Color.white.opacity(0.6)
        return ZStack(alignment: .topLeading) {
            ForEach(0..<24, id: \.self) { hour in
                ForEach([15, 30, 45], id: \.self) { minute in
                    Rectangle()
                        .fill(tickColor)
                        .frame(width: 8, height: 1)
                        .position(x: 30, y: CGFloat(hour) * pointsPerHour + CGFloat(minute) * pointsPerMinute + 10)
                }
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

// MARK: - OPTIMIZED TASK LAYER (EQUATABLE)
struct TimelineTaskLayer: View, Equatable {
    let tasks: [Task]
    let taskBlocks: [TaskBlock]
    let selectedDate: Date
    let totalHeight: CGFloat
    let geometryWidth: CGFloat
    @Binding var isAnyTaskDragging: Bool
    @Binding var showingTaskDetails: Task?
    @Binding var showingTaskBlockDetails: TaskBlock?
    let scrollProxy: ScrollViewProxy?
    
    // OPTIMIZED: Pre-computed groups (optional - if provided, avoids O(N²) computation during render)
    let workItemGroups: [[TimelineItem]]?
    let personalItemGroups: [[TimelineItem]]?
    
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let updateTaskTime: (Task, Date, Date) -> Void
    let updateTaskSide: (Task, TaskTimelineBlock.TimelineSide) -> Void
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Task, Date, Date) -> Void
    
    // Constants
    private let pointsPerHour: CGFloat = 120
    private let pointsPerMinute: CGFloat = 2
    
    static func == (lhs: TimelineTaskLayer, rhs: TimelineTaskLayer) -> Bool {
        // OPTIMIZED: Check most likely to change first, avoid expensive array comparisons if possible
        // If dragging state changed, we want to update (return false)
        if lhs.isAnyTaskDragging != rhs.isAnyTaskDragging {
            return false
        }
        // If date changed, we want to update
        if lhs.selectedDate != rhs.selectedDate {
            return false
        }
        // If geometry changed, we want to update
        if lhs.geometryWidth != rhs.geometryWidth {
            return false
        }
        // Only do expensive array comparisons if basic checks pass
        let lhsTaskIDs = lhs.tasks.map { $0.id }
        let rhsTaskIDs = rhs.tasks.map { $0.id }
        if lhsTaskIDs != rhsTaskIDs {
            return false
        }
        // Check start times only if IDs match (optimization)
        let lhsStartTimes = lhs.tasks.map { $0.startTime }
        let rhsStartTimes = rhs.tasks.map { $0.startTime }
        return lhsStartTimes == rhsStartTimes
    }
    
    var body: some View {
        let timelineWidth: CGFloat = 60
        let sideMargin: CGFloat = 10
        let centerX = geometryWidth / 2
        let sideWidth = (geometryWidth - timelineWidth - (sideMargin * 4)) / 2
        
        ZStack(alignment: .topLeading) {
            // Work Tasks (Left)
            renderTasks(for: .left, width: sideWidth)
                .frame(width: sideWidth, alignment: .trailing)
                .offset(x: sideMargin)
            
            // Personal Tasks (Right)
            renderTasks(for: .right, width: sideWidth)
                .frame(width: sideWidth, alignment: .leading)
                .offset(x: centerX + (timelineWidth / 2) + sideMargin)
        }
    }
    
    @ViewBuilder
    private func renderTasks(for side: TaskTimelineBlock.TimelineSide, width: CGFloat) -> some View {
        // OPTIMIZED: Use pre-computed groups if available, otherwise compute (backward compatible)
        // Compute groups outside @ViewBuilder context
        let groups: [[TimelineItem]] = {
            if let precomputedGroups = side == .left ? workItemGroups : personalItemGroups {
                return precomputedGroups
            } else {
                // Fallback: compute groups (for backward compatibility)
                let items = getItems(for: side)
                return groupOverlappingItems(items)
            }
        }()
        
        ZStack(alignment: .topLeading) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                HStack(spacing: 2) {
                    let count = group.count
                    ForEach(0..<min(count, 3), id: \.self) { idx in
                        itemView(for: group[idx], side: side, groupCount: count)
                    }
                }
                .frame(width: width, alignment: side == .left ? .trailing : .leading)
            }
        }
    }
    
    private func getItems(for side: TaskTimelineBlock.TimelineSide) -> [TimelineItem] {
        let filteredTasks = tasks.filter { task in
            guard task.taskBlock == nil else { return false }
            if side == .left {
                return task.category == .work || task.category == .fixed || task.category == .growth || task.category == .reading
            } else {
                return task.category == .personal || task.category == .flexible || task.category == .hobbies || task.category == .selfCare || task.category == .leisure || task.category == .skinCare
            }
        }
        
        let filteredBlocks = taskBlocks.filter { block in
            let blockTasks = getAllTasksForBlock(block)
            return blockTasks.contains { task in
                if side == .left {
                    return task.category == .work || task.category == .fixed || task.category == .growth || task.category == .reading
                } else {
                    return task.category == .personal || task.category == .flexible || task.category == .hobbies || task.category == .selfCare || task.category == .leisure || task.category == .skinCare
                }
            }
        }
        return filteredTasks.map { TimelineItem.task($0) } + filteredBlocks.map { TimelineItem.block($0) }
    }
    
    private func groupOverlappingItems(_ items: [TimelineItem]) -> [[TimelineItem]] {
        guard !items.isEmpty else { return [] }
        let sortedItems = items.sorted { itemStart($0) < itemStart($1) }
        var groups: [[TimelineItem]] = []
        
        for item in sortedItems {
            var placed = false
            for i in 0..<groups.count {
                if groups[i].contains(where: { itemsOverlap(item, $0) }) {
                    groups[i].append(item)
                    placed = true
                    break
                }
            }
            if !placed { groups.append([item]) }
        }
        return groups
    }
    
    private func itemsOverlap(_ item1: TimelineItem, _ item2: TimelineItem) -> Bool {
        return itemStart(item1) < itemEnd(item2) && itemStart(item2) < itemEnd(item1)
    }
    
    private func itemStart(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.startTime
        case .block(let b):
            let tasks = getAllTasksForBlock(b)
            return tasks.map { $0.startTime }.min() ?? Date()
        }
    }
    
    private func itemEnd(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.endTime
        case .block(let b):
            let tasks = getAllTasksForBlock(b)
            return tasks.map { $0.endTime }.max() ?? Date()
        }
    }
    
    @ViewBuilder
    private func itemView(for item: TimelineItem, side: TaskTimelineBlock.TimelineSide, groupCount: Int) -> some View {
        switch item {
        case .task(let task):
            let start = task.startTime
            let end = task.endTime
            let hour = Calendar.current.component(.hour, from: start)
            let minute = Calendar.current.component(.minute, from: start)
            let yPos = CGFloat(hour) * pointsPerHour + CGFloat(minute) * pointsPerMinute + 10
            let height = max(20, CGFloat(end.timeIntervalSince(start) / 60) * 2)
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskTimelineBlock(task: task, side: side).frame(height: height)
                },
                side: side,
                isLocked: task.isLocked,
                startTime: start,
                endTime: end,
                onTimeChanged: { s, e in updateTaskTime(task, s, e) },
                onSideChanged: { s in updateTaskSide(task, s) },
                onTaskCollision: { s, e in handleTaskCollision(task, s, e) },
                onDragStateChanged: { dragging in isAnyTaskDragging = dragging },
                onTap: { showingTaskDetails = task },
                onScrollRequest: { dir in handleScrollRequest(direction: dir) }
            )
            .frame(maxWidth: groupCount == 1 ? .infinity : nil)
            .frame(width: groupCount > 1 ? (UIScreen.main.bounds.width * 0.35) / CGFloat(min(groupCount, 3)) : nil)
            .offset(y: yPos)
            
        case .block(let block):
            let tasks = getAllTasksForBlock(block)
            let start = tasks.map { $0.startTime }.min() ?? Date()
            let end = tasks.map { $0.endTime }.max() ?? Date()
            let hour = Calendar.current.component(.hour, from: start)
            let minute = Calendar.current.component(.minute, from: start)
            let yPos = CGFloat(hour) * pointsPerHour + CGFloat(minute) * pointsPerMinute + 10
            let height = max(20, CGFloat(end.timeIntervalSince(start) / 60) * 2)
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskBlockTimelineView(taskBlock: block, tasks: tasks, side: side).frame(height: height)
                },
                side: side,
                isLocked: block.isLocked,
                startTime: start,
                endTime: end,
                onTimeChanged: { s, e in updateTaskBlockTime(block, s, e) },
                onSideChanged: { s in updateTaskBlockSide(block, s) },
                onTaskCollision: { s, e in
                    if let first = tasks.first { handleTaskCollision(first, s, e) }
                },
                onDragStateChanged: { dragging in isAnyTaskDragging = dragging },
                onTap: { showingTaskBlockDetails = block },
                onScrollRequest: { dir in handleScrollRequest(direction: dir) }
            )
            .frame(maxWidth: groupCount == 1 ? .infinity : nil)
            .frame(width: groupCount > 1 ? (UIScreen.main.bounds.width * 0.35) / CGFloat(min(groupCount, 3)) : nil)
            .offset(y: yPos)
        }
    }
    
    private func handleScrollRequest(direction: TimelineScrollDirection) {
        guard let proxy = scrollProxy else { return }
        let scrollAmount: CGFloat = 60
        switch direction {
        case .up:
            // This is a simplified handler since Equatable prevents reading live offset
            break
        case .down:
            break
        case .none:
            break
        }
    }
    
    // OPTIMIZED: Use shared TimelineItem enum from TimelineViewModel instead of local enum
    // This allows us to use pre-computed groups from ViewModel
    // private enum TimelineItem { ... } - REMOVED, using TimelineItem from TimelineViewModel
} // <--- THIS WAS THE MISSING BRACE

// MARK: - Helper Views
struct WorkTaskBlockView: View {
    let taskBlock: TaskBlock
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Task, Date, Date) -> Void
    let taskPosition: (Date) -> CGFloat
    let taskHeight: (Date, Date) -> CGFloat
    let onDragStateChanged: (Bool) -> Void
    let onBlockTap: (TaskBlock) -> Void
    
    // @ViewBuilder is required here because you use 'if let' at top level
    @ViewBuilder
    var body: some View {
        let blockTasks = getAllTasksForBlock(taskBlock).filter { task in
            task.category == .work || task.category == .fixed ||
            task.category == .growth || task.category == .reading
        }
        
        if let firstTask = blockTasks.sorted(by: { $0.startTime < $1.startTime }).first,
           let lastTask = blockTasks.sorted(by: { $0.endTime < $1.endTime }).last {
            let position = taskPosition(firstTask.startTime)
            let height = taskHeight(firstTask.startTime, lastTask.endTime)
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskBlockTimelineView(
                        taskBlock: taskBlock,
                        tasks: blockTasks,
                        side: .left
                    )
                    .frame(height: height)
                },
                side: .left,
                isLocked: taskBlock.isLocked,
                startTime: firstTask.startTime,
                endTime: lastTask.endTime,
                onTimeChanged: { newStart, newEnd in
                    updateTaskBlockTime(taskBlock, newStart, newEnd)
                },
                onSideChanged: { newSide in
                    updateTaskBlockSide(taskBlock, newSide)
                },
                onTaskCollision: { newStart, newEnd in
                    handleTaskCollision(firstTask, newStart, newEnd)
                },
                onDragStateChanged: { dragging in
                    onDragStateChanged(dragging)
                },
                onTap: { onBlockTap(taskBlock) }
            )
            .offset(y: position)
        }
    }
}

struct PersonalTaskBlockView: View {
    let taskBlock: TaskBlock
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Task, Date, Date) -> Void
    let taskPosition: (Date) -> CGFloat
    let taskHeight: (Date, Date) -> CGFloat
    let onDragStateChanged: (Bool) -> Void
    let onBlockTap: (TaskBlock) -> Void
    
    @ViewBuilder
    var body: some View {
        let blockTasks = getAllTasksForBlock(taskBlock).filter { task in
            task.category == .personal || task.category == .flexible ||
            task.category == .hobbies || task.category == .selfCare ||
            task.category == .leisure || task.category == .skinCare
        }
        
        if let firstTask = blockTasks.sorted(by: { $0.startTime < $1.startTime }).first,
           let lastTask = blockTasks.sorted(by: { $0.endTime < $1.endTime }).last {
            let position = taskPosition(firstTask.startTime)
            let height = taskHeight(firstTask.startTime, lastTask.endTime)
            
            UnifiedDraggableTimelineItem(
                content: {
                    TaskBlockTimelineView(
                        taskBlock: taskBlock,
                        tasks: blockTasks,
                        side: .right
                    )
                    .frame(height: height)
                },
                side: .right,
                isLocked: taskBlock.isLocked,
                startTime: firstTask.startTime,
                endTime: lastTask.endTime,
                onTimeChanged: { newStart, newEnd in
                    updateTaskBlockTime(taskBlock, newStart, newEnd)
                },
                onSideChanged: { newSide in
                    updateTaskBlockSide(taskBlock, newSide)
                },
                onTaskCollision: { newStart, newEnd in
                    handleTaskCollision(firstTask, newStart, newEnd)
                },
                onDragStateChanged: { dragging in
                    onDragStateChanged(dragging)
                },
                onTap: { onBlockTap(taskBlock) }
            )
            .offset(y: position)
        }
    }
}

// MARK: - Task Overlap Alert
struct TaskOverlapAlertView: View {
    let taskCount: Int
    let position: CGFloat
    let onCreateBlock: () -> Void
    @State private var showAlert = true
    @State private var undoTimer: Timer?
    
    var body: some View {
        if showAlert {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    
                    Text("\(taskCount) Tasks Overlap")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Create a Task Block?")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showAlert = false
                        }
                        onCreateBlock()
                        startUndoTimer()
                    }) {
                        Text("Create Block")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                            )
                    }
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showAlert = false
                        }
                    }) {
                        Text("Keep Separate")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(999)
            .offset(y: position - 50)
            .onDisappear {
                // Ensure timer is invalidated when view disappears
                undoTimer?.invalidate()
                undoTimer = nil
            }
        }
    }
    
    private func startUndoTimer() {
        // FIX: Cancel existing timer before creating new one
        undoTimer?.invalidate()
        // Note: TaskOverlapAlertView is a struct (value type), so no need for [weak self]
        // Structs don't have retain cycles. The timer will be invalidated in onDisappear.
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            print("Block creation confirmed")
        }
    }
}

// ScrollOffsetPreferenceKey is defined in InfiniteDaySelector.swift

// MARK: - Timeline Task Detail View
struct TimelineTaskDetailView: View {
    let task: Task
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var notes: String
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager
    @Environment(\.modelContext) private var modelContext
    
    init(task: Task, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onCancel = onCancel
        self._notes = State(initialValue: task.taskDescription ?? "")
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Task Info") {
                    let theme = themeManager.currentTheme
                    
                    HStack {
                        Text("Title").foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(task.title).foregroundColor(theme.textPrimary)
                    }
                    
                    HStack {
                        Text("Time").foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    HStack {
                        Text("Category").foregroundColor(theme.textSecondary)
                        Spacer()
                        HStack {
                            Image(systemName: task.category.icon).foregroundColor(task.category.color())
                            Text(task.category.displayName).foregroundColor(theme.textPrimary)
                        }
                    }
                    
                    HStack {
                        Text("Priority").foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(task.priority.rawValue.capitalized).foregroundColor(theme.textSecondary)
                    }
                    
                    HStack {
                        Image(systemName: task.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(task.isLocked ? .orange : .green)
                        Text(task.isLocked ? "Task is Locked" : "Task is Unlocked")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Button(action: {
                            // FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
                            task.isLocked.toggle()
                            _Concurrency.Task { @MainActor in
                                try? modelContext.save()
                            }
                        }) {
                            Text(task.isLocked ? "Unlock" : "Lock").foregroundColor(theme.accentColor)
                        }
                    }
                }
                
                Section("Notes") {
                    // Assuming transparentTextEditor exists elsewhere in your project
                    TextEditor(text: $notes)
                        .frame(minHeight: 150)
                }
                
                Section("Calendar") {
                    Button(action: {
                        calendarManager.addTaskToCalendar(task: task)
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Calendar")
                        }
                    }
                    
                    if calendarManager.isAuthorized {
                        Button(action: {
                            calendarManager.syncTaskWithCalendar(task: task)
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Sync with Calendar")
                            }
                        }
                    } else {
                        Button(action: {
                            calendarManager.requestAccess()
                        }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("Enable Calendar Access")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave(notes) }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Timeline Task Block Detail View
struct TimelineTaskBlockDetailView: View {
    let taskBlock: TaskBlock
    let tasks: [Task]
    let onDismiss: () -> Void
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @Environment(\.modelContext) private var modelContext
    @State private var notes: String = ""

    init(taskBlock: TaskBlock, tasks: [Task], onDismiss: @escaping () -> Void) {
        self.taskBlock = taskBlock
        self.tasks = tasks
        self.onDismiss = onDismiss
        self._notes = State(initialValue: taskBlock.blockDescription ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Block") {
                    let theme = themeManager.currentTheme
                    let isDarkMode = theme.id == "dark" || theme.id == "purple"
                    
                    HStack {
                        Text("Title").foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(taskBlock.title).foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                    HStack {
                        Text("Priority").foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(taskBlock.priority.rawValue.capitalized)
                            .foregroundColor(isDarkMode ? theme.textSecondary : blockPriorityColor)
                    }
                    HStack {
                        Text("Tasks in Block").foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text("\(tasks.count)").foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 150)
                }

                Section("Tasks") {
                    let theme = themeManager.currentTheme
                    let isDarkMode = theme.id == "dark" || theme.id == "purple"
                    
                    ForEach(tasks, id: \.id) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                            Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                                .font(.caption)
                                .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Task Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        taskBlock.blockDescription = notes.isEmpty ? nil : notes
                        try? modelContext.save()
                        onDismiss()
                    }
                }
            }
        }
    }

    private var blockPriorityColor: Color {
        switch taskBlock.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
}
