//
//  RecentItemCard.swift
//  TimeFlow
//
//  Created by AI on 2025-01-13.
//

import SwiftUI
import SwiftData

struct RecentItemCard: View {
    let item: Any
    let theme: any AppTheme
    let onTap: () -> Void
    
    private var itemType: String {
        if item is Task {
            return "Task"
        } else if item is Goal {
            return "Goal"
        } else if item is TaskBlock {
            return "Task Block"
        }
        return "Item"
    }
    
    private var itemTitle: String {
        if let task = item as? Task {
            return task.title
        } else if let goal = item as? Goal {
            return goal.title
        } else if let taskBlock = item as? TaskBlock {
            return taskBlock.title
        }
        return "Unknown"
    }
    
    private var itemDate: Date {
        if let task = item as? Task {
            // Task doesn't have createdAt, use startTime as creation date
            return task.startTime
        } else if let goal = item as? Goal {
            return goal.createdAt
        } else if let taskBlock = item as? TaskBlock {
            return taskBlock.createdDate
        }
        return Date()
    }
    
    private var itemIcon: String {
        if item is Task {
            return "checkmark.circle.fill"
        } else if item is Goal {
            return "target"
        } else if item is TaskBlock {
            return "square.stack.3d.up.fill"
        }
        return "circle.fill"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: itemIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(itemType)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(formatDate(itemDate))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3)
        
        RecentItemCard(
            item: Task(
                userID: "preview-user",
                title: "Sample Task",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                category: .work
            ),
            theme: DefaultTheme(),
            onTap: {}
        )
        .padding()
    }
}

