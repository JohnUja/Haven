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

// MARK: - Custom Timeline Shape for Pixel-Perfect Rendering
struct TimelineShape: Shape {
    let pointsPerHour: CGFloat
    let textHeight: CGFloat // The height of your hour text (e.g., 12)
    let textPadding: CGFloat // The empty space above/below the text (e.g., 4)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // --- Calculate the geometry for the line breaks ---
        
        // This is the total empty space for the text
        let totalTextGap = textHeight + textPadding 
        
        // This is the height of the line *above* and *below* the text
        // (120 - 16) / 2 = 52 points
        let segmentHeight = (pointsPerHour - totalTextGap) / 2
        
        // This is the x-coordinate for our vertical line
        let x = rect.midX

        // Loop 24 times (00:00 to 23:00)
        for hour in 0..<24 {
            let hourY = CGFloat(hour) * pointsPerHour
            
            // --- 1. Draw TOP line segment ---
            let topSegmentStartY = hourY
            let topSegmentEndY = hourY + segmentHeight
            
            path.move(to: CGPoint(x: x, y: topSegmentStartY))
            path.addLine(to: CGPoint(x: x, y: topSegmentEndY))
            
            // --- 2. Draw BOTTOM line segment ---
            // (We skip over the totalTextGap)
            let bottomSegmentStartY = topSegmentEndY + totalTextGap
            let bottomSegmentEndY = bottomSegmentStartY + segmentHeight
            
            path.move(to: CGPoint(x: x, y: bottomSegmentStartY))
            path.addLine(to: CGPoint(x: x, y: bottomSegmentEndY))
        }
        
        return path
    }
}

struct ContinuousTimelineView: View {
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @Environment(ThemeManager.self) private var themeManager
    let tasks: [Task]
    let taskBlocks: [TaskBlock]
    let calendarEvents: [EKEvent]
    let selectedDate: Date
    let currentTime: Date
    let getTasksForBlock: (TaskBlock, Int) -> [Task]
    let getAllTasksForBlock: (TaskBlock) -> [Task]
    let getOverlappingTasks: ([Task]) -> [[Task]]
    let updateTaskTime: (Task, Date, Date) -> Void
    let updateTaskSide: (Task, TaskTimelineBlock.TimelineSide) -> Void
    let updateTaskBlockTime: (TaskBlock, Date, Date) -> Void
    let updateTaskBlockSide: (TaskBlock, TaskTimelineBlock.TimelineSide) -> Void
    let handleTaskCollision: (Task, Date, Date) -> Void
    let viewMode: TimelineViewMode? // Optional view mode for collapse/expand
    
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
    
    // Timeline constants
    private let pointsPerHour: CGFloat = 120
    private let pointsPerMinute: CGFloat = 2
    private let totalHeight: CGFloat = 24 * 120 // 2880 points for 24 hours
    private let hourTextHeight: CGFloat = 12 // The font size
    private let hourTextPadding: CGFloat = 4  // The gap above/below text
    
