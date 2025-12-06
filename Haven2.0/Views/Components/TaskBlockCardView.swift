//
//  TaskBlockCardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-19.
//

import SwiftUI
import SwiftData
import AudioToolbox
import FirebaseAuth

struct TaskBlockCardView: View {
    let tasks: [Task]
    let taskBlock: TaskBlock?
    let theme: any AppTheme
    let onEditBlock: (([Task]) -> Void)?
    let onAddSubtask: (() -> Void)?
    let onRemoveSubtask: ((Task) -> Void)?
    
    @State private var isExpanded = false
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var users: [User]
    @Query private var allTasks: [Task]

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
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
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
                                .foregroundColor(.white) // WHITE TEXT
                                .strikethrough(isBlockComplete) // CROSS OUT WHEN COMPLETE
                                .opacity(isBlockComplete ? 0.6 : 1.0)
                            
                            Spacer()
                            
                            Text("\(completedCount)/\(tasks.count)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8)) // WHITE TEXT
                        }
                        
                            // Priority text for the block - MATCH PRIORITY COLOR
                            HStack {
                                Text("Priority: \(blockPriorityText)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(blockPriorityColor) // MATCH PRIORITY COLOR (Green/Blue/Orange/Red)
                                Spacer()
                            }
                        
                        // Progress bar
                        ProgressView(value: Double(completedCount), total: Double(tasks.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.5))) // WHITE PROGRESS BAR
                            .scaleEffect(y: 0.5)
                        
