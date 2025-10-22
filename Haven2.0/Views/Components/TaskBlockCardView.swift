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
    let taskBlock: TaskBlock?
    let theme: any AppTheme
    let onEditBlock: (([Task]) -> Void)?
    let onAddSubtask: (() -> Void)?
    let onRemoveSubtask: ((Task) -> Void)?
    
    @State private var isExpanded = false
    
    init(tasks: [Task], taskBlock: TaskBlock? = nil, theme: any AppTheme, onEditBlock: (([Task]) -> Void)? = nil, onAddSubtask: (() -> Void)? = nil, onRemoveSubtask: ((Task) -> Void)? = nil) {
        self.tasks = tasks
        self.taskBlock = taskBlock
        self.theme = theme
        self.onEditBlock = onEditBlock
        self.onAddSubtask = onAddSubtask
        self.onRemoveSubtask = onRemoveSubtask
    }
    
    private var blockTitle: String {
        // Use the actual TaskBlock title if available, otherwise fallback to "Task Block"
        return taskBlock?.title ?? "Task Block"
    }
    
    private var completedCount: Int {
        guard !tasks.isEmpty else { return 0 }
        return tasks.filter { $0.isComplete }.count
    }
    
    private var isBlockComplete: Bool {
        guard !tasks.isEmpty else { return false }
        return completedCount == tasks.count
    }
    
    private var blockPriorityColor: Color {
        guard !tasks.isEmpty else { return .blue }
        // Use the highest priority in the block
        let priorities = tasks.map { $0.priority }
        if priorities.contains(.urgent) { return .red }
        if priorities.contains(.high) { return .orange }
        if priorities.contains(.normal) { return .green }
        return .blue
    }
    
    private var blockPriorityText: String {
        guard !tasks.isEmpty else { return "Low" }
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
                        
                        // Simple completion highlight
                        if isBlockComplete {
                            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                .stroke(Color.green, lineWidth: 2)
                                .opacity(0.8)
                        }
                    }
                )
                .opacity(isBlockComplete ? 0.7 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture {
                onEditBlock?(tasks)
            }
            
            // Expanded subtasks
            if isExpanded && !tasks.isEmpty {
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
                                        
                                        // Simple completion feedback
                                        if task.isComplete && isBlockComplete {
                                            AudioServicesPlaySystemSound(1104) // Tink sound
                                            AudioServicesPlaySystemSound(1520) // Haptic feedback
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