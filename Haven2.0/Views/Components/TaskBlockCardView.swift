//
//  TaskBlockCardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-19.
//

import SwiftUI
import SwiftData
import AudioToolbox

struct TaskBlockCardView: View {
    let tasks: [Task]
    let theme: any AppTheme
    let onEditBlock: (([Task]) -> Void)?
    let onAddSubtask: (() -> Void)?
    let onRemoveSubtask: ((Task) -> Void)?
    
    @State private var isExpanded = false
    @State private var showCompletionAnimation = false
    @State private var ringProgress: CGFloat = 0
    
    init(tasks: [Task], theme: any AppTheme, onEditBlock: (([Task]) -> Void)? = nil, onAddSubtask: (() -> Void)? = nil, onRemoveSubtask: ((Task) -> Void)? = nil) {
        self.tasks = tasks
        self.theme = theme
        self.onEditBlock = onEditBlock
        self.onAddSubtask = onAddSubtask
        self.onRemoveSubtask = onRemoveSubtask
    }
    
    private var blockTitle: String {
        "Task Block"
    }
    
    private var completedCount: Int {
        tasks.filter { $0.isComplete }.count
    }
    
    private var isBlockComplete: Bool {
        completedCount == tasks.count && !tasks.isEmpty
    }
    
    private var blockPriorityColor: Color {
        // Use the highest priority in the block
        let priorities = tasks.map { $0.priority }
        if priorities.contains(.urgent) { return .red }
        if priorities.contains(.high) { return .orange }
        if priorities.contains(.normal) { return .green }
        return .blue
    }
    
    private var blockPriorityText: String {
        let priorities = tasks.map { $0.priority }
        if priorities.contains(.urgent) { return "Urgent" }
        if priorities.contains(.high) { return "High" }
        if priorities.contains(.normal) { return "Normal" }
        return "Low"
    }
    
    private var blockCategoryColor: Color {
        // Use the category color of the first task, or default to blue
        if let firstTask = tasks.first {
            return firstTask.category.color()
        }
        return .blue
    }
    
    private var timeRangeText: String {
        guard !tasks.isEmpty else { return "" }
        
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        let startTime = sortedTasks.first?.startTime ?? Date()
        let endTime = sortedTasks.last?.endTime ?? Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if Calendar.current.isDate(startTime, inSameDayAs: endTime) {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        } else {
            return "Multi-day"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main block header
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Block color indicator
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Priority indicator for the block
                            Circle()
                                .fill(blockPriorityColor)
                                .frame(width: 8, height: 8)
                            
                            Text(blockTitle)
                                .font(theme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(completedCount)/\(tasks.count)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                            // Priority text for the block
                            HStack {
                                Text("Priority: \(blockPriorityText)")
                                    .font(.caption2)
                                    .foregroundColor(blockPriorityColor)
                                Spacer()
                            }
                        
                        // Progress bar
                        ProgressView(value: Double(completedCount), total: Double(tasks.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 0.5)
                        
                        // Time range for the block
                        HStack {
                            Text(timeRangeText)
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .fill(isBlockComplete ? theme.cardBackground.opacity(0.5) : theme.cardBackground)
                            .overlay(
                                // Category color ring
                                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                    .stroke(
                                        blockCategoryColor,
                                        lineWidth: 1.5
                                    )
                                    .opacity(0.6)
                            )
                            .shadow(color: theme.primaryColor.opacity(0.1), radius: theme.shadowRadius)
                        
                        // Completion ring animation
                        if showCompletionAnimation {
                            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                .stroke(
                                    AngularGradient(
                                        colors: [.green, .blue, .purple, .pink, .green],
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360)
                                    ),
                                    lineWidth: 3
                                )
                                .opacity(ringProgress)
                                .scaleEffect(1.05)
                                .animation(.easeInOut(duration: 2.0), value: ringProgress)
                        }
                    }
                )
                .opacity(isBlockComplete ? 0.7 : 1.0)
                .onChange(of: isBlockComplete) { _, newValue in
                    if newValue && !showCompletionAnimation {
                        triggerCompletionAnimation()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture {
                onEditBlock?(tasks)
            }
            
            // Expanded subtasks
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(tasks, id: \.id) { task in
                        HStack(spacing: 12) {
                            // Indent for subtask
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 2, height: 20)
                            
                            // Task content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(theme.bodyFont)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textPrimary)
                                    .strikethrough(task.isComplete)
                                    .opacity(task.isComplete ? 0.6 : 1.0)
                                
                                if let description = task.taskDescription {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                        .lineLimit(2)
                                        .opacity(task.isComplete ? 0.6 : 1.0)
                                }
                            }
                            
                            Spacer()
                            
                            // Completion checkbox
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        task.isComplete.toggle()
                                        
                                        // Trigger completion animation if all tasks are now complete
                                        if task.isComplete && isBlockComplete && !showCompletionAnimation {
                                            triggerCompletionAnimation()
                                        }
                                    }
                                }) {
                                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(task.isComplete ? .green : theme.textSecondary)
                                    .scaleEffect(task.isComplete ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: task.isComplete)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.cardBackground.opacity(0.5))
                        )
                        .opacity(task.isComplete ? 0.7 : 1.0)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onLongPressGesture {
            // Long press to edit task block
            onEditBlock?(tasks)
        }
    }
    
    private func triggerCompletionAnimation() {
        showCompletionAnimation = true
        
        // Ring animation
        withAnimation(.easeInOut(duration: 1.5)) {
            ringProgress = 1.0
        }
        
        // Play completion sound and vibration
        AudioServicesPlaySystemSound(1104) // Tink sound (more satisfying)
        AudioServicesPlaySystemSound(1520) // Haptic feedback
        
        // Hide animation after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                ringProgress = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCompletionAnimation = false
            }
        }
    }
}

#Preview {
    let sampleTasks = [
        Task(userID: "1", title: "Eat breakfast", startTime: Date(), endTime: Date().addingTimeInterval(1800)),
        Task(userID: "1", title: "Drive to work", startTime: Date(), endTime: Date().addingTimeInterval(3600)),
        Task(userID: "1", title: "Dress up", startTime: Date(), endTime: Date().addingTimeInterval(900))
    ]
    
    return TaskBlockCardView(tasks: sampleTasks, theme: DefaultTheme())
        .padding()
}