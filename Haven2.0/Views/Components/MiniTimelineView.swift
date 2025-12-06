//
//  MiniTimelineView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Mini timeline view for today's agenda
//

import SwiftUI
import SwiftData

struct MiniTimelineView: View {
    let tasks: [Task]
    let selectedDate: Date
    @State private var selectedTask: Task? = nil
    @State private var showingImmersive = false
    
    private var sortedTasks: [Task] {
        tasks.filter { !$0.isComplete }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(sortedTasks) { task in
                    TimelineTaskContainer(
                        task: task,
                        onTap: {
                            selectedTask = task
                            showingImmersive = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingImmersive) {
            if let task = selectedTask {
                ImmersiveWorkingOnView(task: task, onDismiss: {
                    showingImmersive = false
                    selectedTask = nil
                })
            }
        }
    }
}

struct TimelineTaskContainer: View {
    let task: Task
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(task.priority.color))
                        .frame(width: 6, height: 6)
                    
                    Text(timeFormatter.string(from: task.startTime))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(task.priority.color).opacity(0.5), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

