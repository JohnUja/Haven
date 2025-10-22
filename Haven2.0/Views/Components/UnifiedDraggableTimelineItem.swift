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
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentHoverTime: Date? = nil
    @State private var showingSideChangeConfirmation = false
    @State private var pendingSideChange: TaskTimelineBlock.TimelineSide? = nil
    @State private var showGuidelines = false
    @State private var showingLockedAlert = false
    
    private let minuteHeight: CGFloat = 2.0 // 120 points per hour / 60 minutes = 2 points per minute
    
    init(
        @ViewBuilder content: () -> Content,
        side: TaskTimelineBlock.TimelineSide,
        isLocked: Bool,
        startTime: Date,
        endTime: Date,
        onTimeChanged: @escaping (Date, Date) -> Void,
        onSideChanged: @escaping (TaskTimelineBlock.TimelineSide) -> Void
    ) {
        self.content = content()
        self.side = side
        self.isLocked = isLocked
        self.startTime = startTime
        self.endTime = endTime
        self.onTimeChanged = onTimeChanged
        self.onSideChanged = onSideChanged
    }
    
    var body: some View {
        content
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .gesture(dragGesture)
            .zIndex(isDragging ? 1000 : 0)
            .overlay(dragOverlay)
            .overlay(guidelinesOverlay)
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
                    // Long press started - check if item is locked
                    if isLocked {
                        showingLockedAlert = true
                        AudioServicesPlaySystemSound(1521) // Error haptic
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDragging = true
                            showGuidelines = true
                        }
                        AudioServicesPlaySystemSound(1519) // Haptic feedback
                    }
                    
                case .second(true, let drag):
                    // Drag started
                    if let drag = drag {
                        dragOffset = drag.translation
                        
                        // Calculate potential new time based on drag
                        let verticalTranslation = drag.translation.height
                        let minuteTranslation = Int(verticalTranslation / minuteHeight)
                        
                        let newStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: startTime) ?? startTime
                        let newEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: endTime) ?? endTime
                        
                        // Snap to nearest 5-minute interval
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
                    }
                    
                    if let drag = drag {
                        // Calculate final new time based on drag
                        let verticalTranslation = drag.translation.height
                        let minuteTranslation = Int(verticalTranslation / minuteHeight)
                        
                        var finalNewStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: startTime) ?? startTime
                        var finalNewEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: endTime) ?? endTime
                        
                        // Snap to nearest 5-minute interval on drop
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
                    AudioServicesPlaySystemSound(1520) // Haptic feedback
                    
                default:
                    // Long press cancelled
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDragging = false
                        dragOffset = .zero
                        showGuidelines = false
                    }
                }
            }
    }
    
    private var dragOverlay: some View {
        Group {
            if isDragging, let hoverTime = currentHoverTime {
                VStack {
                    Text("\(hoverTime, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .shadow(radius: 2)
                        )
                        .foregroundColor(.black)
                        .offset(y: dragOffset.height - 30)
                    
                    if let pendingSide = pendingSideChange {
                        Text("Move to \(pendingSide == .left ? "Work" : "Personal")?")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(pendingSide == .left ? Color.blue.opacity(0.8) : Color.purple.opacity(0.8))
                            )
                            .foregroundColor(.white)
                            .offset(y: dragOffset.height - 10)
                    }
                }
            }
        }
    }
    
    private var guidelinesOverlay: some View {
        Group {
            if showGuidelines && isDragging {
                VStack(spacing: 0) {
                    // 15-minute guideline
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                        .offset(y: -30) // 15 minutes = 30 points
                    
                    // 30-minute guideline (middle) - more prominent
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(height: 2)
                        .offset(y: 0) // 30 minutes = 60 points
                    
                    // 45-minute guideline
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                        .offset(y: 30) // 45 minutes = 90 points
                    
                    // 60-minute guideline (end of hour)
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(height: 1)
                        .offset(y: 60) // 60 minutes = 120 points
                }
                .frame(width: 2)
                .offset(x: side == .left ? -20 : 20) // Position on the appropriate side
            }
        }
    }
    
    private func snapToNearestFiveMinutes(date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        let snappedMinute = (minute / 5) * 5
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
