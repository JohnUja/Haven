struct TaskTimelineBlock: View {
    let task: Task
    let side: TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    
    private var taskHeight: CGFloat {
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let minutes = duration / 60
        // Full hour space: 120 points per hour, so each minute is 2 points
        // Allow tasks to span multiple hours - no maximum height cap
        return max(20, CGFloat(minutes) * 2.0)
    }
    
    private var taskOffset: CGFloat {
        // Calculate offset within the hour for tasks that start in this hour
        let taskStartHour = Calendar.current.component(.hour, from: task.startTime)
        let taskStartMinute = Calendar.current.component(.minute, from: task.startTime)
        
        // If task starts in this hour, offset by minutes within the hour
        if taskStartHour == Calendar.current.component(.hour, from: Date()) {
            return CGFloat(taskStartMinute) * 2.0 // 2 points per minute
        }
        
        // If task spans across this hour, start at the top
        return 0
    }
    
    private var taskColor: Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    private var categoryColor: Color {
        task.category.color()
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 4) {
            // Task title
            Text(task.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(side == .left ? .leading : .trailing)
            
            // Time range
            Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            // Priority indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(taskColor)
                    .frame(width: 6, height: 6)
                
                Text(task.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(taskColor, lineWidth: 2)
                )
        )
        .frame(maxWidth: 120, minHeight: taskHeight)
        .offset(y: taskOffset) // Apply the calculated offset
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        .overlay(
            // Lock icon for locked tasks
            Group {
                if task.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                        .offset(x: 50, y: -20) // Top-right corner
                }
            },
            alignment: .topTrailing
        )
    }
}

struct TaskBlockTimelineView: View {
    let taskBlock: TaskBlock
    let tasks: [Task]
    let side: TimelineSide
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    private var blockHeight: CGFloat {
        let totalDuration = tasks.reduce(0) { total, task in
            total + task.endTime.timeIntervalSince(task.startTime)
        }
        let minutes = totalDuration / 60
        // Each hour is 120 points, so each minute is 2 points
        // Minimum height of 30 points, maximum of 100 points per hour
        return max(30, min(100, CGFloat(minutes) * 2))
    }
    
    private var blockColor: Color {
        switch taskBlock.priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    private var categoryColor: Color {
        // Use the category color of the first task, or default to blue
        if let firstTask = tasks.first {
            return firstTask.category.color()
        }
        return .blue
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 4) {
            // Block title
            Text(taskBlock.title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(side == .left ? .leading : .trailing)
            
            // Task count
            Text("\(tasks.count) tasks")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            // Time range
            if let firstTask = tasks.first, let lastTask = tasks.last {
                let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
                let startTime = sortedTasks.first?.startTime ?? firstTask.startTime
                let endTime = sortedTasks.last?.endTime ?? lastTask.endTime
                
                Text("\(timeSettings.formatTime(startTime)) - \(timeSettings.formatTime(endTime))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Priority indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(blockColor)
                    .frame(width: 6, height: 6)
                
                Text(taskBlock.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(blockColor, lineWidth: 3)
                )
        )
        .frame(maxWidth: 120, minHeight: blockHeight)
        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
        .overlay(
            // Lock icon for locked task blocks
            Group {
                if taskBlock.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                        .offset(x: 50, y: -20) // Top-right corner
                }
            },
            alignment: .topTrailing
        )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Task.self], inMemory: true)
}
