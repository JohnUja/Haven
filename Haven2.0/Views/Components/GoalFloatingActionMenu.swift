//
//  GoalFloatingActionMenu.swift
//  TimeFlow
//
//  Created by AI on 2025-11-26.
//

import SwiftUI
import SwiftData

struct GoalFloatingActionMenu: View {
    let goal: Goal
    let onEdit: () -> Void
    let onAddTask: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Edit
            Button(action: onEdit) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.title2)
                    Text("Edit")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Add Task
            Button(action: onAddTask) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                    Text("Add Task")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Pause/Resume
            Button(action: onPause) {
                VStack(spacing: 4) {
                    Image(systemName: goal.status == .paused ? "play.circle" : "pause.circle")
                        .font(.title2)
                    Text(goal.status == .paused ? "Resume" : "Pause")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Delete
            Button(role: .destructive, action: onDelete) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}