    // Helper to get adjusted display times for day-spanning tasks
    private func getAdjustedDisplayTimes(for task: Task) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let taskStart = task.startTime
        let taskEnd = task.endTime
        let taskStartDay = calendar.startOfDay(for: taskStart)
        let taskEndDay = calendar.startOfDay(for: taskEnd)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
        let endOfSelectedDay = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDay) ?? startOfSelectedDay
        
        // If task starts on a previous day but ends on or after selected day
        if taskStartDay < selectedDay && taskEndDay >= selectedDay {
            // Show continuation from 12:00 AM on selected day
            let displayStart = startOfSelectedDay
            // Keep original end time if it's on selected day, otherwise show to end of day
            let displayEnd = taskEndDay > selectedDay ? endOfSelectedDay : taskEnd
            return (displayStart, displayEnd)
        }
        // If task starts on selected day but ends on next day
        else if taskStartDay == selectedDay && taskEndDay > selectedDay {
            // Show from start time to end of selected day (midnight)
            return (taskStart, endOfSelectedDay)
        }
        // Otherwise, task is fully on selected day - no adjustment needed
        else {
            return (taskStart, taskEnd)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Continuous timeline - single column view
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // Store proxy for scroll-on-hover
                            Color.clear
                                .onAppear {
                                    scrollProxy = proxy
                                }
                                .id("scrollProxy")
                                .zIndex(-2)
                            // Invisible background to ensure scrolling works even when starting from task area
                            // This layer captures scroll gestures even when starting from task areas
                            Color.clear
                                .frame(height: totalHeight)
                                .contentShape(Rectangle())
                                .allowsHitTesting(false) // Don't interfere with scroll gestures
                                .zIndex(-1)
                            // Timeline background with hour markers
                            timelineBackground
                            
                            // Calculate proper spacing for perfect centering
                            let timelineWidth: CGFloat = 60
                            let sideMargin: CGFloat = 10
                            let centerX = geometry.size.width / 2
                            let sideWidth = (geometry.size.width - timelineWidth - (sideMargin * 4)) / 2
                            
                            // Work tasks (left side) - aligned to right edge before timeline
                            workTasksAbsoluteView
                                .frame(width: sideWidth, alignment: .trailing)
                                .offset(x: sideMargin)
                            
                            // Central timeline with integrated hour labels - perfectly centered
                            centralTimelineColumn
                                .frame(width: timelineWidth)
                                .offset(x: centerX - (timelineWidth / 2))
                            
                            // Dynamic elements - Only 15, 30, 45 minute ticks when dragging
                            if isAnyTaskDragging {
                                // Dynamic tick marks (15, 30, 45 min) - NO hour marks
                                dynamicTickMarks
                                    .frame(width: timelineWidth)
                                    .offset(x: centerX - (timelineWidth / 2))
                            }
                            
                            // Personal tasks (right side) - aligned to left edge after timeline
                            personalTasksAbsoluteView
                                .frame(width: sideWidth, alignment: .leading)
                                .offset(x: centerX + (timelineWidth / 2) + sideMargin)
                        }
                        .frame(height: totalHeight)
                        .drawingGroup() // Performance optimization
                    }
                    .coordinateSpace(name: "timeline")
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("timeline")).minY)
                        }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let previousOffset = scrollOffset
                        scrollOffset = value
                        
                        // Metallic clicking haptic feedback on scroll (like Clock app timer wheel)
                        // Trigger when scrolling past hour markers (every 120 points)
                        let previousHour = Int(previousOffset / 120)
                        let currentHour = Int(value / 120)
                        
                        if previousHour != currentHour && currentHour >= 0 && currentHour < 24 {
                            HapticSoundPlayer.shared.playTimePickerSound()
                        }
                    }
                    .onAppear {
                        // Ensure timeline starts at 00:00
                        proxy.scrollTo(0, anchor: .top)
                    }
                }
            }
        }
        .sheet(item: $showingTaskDetails) { task in
            TimelineTaskDetailView(task: task, onSave: { updatedNotes in
                task.taskDescription = updatedNotes.isEmpty ? nil : updatedNotes
                try? modelContext.save()
                showingTaskDetails = nil
            }, onCancel: {
                showingTaskDetails = nil
            })
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $showingTaskBlockDetails) { block in
            TimelineTaskBlockDetailView(
                taskBlock: block,
                tasks: getAllTasksForBlock(block),
                onDismiss: { showingTaskBlockDetails = nil }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Timeline Background
    private var timelineBackground: some View {
        VStack(spacing: 0) {
            // In collapsible mode, only show hours with tasks
            let hoursToShow: [Int] = {
                if viewMode == .collapsible {
                    var hoursWithTasks: Set<Int> = []
                    let calendar = Calendar.current
                    for task in tasks {
                        let hour = calendar.component(.hour, from: task.startTime)
                        hoursWithTasks.insert(hour)
                        let endHour = calendar.component(.hour, from: task.endTime)
                        if endHour != hour {
                            hoursWithTasks.insert(endHour)
                        }
                    }
                    for block in taskBlocks {
                        let blockTasks = getAllTasksForBlock(block)
                        for task in blockTasks {
                            let hour = calendar.component(.hour, from: task.startTime)
                            hoursWithTasks.insert(hour)
                            let endHour = calendar.component(.hour, from: task.endTime)
                            if endHour != hour {
                                hoursWithTasks.insert(endHour)
                            }
                        }
                    }
                    return Array(hoursWithTasks).sorted()
                } else {
                    return Array(0..<24)
                }
            }()
            
            ForEach(hoursToShow, id: \.self) { hour in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: pointsPerHour)
            }
        }
    }
    
    // MARK: - Central Timeline Column (NO LINE - Only Hour Labels)
    private var centralTimelineColumn: some View {
        ZStack(alignment: .topLeading) {
            // NO CONTINUOUS LINE - Only hour labels positioned at exact hour positions
            // Each hour needs an ID for ScrollViewReader
            // In collapsible mode, only show hours with tasks
            let hoursToShow: [Int] = {
                if viewMode == .collapsible {
                    // Get hours that have tasks
                    var hoursWithTasks: Set<Int> = []
                    let calendar = Calendar.current
                    for task in tasks {
                        let hour = calendar.component(.hour, from: task.startTime)
                        hoursWithTasks.insert(hour)
                        let endHour = calendar.component(.hour, from: task.endTime)
                        if endHour != hour {
                            hoursWithTasks.insert(endHour)
                        }
                    }
                    for block in taskBlocks {
                        let blockTasks = getAllTasksForBlock(block)
                        for task in blockTasks {
                            let hour = calendar.component(.hour, from: task.startTime)
                            hoursWithTasks.insert(hour)
                            let endHour = calendar.component(.hour, from: task.endTime)
                            if endHour != hour {
                                hoursWithTasks.insert(endHour)
                            }
                        }
                    }
                    return Array(hoursWithTasks).sorted()
                } else {
                    // Full view: show all 24 hours
                    return Array(0..<24)
                }
            }()
            
            ForEach(hoursToShow, id: \.self) { hour in
                Text(timeSettings.formatHour(hour))
                    .appTextStyle(.caption, theme: themeManager.currentTheme)
                    .id(hour) // Add ID for scroll targeting
                    .position(
                        x: 30, // Center of timeline
                        y: CGFloat(hour) * pointsPerHour + 10 // Hour position + small offset
                    )
            }
            
            // Current time indicator (if today) - positioned on the timeline with green pulsing ring
            if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
                let currentHour = Calendar.current.component(.hour, from: currentTime)
                let currentMinute = Calendar.current.component(.minute, from: currentTime)
                let currentPosition = CGFloat(currentHour) * pointsPerHour + CGFloat(currentMinute) * pointsPerMinute + 10 // Match hour label offset
                
                TimelineTimeIndicatorView(
                    position: CGPoint(x: 30, y: currentPosition),
                    currentTime: currentTime
                )
                .environmentObject(timeSettings)
            }
        }
        .frame(width: 60, height: totalHeight)
    }
    
    // MARK: - Dynamic Tick Marks (15, 30, 45 min ONLY - No Hour Marks)
    private var dynamicTickMarks: some View {
        let theme = themeManager.currentTheme
        // Rule indicator intervals: black/dark grey for light mode, light for purple/dark themes
        let tickColor: Color = {
            switch theme.id {
            case "light":
                return Color.black.opacity(0.6)
            default:
                return Color.white.opacity(0.6)
            }
        }()
        
        return ZStack(alignment: .topLeading) {
            ForEach(0..<24, id: \.self) { hour in
                ForEach([15, 30, 45], id: \.self) { minute in
                    Rectangle()
                        .fill(tickColor)
                        .frame(width: 8, height: 1)
                        .position(
                            x: 30, // Center of 60pt timeline
                            y: CGFloat(hour) * pointsPerHour + CGFloat(minute) * pointsPerMinute + 10
                        )
                }
            }
        }
        .frame(width: 60, height: totalHeight)
        .allowsHitTesting(false)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isAnyTaskDragging)
    }
    
    // MARK: - Dynamic Guidelines (5-minute intervals) - Top-Leading Coordinates
    private var dynamicGuidelines: some View {
        ZStack(alignment: .topLeading) {
            // Draw 5-minute interval guidelines for all 24 hours (288 intervals)
            ForEach(0..<288, id: \.self) { interval in
                let minute = (interval * 5) % 60
                let hour = interval / 12
                let isMajorMark = minute % 15 == 0
                
                // Skip hour marks (0 minutes) to avoid overlap with time labels
                if minute != 0 {
                    Rectangle()
                        .fill(Color.white.opacity(isMajorMark ? 0.7 : 0.35))
                        .frame(width: isMajorMark ? 14 : 10, height: isMajorMark ? 2 : 1)
                        .position(
                            x: 30, // Center of 60pt timeline
                            y: CGFloat(hour) * 120 + CGFloat(minute) * 2
                        )
                }
            }
        }
        .frame(width: 60, height: totalHeight)
        .allowsHitTesting(false)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isAnyTaskDragging)
    }
    
    // MARK: - Work Tasks Absolute View
    private var workTasksAbsoluteView: some View {
        ZStack(alignment: .topLeading) {
            let workTaskItems = workTasks.map { TimelineItem.task($0) }
            let workBlockItems = workTaskBlocks.map { TimelineItem.block($0) }
            let workItems: [TimelineItem] = workTaskItems + workBlockItems
            let itemGroups: [[TimelineItem]] = groupOverlappingItems(workItems)

            ForEach(Array(itemGroups.enumerated()), id: \.offset) { _, group in
                HStack(spacing: 2) {
                    let count = group.count
                    ForEach(0..<min(count, 3), id: \.self) { idx in
                        let item = group[idx]
                        itemView(for: item, side: .left, groupCount: count)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Personal Tasks Absolute View
    private var personalTasksAbsoluteView: some View {
        ZStack(alignment: .topLeading) {
            let personalTaskItems = personalTasks.map { TimelineItem.task($0) }
            let personalBlockItems = personalTaskBlocks.map { TimelineItem.block($0) }
            let personalItems: [TimelineItem] = personalTaskItems + personalBlockItems
            let itemGroups: [[TimelineItem]] = groupOverlappingItems(personalItems)

            ForEach(Array(itemGroups.enumerated()), id: \.offset) { _, group in
                HStack(spacing: 2) {
                    let count = group.count
                    ForEach(0..<min(count, 3), id: \.self) { idx in
                        let item = group[idx]
                        itemView(for: item, side: .right, groupCount: count)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Helper Functions
    private enum TimelineItem {
        case task(Task)
        case block(TaskBlock)
    }

    private func itemStart(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.startTime
        case .block(let b): return getTaskBlockStartTime(b)
        }
    }

    private func itemEnd(_ item: TimelineItem) -> Date {
        switch item {
        case .task(let t): return t.endTime
        case .block(let b): return getTaskBlockEndTime(b)
        }
    }

    private func groupOverlappingItems(_ items: [TimelineItem]) -> [[TimelineItem]] {
        var groups: [[TimelineItem]] = []
        for item in items {
            var placed = false
            for i in 0..<groups.count {
                // Check if item overlaps with any item in this group
                if groups[i].contains(where: { itemStart(item) < itemEnd($0) && itemStart($0) < itemEnd(item) }) {
                    groups[i].append(item)
                    placed = true
                    break
                }
            }
            if !placed { groups.append([item]) }
        }
        
        // Sort items within each group by priority (highest first) then by start time
        for i in 0..<groups.count {
            groups[i].sort { item1, item2 in
                let priority1 = getItemPriority(item1)
                let priority2 = getItemPriority(item2)
                if priority1 != priority2 {
                    return priority1 > priority2 // Higher priority first
                }
                return itemStart(item1) < itemStart(item2) // Then by start time
            }
        }
        
        return groups
    }
    
    // Helper to get priority for an item (for grouping)
    private func getItemPriority(_ item: TimelineItem) -> Int {
        switch item {
        case .task(let task):
            switch task.priority {
            case .urgent: return 4
            case .high: return 3
            case .normal: return 2
            case .low: return 1
            }
        case .block(let block):
            // Get highest priority from tasks in block
            let blockTasks = getAllTasksForBlock(block)
            let priorities = blockTasks.map { task in
                switch task.priority {
                case .urgent: return 4
                case .high: return 3
                case .normal: return 2
                case .low: return 1
                }
            }
            return priorities.max() ?? 1
        }
    }
    
    // MARK: - Scroll-on-Hover Handler
    private func handleScrollRequest(direction: TimelineScrollDirection) {
        guard let proxy = scrollProxy else { return }
        
        let scrollAmount: CGFloat = 60 // Scroll 60 points (30 minutes) per request
        let currentOffset = abs(scrollOffset) // Use absolute value
        
        switch direction {
        case .up:
            // Scroll up (earlier time) - scroll to a point earlier in the timeline
            let newOffset = max(0, currentOffset - scrollAmount)
            // Convert offset to hour position for scrolling
            let targetHour = Int(newOffset / pointsPerHour)
            withAnimation(.linear(duration: 0.05)) {
                proxy.scrollTo(targetHour, anchor: .top)
            }
        case .down:
            // Scroll down (later time) - scroll to a point later in the timeline
            let newOffset = min(totalHeight, currentOffset + scrollAmount)
            // Convert offset to hour position for scrolling
            let targetHour = min(23, Int(newOffset / pointsPerHour))
            withAnimation(.linear(duration: 0.05)) {
                proxy.scrollTo(targetHour, anchor: .top)
            }
        case .none:
            break
        }
    }

    private func tasksForBlockBySide(_ block: TaskBlock, side: TaskTimelineBlock.TimelineSide) -> [Task] {
        let all = getAllTasksForBlock(block)
        switch side {
        case .left:
            return all.filter { $0.category == .work || $0.category == .fixed || $0.category == .growth || $0.category == .reading }
        case .right:
            return all.filter { $0.category == .personal || $0.category == .flexible || $0.category == .hobbies || $0.category == .selfCare || $0.category == .leisure || $0.category == .skinCare }
        }
    }

    @ViewBuilder
    private func itemView(for item: TimelineItem, side: TaskTimelineBlock.TimelineSide, groupCount: Int) -> some View {
        switch item {
        case .task(let task):
            // Get adjusted display times for day-spanning tasks
            let (start, end) = getAdjustedDisplayTimes(for: task)
            let height = taskHeight(from: start, to: end)
            UnifiedDraggableTimelineItem(
                content: {
                    TaskTimelineBlock(task: task, side: side)
                        .frame(height: height)
                },
                side: side,
                isLocked: task.isLocked,
                startTime: start,
                endTime: end,
                onTimeChanged: { newStart, newEnd in
                    updateTaskTime(task, newStart, newEnd)
                },
                onSideChanged: { newSide in
                    updateTaskSide(task, newSide)
                },
                onTaskCollision: { newStart, newEnd in
                    handleTaskCollision(task, newStart, newEnd)
                },
                onDragStateChanged: { dragging in
                    isAnyTaskDragging = dragging
                },
                onTap: { showingTaskDetails = task },
                onScrollRequest: { direction in
                    handleScrollRequest(direction: direction)
                }
            )
            .frame(maxWidth: groupCount == 1 ? .infinity : nil)
            .frame(width: groupCount > 1 ? (UIScreen.main.bounds.width * 0.35) / CGFloat(min(groupCount, 3)) : nil)
            .offset(y: taskPosition(for: start))

        case .block(let block):
            let all = tasksForBlockBySide(block, side: side)
            if let first = all.sorted(by: { $0.startTime < $1.startTime }).first,
               let last = all.sorted(by: { $0.endTime < $1.endTime }).last {
                let start = first.startTime
                let end = last.endTime
                let height = taskHeight(from: start, to: end)
                UnifiedDraggableTimelineItem(
                    content: {
                        TaskBlockTimelineView(taskBlock: block, tasks: all, side: side)
                            .frame(height: height)
                            .overlay(
                                Group {
                                    if block.isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Circle().fill(Color.black.opacity(0.7)))
                                            .offset(x: 60, y: -60)
                                    }
                                }, alignment: .topTrailing
                            )
                            .overlay(
                                Group {
                                    if block.isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Circle().fill(Color.black.opacity(0.7)))
                                            .offset(x: 60, y: -60)
                                    }
                                }, alignment: .topTrailing
                            )
                    },
                    side: side,
                    isLocked: block.isLocked,
                    startTime: start,
                    endTime: end,
                    onTimeChanged: { newStart, newEnd in
                        updateTaskBlockTime(block, newStart, newEnd)
                    },
                    onSideChanged: { newSide in
                        updateTaskBlockSide(block, newSide)
                    },
                    onTaskCollision: { newStart, newEnd in
                        // For task blocks, we don't have a single task, so we'll use the first task in the block
                        if let firstTask = getAllTasksForBlock(block).first {
                            handleTaskCollision(firstTask, newStart, newEnd)
                        }
                    },
                    onDragStateChanged: { dragging in
                        isAnyTaskDragging = dragging
                    },
                    onTap: { showingTaskBlockDetails = block },
                    onScrollRequest: { direction in
                        handleScrollRequest(direction: direction)
                    }
                )
                .frame(maxWidth: groupCount == 1 ? .infinity : nil)
                .frame(width: groupCount > 1 ? (UIScreen.main.bounds.width * 0.35) / CGFloat(min(groupCount, 3)) : nil)
                .offset(y: taskPosition(for: start))
            }
        }
    }
    private func taskPosition(for date: Date) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        // Center tasks on hour labels: match the +10 offset from hour labels
        return CGFloat(hour) * pointsPerHour + CGFloat(minute) * pointsPerMinute + 10
    }
    
    private func taskHeight(from startDate: Date, to endDate: Date) -> CGFloat {
        let duration = endDate.timeIntervalSince(startDate)
        let minutes = duration / 60
        return max(20, CGFloat(minutes) * pointsPerMinute)
    }
    
    // MARK: - Task Block Overlap Helpers
    private func getTaskBlockStartTime(_ taskBlock: TaskBlock) -> Date {
        let blockTasks = getAllTasksForBlock(taskBlock)
        guard let firstTask = blockTasks.sorted(by: { $0.startTime < $1.startTime }).first else {
            return Date()
        }
        return firstTask.startTime
    }
    
    private func getTaskBlockEndTime(_ taskBlock: TaskBlock) -> Date {
        let blockTasks = getAllTasksForBlock(taskBlock)
        guard let lastTask = blockTasks.sorted(by: { $0.endTime < $1.endTime }).last else {
            return Date()
        }
        return lastTask.endTime
    }
    
    private func taskBlocksOverlap(_ block1: TaskBlock, _ block2: TaskBlock) -> Bool {
        let start1 = getTaskBlockStartTime(block1)
        let end1 = getTaskBlockEndTime(block1)
        let start2 = getTaskBlockStartTime(block2)
        let end2 = getTaskBlockEndTime(block2)
        return start1 < end2 && start2 < end1
    }
    
    private func getOverlappingTaskBlocks(_ blocks: [TaskBlock]) -> [[TaskBlock]] {
        var groups: [[TaskBlock]] = []
        var processed: Set<String> = []
        
        for block in blocks {
            if processed.contains(block.id) { continue }
            
            var group = [block]
            processed.insert(block.id)
            
            for otherBlock in blocks {
                if processed.contains(otherBlock.id) { continue }
                
                // Check if blocks overlap (within 5 minute tolerance)
                if taskBlocksOverlap(block, otherBlock) {
                    group.append(otherBlock)
                    processed.insert(otherBlock.id)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    private var workTasks: [Task] {
        // Show work category tasks, plus other categories on the work side
        tasks.filter { 
            $0.taskBlockID == nil && 
            ($0.category == .work || $0.category == .fixed || $0.category == .growth || $0.category == .reading)
        }
    }
    
    private var personalTasks: [Task] {
        // Show personal category tasks, plus other categories on the personal side
        tasks.filter { 
            $0.taskBlockID == nil && 
            ($0.category == .personal || $0.category == .flexible || $0.category == .hobbies || 
             $0.category == .selfCare || $0.category == .leisure || $0.category == .skinCare)
        }
    }
    
    private var workTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getAllTasksForBlock(block)
            return blockTasks.contains { task in
                task.category == .work || task.category == .fixed || 
                task.category == .growth || task.category == .reading
            }
        }
    }
    
    private var personalTaskBlocks: [TaskBlock] {
        taskBlocks.filter { block in
            let blockTasks = getAllTasksForBlock(block)
            return blockTasks.contains { task in
                task.category == .personal || task.category == .flexible || 
                task.category == .hobbies || task.category == .selfCare || 
                task.category == .leisure || task.category == .skinCare
            }
        }
    }
}

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
            .offset(y: position) // Width controlled by parent HStack
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
            .offset(y: position) // Width controlled by parent HStack
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
                        
                        // Show undo toast for 5 seconds
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
            .offset(y: position - 50) // Position above the overlapping tasks
        }
    }
    
    private func startUndoTimer() {
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            // Timer expires, block creation is confirmed
            print("Block creation confirmed")
        }
    }
}

// ScrollOffsetPreferenceKey is defined in InfiniteDaySelector.swift to avoid redeclaration

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
        NavigationView {
            List {
                Section("Task Info") {
                    let theme = themeManager.currentTheme
                    let isDarkMode = theme.id == "dark" || theme.id == "purple"
                    
                    HStack {
                        Text("Title")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(task.title)
                            .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                    
                    HStack {
                        Text("Time")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                            .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                    
                    HStack {
                        Text("Category")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        HStack {
                            Image(systemName: task.category.icon)
                                .foregroundColor(task.category.color())
                            Text(task.category.displayName)
                                .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Priority")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(task.priority.rawValue.capitalized)
                            .foregroundColor(isDarkMode ? theme.textSecondary : priorityColor) // Grey on dark mode
                    }
                    
                    // Lock/Unlock button - Always visible (persistent)
                        HStack {
                        Image(systemName: task.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(task.isLocked ? .orange : .green)
                        Text(task.isLocked ? "Task is Locked" : "Task is Unlocked")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                            Spacer()
                            Button(action: {
                            task.isLocked.toggle()
                                try? modelContext.save()
                            }) {
                            Text(task.isLocked ? "Unlock" : "Lock")
                                .foregroundColor(isDarkMode ? theme.textSecondary : .blue) // Grey on dark mode
                        }
                    }
                }
                
                Section("Notes") {
                    transparentTextEditor(
                        text: $notes,
                        theme: themeManager.currentTheme,
                        placeholder: "Add notes...",
                        minHeight: 150
                    )
                }
                
                Section("Calendar") {
                    Button(action: {
                        // Add task to calendar
                        calendarManager.addTaskToCalendar(task: task)
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Calendar")
                        }
                    }
                    
                    if calendarManager.isAuthorized {
                        Button(action: {
                            // Sync with calendar
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
            // Default system white background restored
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(notes)
                    }
                    .fontWeight(.semibold)
                }
            }
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
        NavigationView {
            List {
                Section("Block") {
                    let theme = themeManager.currentTheme
                    let isDarkMode = theme.id == "dark" || theme.id == "purple"
                    
                    HStack {
                        Text("Title")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(taskBlock.title)
                            .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                    HStack {
                        Text("Priority")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text(taskBlock.priority.rawValue.capitalized)
                            .foregroundColor(isDarkMode ? theme.textSecondary : blockPriorityColor) // Grey on dark mode
                    }
                    HStack {
                        Text("Tasks in Block")
                            .foregroundColor(isDarkMode ? theme.textSecondary : .secondary)
                        Spacer()
                        Text("\(tasks.count)")
                            .foregroundColor(isDarkMode ? theme.textPrimary : .primary)
                    }
                }

                Section("Notes") {
                    transparentTextEditor(
                        text: $notes,
                        theme: themeManager.currentTheme,
                        placeholder: "Add notes...",
                        minHeight: 150
                    )
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

#Preview {
    ContinuousTimelineView(
        tasks: [],
        taskBlocks: [],
        calendarEvents: [],
        selectedDate: Date(),
        currentTime: Date(),
        getTasksForBlock: { _, _ in [] },
        getAllTasksForBlock: { _ in [] },
        getOverlappingTasks: { _ in [] },
        updateTaskTime: { _, _, _ in },
        updateTaskSide: { _, _ in },
        updateTaskBlockTime: { _, _, _ in },
        updateTaskBlockSide: { _, _ in },
        handleTaskCollision: { _, _, _ in },
        viewMode: .fullView
    )
    .environmentObject(TimeSettingsManager())
}
