//
//  UnifiedDraggableTimelineItem.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI
import AudioToolbox

struct UnifiedDraggableTimelineItem<Content: View>: View {
    let content: Content
    let side: TaskTimelineBlock.TimelineSide
    let isLocked: Bool
    let startTime: Date
    let endTime: Date
    let onTimeChanged: (Date, Date) -> Void
    let onSideChanged: (TaskTimelineBlock.TimelineSide) -> Void
    let onTaskCollision: ((Date, Date) -> Void)? // New parameter for collision detection
    let onDragStateChanged: ((Bool) -> Void)? // New parameter for drag state
    let onTap: (() -> Void)? // New parameter for tap gesture
    
    init(content: Content, side: TaskTimelineBlock.TimelineSide, isLocked: Bool, startTime: Date, endTime: Date, onTimeChanged: @escaping (Date, Date) -> Void, onSideChanged: @escaping (TaskTimelineBlock.TimelineSide) -> Void, onTaskCollision: ((Date, Date) -> Void)? = nil, onDragStateChanged: ((Bool) -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.content = content
        self.side = side
        self.isLocked = isLocked
        self.startTime = startTime
        self.endTime = endTime
        self.onTimeChanged = onTimeChanged
        self.onSideChanged = onSideChanged
        self.onTaskCollision = onTaskCollision
        self.onDragStateChanged = onDragStateChanged
        self.onTap = onTap
    }
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentHoverTime: Date? = nil
    @State private var showingSideChangeConfirmation = false
    @State private var pendingSideChange: TaskTimelineBlock.TimelineSide? = nil
    @State private var showGuidelines = false
    @State private var showingLockedAlert = false
    @State private var didDrag: Bool = false
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    private let minuteHeight: CGFloat = 2.0 // 120 points per hour / 60 minutes = 2 points per minute
    
    init(
        @ViewBuilder content: () -> Content,
        side: TaskTimelineBlock.TimelineSide,
        isLocked: Bool,
        startTime: Date,
        endTime: Date,
        onTimeChanged: @escaping (Date, Date) -> Void,
        onSideChanged: @escaping (TaskTimelineBlock.TimelineSide) -> Void,
        onTaskCollision: ((Date, Date) -> Void)? = nil,
        onDragStateChanged: ((Bool) -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.content = content()
        self.side = side
        self.isLocked = isLocked
        self.startTime = startTime
        self.endTime = endTime
        self.onTimeChanged = onTimeChanged
        self.onSideChanged = onSideChanged
        self.onTaskCollision = onTaskCollision
        self.onDragStateChanged = onDragStateChanged
        self.onTap = onTap
    }
    
    var body: some View {
        ZStack {
            content
                .offset(dragOffset)
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Only trigger tap if there was no drag
                            if !didDrag, let tapHandler = onTap {
                                tapHandler()
                            }
                            didDrag = false // Reset for next interaction
                        }
                )
                .gesture(dragGesture)
                .zIndex(isDragging ? 1000 : 0)
            
            // Floating time indicator at timeline level (positioned at the top of the task)
            if isDragging, let hoverTime = currentHoverTime {
                floatingTimeIndicator
                    .zIndex(1001)
            }
        }
        // Guidelines are now handled in ContinuousTimelineView
        .alert("Move Item", isPresented: $showingSideChangeConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingSideChange = nil
            }
            Button("Move to \(pendingSideChange == .left ? "Work" : "Personal")") {
                if let newSide = pendingSideChange {
                    onSideChanged(newSide)
                }
                pendingSideChange = nil
            }
        } message: {
            if let newSide = pendingSideChange {
                Text("Do you want to move this item to \(newSide == .left ? "Work" : "Personal") side?")
            }
        }
        .alert("Item Locked", isPresented: $showingLockedAlert) {
            Button("OK") { }
        } message: {
            Text("This item is locked and cannot be moved. Unlock it from the home screen to move it.")
        }
    }
    
    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press started - start dragging if not locked
                    if !isLocked {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDragging = true
                            showGuidelines = true
                            onDragStateChanged?(true) // Notify parent
                        }
                        AudioServicesPlaySystemSound(1519) // Haptic feedback
                    }
                    
                case .second(true, let drag):
                    // Drag started - check if item is locked
                    if isLocked {
                        showingLockedAlert = true
                        AudioServicesPlaySystemSound(1521) // Error haptic
                        return
                    }
                    
                    if let drag = drag {
                        didDrag = true // Mark that a drag occurred
                        dragOffset = drag.translation
                        
                        // Calculate potential new time based on drag
                        let verticalTranslation = drag.translation.height
                        let minuteTranslation = Int(verticalTranslation / minuteHeight)
                        
                        let newStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: startTime) ?? startTime
                        let newEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: endTime) ?? endTime
                        
                        // Snap to nearest 5-minute interval for ultra precision
                        currentHoverTime = snapToNearestFiveMinutes(date: newStartTime)
                        
                        // Check if crossing to other side
                        if let newSide = determineSideFromPosition(drag.translation), newSide != side {
                            pendingSideChange = newSide
                        } else {
                            pendingSideChange = nil
                        }
                    }
                    
                default:
                    break
                }
            }
            .onEnded { value in
                switch value {
                case .second(true, let drag):
                    // Drag ended
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDragging = false
                        dragOffset = .zero
                        showGuidelines = false
                        onDragStateChanged?(false) // Notify parent
                    }
                    
                    if let drag = drag {
                        // Calculate final new time based on drag
                        let verticalTranslation = drag.translation.height
                        let minuteTranslation = Int(verticalTranslation / minuteHeight)
                        
                        var finalNewStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: startTime) ?? startTime
                        var finalNewEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: endTime) ?? endTime
                        
                        // Snap to nearest 5-minute interval on drop for ultra precision
                        if let snappedTime = snapToNearestFiveMinutes(date: finalNewStartTime) {
                            let duration = finalNewEndTime.timeIntervalSince(finalNewStartTime)
                            finalNewStartTime = snappedTime
                            finalNewEndTime = snappedTime.addingTimeInterval(duration)
                        }
                        
                        // Check if side changed
                        if let newSide = determineSideFromPosition(drag.translation), newSide != side {
                            showingSideChangeConfirmation = true
                            pendingSideChange = newSide
                        } else {
                            // Just update time
                            onTimeChanged(finalNewStartTime, finalNewEndTime)
                        }
                    }
                    
                    currentHoverTime = nil
                    didDrag = false // Reset for next interaction
                    AudioServicesPlaySystemSound(1520) // Haptic feedback
                    
                default:
                    // Long press cancelled
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDragging = false
                        dragOffset = .zero
                        showGuidelines = false
                        onDragStateChanged?(false) // Notify parent
                    }
                }
            }
    }
    
    // Floating time indicator - acts as a "leveler" showing exact position on timeline
    private var floatingTimeIndicator: some View {
        HStack {
            Spacer()
            
            if let hoverTime = currentHoverTime {
                VStack(spacing: 4) {
                    // Time display with FIXED WIDTH
                    Text(timeSettings.formatTime(hoverTime))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 120) // FIXED WIDTH - never changes
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.95))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Side change indicator (if applicable)
                    if let pendingSide = pendingSideChange {
                        Text("Move to \(pendingSide == .left ? "Work" : "Personal")?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 120) // FIXED WIDTH - matches time display
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(pendingSide == .left ? Color.blue.opacity(0.9) : Color.green.opacity(0.9))
                            )
                    }
                }
                .offset(y: dragOffset.height - 40) // Position above the task
                .padding(.trailing, 16)
            }
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    private var guidelinesOverlay: some View {
        GeometryReader { geometry in
            if showGuidelines && isDragging {
                // Dynamic guidelines spanning the entire 24-hour timeline
                ZStack(alignment: .top) {
                    // Draw 5-minute interval guidelines for all 24 hours (288 intervals)
                    ForEach(0..<288, id: \.self) { interval in
                        let minute = (interval * 5) % 60
                        let hour = interval / 12
                        let yPosition = CGFloat(hour) * 120 + CGFloat(minute) * 2
                        let isMajorMark = minute % 15 == 0
                        
                        Rectangle()
                            .fill(Color.white.opacity(isMajorMark ? 0.6 : 0.25))
                            .frame(width: geometry.size.width * 0.8, height: isMajorMark ? 2 : 1)
                            .position(x: geometry.size.width / 2, y: yPosition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
    }
    
    private func snapToNearestFiveMinutes(date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        // Snap to nearest 5-minute interval (0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)
        let snappedMinute = (minute / 5) * 5
        return Calendar.current.date(bySettingHour: hour, minute: snappedMinute, second: 0, of: date)
    }
    
    private func snapToNearestFifteenMinutes(date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        // Snap to nearest 15-minute interval (0, 15, 30, 45)
        let snappedMinute = (minute / 15) * 15
        return Calendar.current.date(bySettingHour: hour, minute: snappedMinute, second: 0, of: date)
    }
    
    private func determineSideFromPosition(_ translation: CGSize) -> TaskTimelineBlock.TimelineSide? {
        // Only trigger side change when crossing the middle section (half screen width)
        // Use a threshold to prevent accidental side changes
        let screenWidth = UIScreen.main.bounds.width
        let middleThreshold = screenWidth * 0.1 // 10% threshold from center
        
        if translation.width < -middleThreshold {
            return .left // Work side
        } else if translation.width > middleThreshold {
            return .right // Personal side
        } else {
            return nil // Still in middle section, no side change
        }
    }
}

#Preview {
    UnifiedDraggableTimelineItem(
        content: {
            Text("Sample Task")
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        },
        side: .left,
        isLocked: false,
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        onTimeChanged: { _, _ in },
        onSideChanged: { _ in }
    )
    .padding()
}
