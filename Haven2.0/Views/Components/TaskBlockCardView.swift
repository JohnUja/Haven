//
//  TaskBlockCardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-19.
//

import SwiftUI
import SwiftData

struct TaskBlockCardView: View {
    let tasks: [Task]
    let theme: any AppTheme
    
    @State private var isExpanded = false
    
    private var blockTitle: String {
        "Task Block (\(tasks.count) tasks)"
    }
    
    private var completedCount: Int {
        tasks.filter { $0.isComplete }.count
    }
    
    private var isBlockComplete: Bool {
        completedCount == tasks.count && !tasks.isEmpty
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
                            Text(blockTitle)
                                .font(theme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(completedCount)/\(tasks.count)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        // Progress bar
                        ProgressView(value: Double(completedCount), total: Double(tasks.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 0.5)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .fill(isBlockComplete ? theme.cardBackground.opacity(0.5) : theme.cardBackground)
                        .shadow(color: theme.primaryColor.opacity(0.1), radius: theme.shadowRadius)
                )
                .opacity(isBlockComplete ? 0.7 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
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