                        // Time range for the block
                        HStack {
                            Text(timeRangeText)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7)) // WHITE TEXT
                            Spacer()
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7)) // WHITE TEXT
                }
                .padding(16)
                .background(
                    ZStack {
                        // MUCH PALER category color background with HIGH transparency - use taskBlock color if available
                        let backgroundColor = taskBlock.map { colorFromString($0.color).opacity(0.25) } ?? blockCategoryColor.opacity(0.25)
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .fill(isBlockComplete ? backgroundColor.opacity(0.3) : backgroundColor)
                            .overlay(
                                // Subtle category color stroke
                                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                    .stroke(
                                        taskBlock.map { colorFromString($0.color).opacity(0.6) } ?? blockCategoryColor.opacity(0.6),
                                        lineWidth: theme.cardBorderWidth
                                    )
                            )
                        
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
            
            // Expanded subtasks
            if isExpanded && !tasks.isEmpty {
                let blockColorForSubtasks = taskBlock.map { colorFromString($0.color) } ?? blockCategoryColor
                // Sort tasks: incomplete first, then completed (for smooth animation)
                let sortedTasks = tasks.sorted { task1, task2 in
                    if task1.isComplete != task2.isComplete {
                        return !task1.isComplete // Incomplete tasks first
                    }
                    return task1.startTime < task2.startTime // Then by start time
                }
                VStack(spacing: 8) {
                    ForEach(sortedTasks, id: \.id) { task in
                        HStack(spacing: 12) {
                            // Indent for subtask - MATCH BLOCK COLOR
                            Rectangle()
                                .fill(blockColorForSubtasks.opacity(0.5))
                                .frame(width: 2, height: 20)
                            
                            // Task content - LABELS MATCH BLOCK COLOR
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(theme.bodyFont)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .strikethrough(task.isComplete)
                                    .opacity(task.isComplete ? 0.6 : 1.0)
                                
                                if let description = task.taskDescription {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(2)
                                        .opacity(task.isComplete ? 0.6 : 1.0)
                                }
                            }
                            
                            Spacer()
                            
                            // Completion checkbox
                                Button(action: {
                                    guard let user = users.first else { return }
                                    
                                    // Optimized animation - use spring for smoother performance
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        let wasComplete = task.isComplete
                                        task.isComplete.toggle()
                                        
                                        // Simple completion feedback
                                        if task.isComplete && isBlockComplete {
                                            AudioServicesPlaySystemSound(1104) // Tink sound
                                            AudioServicesPlaySystemSound(1520) // Haptic feedback
                                        }
                                        
                                        // Gamification rewards (only when completing, not uncompleting, and not already rewarded)
                                        if task.isComplete && !wasComplete && !task.hasBeenRewarded {
                                            let goal = goals.first(where: { $0.id == task.goalID })
                                            let momentumBonus = GamificationService.getMomentumBonus(user: user)
                                            let baseRewards = GamificationService.calculateTaskRewards(
                                                task: task,
                                                goal: goal,
                                                momentumBonus: momentumBonus
                                            )
                                            
                                            // Add time-based rewards
                                            let timeBasedRewards = GamificationService.calculateTimeBasedTaskRewards(task: task)
                                            let rewards = (
                                                crystals: baseRewards.crystals + timeBasedRewards.crystals,
                                                xp: baseRewards.xp + timeBasedRewards.xp,
                                                score: baseRewards.score
                                            )
                                            
                                            // Apply rewards
                                            user.gamificationCurrency += rewards.crystals
                                            user.currentXP += rewards.xp
                                            
                                            // Mark as rewarded
                                            task.hasBeenRewarded = true
                                            
                                            // Check for level up (will be handled by parent view)
                                            _ = LevelService.checkLevelUp(user: user, newXP: user.currentXP)
                                            
                                            // Update productivity score
                                            GamificationService.resetWeeklyScores(user: user)
                                            user.weeklyProductivityScore += rewards.score
                                            
                                            // Update momentum
                                            _ = GamificationService.updateMomentumDays(user: user, tasks: allTasks)
                                            
                                            // Check for bonuses (similar to TaskCardView)
                                            let calendar = Calendar.current
                                            let today = calendar.startOfDay(for: Date())
                                            let todayCompletedTasks = allTasks.filter { t in
                                                t.id != task.id &&
                                                calendar.isDate(t.startTime, inSameDayAs: today) && t.isComplete
                                            }
                                            
                                            if todayCompletedTasks.isEmpty {
                                                let bonus = GamificationService.calculateFirstTaskBonus()
                                                user.gamificationCurrency += bonus.crystals
                                                user.currentXP += bonus.xp
                                            } else if todayCompletedTasks.count == 4 {
                                                let bonus = GamificationService.calculateDailyTaskBonus(completedTasks: 5)
                                                user.gamificationCurrency += bonus.crystals
                                                user.currentXP += bonus.xp
                                            }
                                            
                                            // Goal/milestone bonuses
                                            if let goal = goal {
                                                if goal.status == .completed && goal.currentValue == goal.effectiveTargetValue(tasks: allTasks.filter { $0.goalID == goal.id }) {
                                                    let bonus = GamificationService.calculateGoalCompletionBonus()
                                                    user.gamificationCurrency += bonus.crystals
                                                    user.currentXP += bonus.xp
                                                    user.weeklyProductivityScore += bonus.score
                                                } else if let milestoneID = task.milestoneID,
                                                          let milestone = goal.milestones.first(where: { $0.id == milestoneID }),
                                                          milestone.isComplete {
                                                    let bonus = GamificationService.calculateMilestoneCompletionBonus()
                                                    user.gamificationCurrency += bonus.crystals
                                                    user.currentXP += bonus.xp
                                                    user.weeklyProductivityScore += bonus.score
                                                }
                                            }
                                            
                                            try? modelContext.save()
                                            
                                            // Sync to Firestore (background, non-blocking)
                                            syncUserStatsToFirestore(user: user)
                                            
                                            // Check if entire block is complete - give block reward
                                            let allBlockTasksComplete = tasks.allSatisfy { $0.isComplete }
                                            if allBlockTasksComplete {
                                                let blockRewards = GamificationService.calculateTaskBlockRewards(tasks: tasks)
                                                user.gamificationCurrency += blockRewards.crystals
                                                user.currentXP += blockRewards.xp
                                                user.weeklyProductivityScore += blockRewards.crystals // Use crystals as score bonus
                                                try? modelContext.save()
                                                
                                                // Sync to Firestore (background, non-blocking)
                                                syncUserStatsToFirestore(user: user)
                                            }
                                        }
                                        
                                        // Update goal progress if linked
                                        if task.goalID != nil {
                                            GoalProgressUpdater.handleTaskToggle(task, context: modelContext, goals: goals)
                                            
                                            // Delay reflection prompt until animations complete (3 seconds)
                                            if task.isComplete {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                    // Reflection prompt handled by parent view
                                                }
                                            }
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
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: task.isComplete)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    AudioServicesPlaySystemSound(1520)
                    AudioServicesPlaySystemSound(1057)
                    onEditBlock?(tasks)
                }
        )
    }
    
}

#Preview {
    let sampleTasks = [
        Task(userID: "1", title: "Eat breakfast", startTime: Date(), endTime: Date().addingTimeInterval(1800)),
        Task(userID: "1", title: "Drive to work", startTime: Date(), endTime: Date().addingTimeInterval(3600)),
        Task(userID: "1", title: "Dress up", startTime: Date(), endTime: Date().addingTimeInterval(900))
    ]
    
    return TaskBlockCardView(tasks: sampleTasks, theme: PurpleTheme())
        .padding()
}

// MARK: - Firestore Sync Helper
extension TaskBlockCardView {
    private func syncUserStatsToFirestore(user: User) {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            // Not logged in or guest - don't sync
            return
        }
        
        // Sync in background (non-blocking)
        _createConcurrencyTaskAsync {
            do {
                try await FirestoreService.shared.syncGamificationStats(
                    uid: uid,
                    level: user.level,
                    currentXP: user.currentXP,
                    nextLevelXP: user.nextLevelXP,
                    crystals: user.gamificationCurrency,
                    momentumDays: user.momentumDays,
                    lastMomentumUpdate: user.lastMomentumUpdate,
                    weeklyProductivityScore: user.weeklyProductivityScore,
                    weeklyResetDate: user.weeklyResetDate
                )
                
                // Sync theme unlocks
                try await FirestoreService.shared.syncThemeUnlocks(
                    uid: uid,
                    ownedThemeIDs: user.ownedThemeIDs,
                    activeThemeID: user.activeThemeID
                )
            } catch {
                print("FirestoreService: Failed to sync user stats: \(error)")
                // Don't show error to user - background sync can fail silently
            }
        }
    }
}