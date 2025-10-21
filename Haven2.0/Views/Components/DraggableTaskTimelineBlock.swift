//
//  DraggableTaskTimelineBlock.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI
import AudioToolbox

struct DraggableTaskTimelineBlock: View {
    @Environment(\.modelContext) private var modelContext
    let task: Task
    let side: TaskTimelineBlock.TimelineSide
    let onTimeChanged: (Task, Date, Date) -> Void
    let onSideChanged: (Task, TaskTimelineBlock.TimelineSide) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentHoverTime: Date? = nil
    @State private var showingSideChangeConfirmation = false
    @State private var pendingSideChange: TaskTimelineBlock.TimelineSide? = nil
    
    private let minuteHeight: CGFloat = 2.0 // 120 points per hour / 60 minutes = 2 points per minute
    
    var body: some View {
        TaskTimelineBlock(task: task, side: side)
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture())
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            // Long press started
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDragging = true
                            }
                            AudioServicesPlaySystemSound(1519) // Haptic feedback
                            
                        case .second(true, let drag):
                            // Drag started
                            if let drag = drag {
                                dragOffset = drag.translation
                                
                                // Calculate potential new time based on drag
                                let verticalTranslation = drag.translation.height
                                let minuteTranslation = Int(verticalTranslation / minuteHeight)
                                
                                let newStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: task.startTime) ?? task.startTime
                                let newEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: task.endTime) ?? task.endTime
                                
                                // Snap to nearest 5-minute interval
                                currentHoverTime = snapToNearestFiveMinutes(date: newStartTime)
                                
                                // Check if crossing to other side
                                let newSide = determineSideFromPosition(drag.translation)
                                if newSide != side {
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
                            }
                            
                            if let drag = drag {
                                // Calculate final new time based on drag
                                let verticalTranslation = drag.translation.height
                                let minuteTranslation = Int(verticalTranslation / minuteHeight)
                                
                                var finalNewStartTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: task.startTime) ?? task.startTime
                                var finalNewEndTime = Calendar.current.date(byAdding: .minute, value: minuteTranslation, to: task.endTime) ?? task.endTime
                                
                                // Snap to nearest 5-minute interval on drop
                                if let snappedTime = snapToNearestFiveMinutes(date: finalNewStartTime) {
                                    let duration = finalNewEndTime.timeIntervalSince(finalNewStartTime)
                                    finalNewStartTime = snappedTime
                                    finalNewEndTime = snappedTime.addingTimeInterval(duration)
                                }
                                
                                // Check if side changed
                                let newSide = determineSideFromPosition(drag.translation)
                                if newSide != side {
                                    showingSideChangeConfirmation = true
                                    pendingSideChange = newSide
                                } else {
                                    // Just update time
                                    onTimeChanged(task, finalNewStartTime, finalNewEndTime)
                                }
                            }
                            
                            currentHoverTime = nil
                            AudioServicesPlaySystemSound(1520) // Haptic feedback
                            
                        default:
                            // Long press cancelled
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDragging = false
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .zIndex(isDragging ? 1000 : 0) // Bring dragged item to front
            .overlay(
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
            )
            .alert("Move Task", isPresented: $showingSideChangeConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingSideChange = nil
                }
                Button("Move to \(pendingSideChange == .left ? "Work" : "Personal")") {
                    if let newSide = pendingSideChange {
                        onSideChanged(task, newSide)
                    }
                    pendingSideChange = nil
                }
            } message: {
                if let newSide = pendingSideChange {
                    Text("Do you want to move '\(task.title)' to \(newSide == .left ? "Work" : "Personal") side?")
                }
            }
    }
    
    private func snapToNearestFiveMinutes(date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        let snappedMinute = (minute / 5) * 5
        return Calendar.current.date(bySettingHour: hour, minute: snappedMinute, second: 0, of: date)
    }
    
    private func determineSideFromPosition(_ translation: CGSize) -> TaskTimelineBlock.TimelineSide {
        // If dragging to the left side of the screen, it's Work (left side)
        // If dragging to the right side of the screen, it's Personal (right side)
        return translation.width < 0 ? .left : .right
    }
}

#Preview {
    VStack {
        DraggableTaskTimelineBlock(
            task: Task(
                userID: "preview",
                title: "Sample Task",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                priority: .normal,
                category: .work
            ),
            side: .left,
            onTimeChanged: { _, _, _ in },
            onSideChanged: { _, _ in }
        )
    }
    .padding()
}
