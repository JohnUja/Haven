//
//  ImmersiveWorkingOnView.swift
//  TimeFlow
//
//  Created by AI on 2025-01-13.
//  Updated: Complete redesign with dynamic backgrounds, pause/skip, auto-rewards
//

import SwiftUI
import SwiftData
import AVKit
import ActivityKit

struct ImmersiveWorkingOnView: View {
    let task: Task
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var allTasks: [Task]
    @Query private var users: [User]
    @Environment(FirebaseAuthService.self) private var authService
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var pausedTime: TimeInterval = 0 // Time when paused
    @State private var totalPausedDuration: TimeInterval = 0 // Total time spent paused
    @State private var timer: Timer?
    @State private var startTime: Date = Date()
    @State private var isPaused: Bool = false
    @State private var showingCompletionSummary: Bool = false
    @State private var showingSkipConfirmation: Bool = false
    @State private var showingCompleteConfirmation: Bool = false
    @State private var accumulatedXP: Int = 0
    @State private var accumulatedCrystals: Int = 0
    
    // Settings
    @AppStorage("allowEarlyCompletion") private var allowEarlyCompletion: Bool = false
    
    // Get tasks if this is part of a task block
    private var blockTasks: [Task] {
        guard let block = task.taskBlock else { return [] }
        return allTasks.filter { $0.taskBlock?.id == block.id }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private var isTaskBlock: Bool {
        task.taskBlock != nil
    }
    
    private var currentUser: User? {
        users.first
    }
    
    // Calculate remaining time
    private var remainingTime: TimeInterval {
        let taskDuration = task.endTime.timeIntervalSince(task.startTime)
        let adjustedElapsed = elapsedTime - totalPausedDuration
        return max(0, taskDuration - adjustedElapsed)
    }
    
    // Check if task can be completed (either time elapsed or early completion allowed)
    private var canComplete: Bool {
        if allowEarlyCompletion {
            return true // Can complete anytime if setting enabled
        }
        return remainingTime <= 0 // Can only complete when time runs out
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            // Theme-aware background - ensure gradient renders properly
            theme.primaryGradient
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 0) {
                // Top section - Task block tasks list (if applicable)
                if isTaskBlock && !blockTasks.isEmpty {
                    taskBlockListView
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                }
                
                // Top bar with dismiss and skip buttons
                HStack {
                    Button(action: {
                        handleDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(theme.textPrimary)
                            .frame(width: theme.iconCircleSize, height: theme.iconCircleSize)
                            .background(
                                Circle()
                                    .fill(theme.glassBackground)
                            )
                    }
                    
                    Spacer()
                    
                    // Skip button
                    Button(action: {
                        showingSkipConfirmation = true
                    }) {
                        Text("SKIP")
                            .appTextStyle(.body, theme: theme)
                            .textCase(.uppercase)
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding / 2)
                            .background(
                                Capsule()
                                    .fill(theme.glassBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, isTaskBlock ? 0 : 60)
                
                Spacer()
                
                // Main content - Task info and timer
                VStack(spacing: 20) {
                    // Task title
                    Text(task.title)
                        .appTextStyle(.sectionHeader, theme: theme)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Large running timer
                    Text(formatTime(elapsedTime - totalPausedDuration))
                        .font(.system(size: 72, weight: .bold, design: .default))
                        .foregroundColor(theme.textPrimary)
                        .monospacedDigit()
                    
                    // Total duration
                    Group {
                        let taskDuration = task.endTime.timeIntervalSince(task.startTime)
                        let hours = Int(taskDuration) / 3600
                        let minutes = (Int(taskDuration) % 3600) / 60
                        if hours > 0 {
                            Text("\(hours)h")
                                .appTextStyle(.caption, theme: theme)
                                .opacity(theme.textSecondaryOpacity)
                        } else if minutes > 0 {
                            Text("\(minutes)m")
                                .appTextStyle(.caption, theme: theme)
                                .opacity(theme.textSecondaryOpacity)
                        }
                    }
                    
                    // Progress bar (Theme-Aware)
                    GeometryReader { geometry in
                        let taskDuration = task.endTime.timeIntervalSince(task.startTime)
                        let progress = min(1.0, (elapsedTime - totalPausedDuration) / taskDuration)
                        
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.glassBorder.opacity(0.3))
                                .frame(height: 4)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.textPrimary)
                                .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    
                    // Next task indicator (if part of routine) - Theme-Aware
                    if let nextTask = getNextTaskInRoutine() {
                        HStack(spacing: 8) {
                            Text("Next:")
                                .appTextStyle(.body, theme: theme)
                                .opacity(theme.textSecondaryOpacity)
                            Text(nextTask.title)
                                .appTextStyle(.body, theme: theme)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Control buttons at bottom (Theme-Aware)
                    HStack(spacing: 40) {
                        // Stop button
                        VStack(spacing: 8) {
                            Button(action: {
                                handleDismiss()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 24, weight: .semibold, design: .default))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(theme.glassBackground)
                                    )
                            }
                            Text("STOP")
                                .appTextStyle(.caption, theme: theme)
                                .textCase(.uppercase)
                                .opacity(theme.textSecondaryOpacity)
                        }
                        
                        // Complete button (accent color)
                        if canComplete {
                            Button(action: {
                                showingCompleteConfirmation = true
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        Circle()
                                            .fill(theme.accentColor)
                                    )
                            }
                        } else {
                            // Pause button when can't complete yet
                            VStack(spacing: 8) {
                                Button(action: {
                                    togglePause()
                                }) {
                                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 24, weight: .semibold, design: .default))
                                        .foregroundColor(theme.textPrimary)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(theme.glassBackground)
                                        )
                                }
                                Text(isPaused ? "RESUME" : "PAUSE")
                                    .appTextStyle(.caption, theme: theme)
                                    .textCase(.uppercase)
                                    .opacity(theme.textSecondaryOpacity)
                            }
                        }
                        
                        // Skip button
                        VStack(spacing: 8) {
                            Button(action: {
                                showingSkipConfirmation = true
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 24, weight: .semibold, design: .default))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(theme.glassBackground)
                                    )
                            }
                            Text("SKIP")
                                .appTextStyle(.caption, theme: theme)
                                .textCase(.uppercase)
                                .opacity(theme.textSecondaryOpacity)
                        }
                    }
                    .padding(.top, 40)
                }
                .padding(.bottom, 100)
                
                // Bottom bar with routine end time (if part of routine)
                if task.routineID != nil {
                    HStack {
                        Spacer()
                        if let routineEndTime = getRoutineEndTime() {
                            Text("Routine ends at \(formatRoutineTime(routineEndTime))")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .fill(theme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTimer()
            setupDynamicIsland()
        }
        .onDisappear {
            stopTimer()
            cleanupDynamicIsland()
        }
        .sheet(isPresented: $showingCompletionSummary) {
            ImmersiveCompletionSummaryView(
                task: task,
                elapsedTime: elapsedTime - totalPausedDuration,
                xpEarned: accumulatedXP,
                crystalsEarned: accumulatedCrystals,
                onDismiss: {
                    showingCompletionSummary = false
                    onDismiss()
                }
            )
        }
        .alert("Skip Task?", isPresented: $showingSkipConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                handleSkip()
            }
        } message: {
            Text("Skipping this task will not award any XP or crystals. Are you sure?")
        }
        .alert("Complete Task?", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete", role: .destructive) {
                handleComplete()
            }
        } message: {
            Text("Mark this task as complete? You'll earn rewards for completing it.")
        }
    }
    
    // MARK: - Task Block List View (Theme-Aware)
    private var taskBlockListView: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("TASKS IN BLOCK")
                .appTextStyle(.caption, theme: theme)
                .textCase(.uppercase)
                .opacity(theme.textSecondaryOpacity)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.itemSpacing) {
                    ForEach(Array(blockTasks.enumerated()), id: \.element.id) { index, blockTask in
                        TaskBlockItemView(
                            task: blockTask,
                            taskNumber: index + 1,
                            isCurrent: blockTask.id == task.id
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // Helper function to get routine end time
    private func getRoutineEndTime() -> Date? {
        guard let routineID = task.routineID else { return nil }
        let routineTasks = allTasks.filter { $0.routineID == routineID }
            .sorted { $0.startTime < $1.startTime }
        
        return routineTasks.last?.endTime
    }
    
    private func formatRoutineTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Timer Functions
    private func startTimer() {
        // Timer should start from 0, not from task's scheduled start time
        elapsedTime = 0
        startTime = Date()
        
        // Note: ImmersiveWorkingOnView is a struct (value type), so no need for [weak self]
        // Structs don't have retain cycles. The timer will be invalidated in stopTimer() or onDisappear.
        // Access @State properties directly - SwiftUI handles the updates correctly for structs
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Direct access to @State properties works in structs
            // SwiftUI will handle the state updates correctly
            if !isPaused {
                elapsedTime += 1.0
                
                // Auto-assign points every 30 seconds
                if Int(elapsedTime - totalPausedDuration) % 30 == 0 {
                    awardProgressPoints()
                }
                
                // Update Dynamic Island every second
                updateDynamicIsland()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func togglePause() {
        if isPaused {
            // Resuming
            pausedTime = Date().timeIntervalSince(startTime)
            totalPausedDuration += pausedTime
            startTime = Date()
            isPaused = false
            updateDynamicIsland() // Update when resuming
        } else {
            // Pausing
            pausedTime = Date().timeIntervalSince(startTime)
            isPaused = true
            updateDynamicIsland() // Update when pausing
        }
    }
    
    
    // MARK: - Points & Rewards
    private func awardProgressPoints() {
        guard let user = currentUser else { return }
        
        // Award XP (small amount per 30 seconds)
        let xpGain = 2
        user.currentXP += xpGain
        accumulatedXP += xpGain
        
        // Award crystals (small amount per minute)
        if Int(elapsedTime - totalPausedDuration) % 60 == 0 {
            let crystalGain = 1
            user.gamificationCurrency += crystalGain
            accumulatedCrystals += crystalGain
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Actions
    private func handleComplete() {
        guard let user = currentUser else { return }
        
        // Final reward calculation
        let taskDuration = task.endTime.timeIntervalSince(task.startTime)
        let actualDuration = elapsedTime - totalPausedDuration
        let completionRatio = min(1.0, actualDuration / taskDuration)
        
        // Base rewards
        let baseXP = 10
        let baseCrystals = 5
        
        // Bonus for completing full duration
        let bonusXP = completionRatio >= 0.9 ? Int(Double(baseXP) * 0.5) : 0
        let bonusCrystals = completionRatio >= 0.9 ? Int(Double(baseCrystals) * 0.5) : 0
        
        let finalXP = baseXP + bonusXP + accumulatedXP
        let finalCrystals = baseCrystals + bonusCrystals + accumulatedCrystals
        
        // Award rewards
        user.currentXP += finalXP
        user.gamificationCurrency += finalCrystals
        
        // Mark task as complete
        task.isComplete = true
        
        try? modelContext.save()
        
        // Clean up Dynamic Island
        cleanupDynamicIsland()
        
        // Show completion summary
        accumulatedXP = finalXP
        accumulatedCrystals = finalCrystals
        showingCompletionSummary = true
    }
    
    private func handleSkip() {
        // No rewards for skipping
        cleanupDynamicIsland()
        onDismiss()
    }
    
    private func handleDismiss() {
        // If user leaves abruptly, award partial points based on time spent
        if elapsedTime - totalPausedDuration > 60 { // At least 1 minute
            let partialXP = Int((elapsedTime - totalPausedDuration) / 60) * 2 // 2 XP per minute
            let partialCrystals = Int((elapsedTime - totalPausedDuration) / 120) // 1 crystal per 2 minutes
            
            if let user = currentUser {
                user.currentXP += partialXP
                user.gamificationCurrency += partialCrystals
                try? modelContext.save()
            }
        }
        
        cleanupDynamicIsland()
        onDismiss()
    }
    
    // MARK: - Dynamic Island
    private func setupDynamicIsland() {
        if #available(iOS 16.1, *) {
            let taskDuration = task.endTime.timeIntervalSince(task.startTime)
            let timeRemaining = max(0, taskDuration - elapsedTime)
            
            _Concurrency.Task {
                try? await ActivityKitService.shared.startImmersiveActivity(
                taskTitle: task.title,
                timeRemaining: timeRemaining
            )
            }
        }
    }
    
    private func cleanupDynamicIsland() {
        if #available(iOS 16.1, *) {
            _Concurrency.Task {
                await ActivityKitService.shared.endImmersiveActivity()
            }
        }
    }
    
    private func updateDynamicIsland() {
        if #available(iOS 16.1, *) {
            let taskDuration = task.endTime.timeIntervalSince(task.startTime)
            let timeRemaining = max(0, taskDuration - (elapsedTime - totalPausedDuration))
            
            _Concurrency.Task {
                await ActivityKitService.shared.updateImmersiveActivity(timeRemaining: timeRemaining)
            }
        }
    }
    
    // Get next task in routine (if this is part of a routine)
    private func getNextTaskInRoutine() -> Task? {
        guard let routineID = task.routineID else { return nil }
        let routineTasks = allTasks.filter { $0.routineID == routineID }
            .sorted { $0.startTime < $1.startTime }
        
        if let currentIndex = routineTasks.firstIndex(where: { $0.id == task.id }),
           currentIndex + 1 < routineTasks.count {
            return routineTasks[currentIndex + 1]
        }
        return nil
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Task Block Item View (Theme-Aware)
struct TaskBlockItemView: View {
    let task: Task
    let taskNumber: Int
    let isCurrent: Bool
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return HStack(spacing: 8) {
            if isCurrent {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 8, height: 8)
            }
            
            Text("TASK \(taskNumber)")
                .appTextStyle(.caption, theme: theme)
                .textCase(.uppercase)
                .fontWeight(isCurrent ? .bold : .regular)
        }
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding / 2)
        .background(
            Capsule()
                .fill(isCurrent ? theme.accentColor.opacity(0.3) : theme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
}

// MARK: - Completion Summary View (Theme-Aware)
struct ImmersiveCompletionSummaryView: View {
    let task: Task
    let elapsedTime: TimeInterval
    let xpEarned: Int
    let crystalsEarned: Int
    let onDismiss: () -> Void
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return NavigationStack {
            ZStack {
                theme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: theme.sectionSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(theme.accentColor)
                    
                    Text("TASK COMPLETED!")
                        .appTextStyle(.pageHeader, theme: theme)
                        .textCase(.uppercase)
                    
                    Text(task.title)
                        .appTextStyle(.title, theme: theme)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: theme.itemSpacing) {
                        rewardRow(icon: "star.fill", label: "XP Earned", value: "\(xpEarned)", color: theme.accentColor)
                        rewardRow(icon: "sparkles", label: "Crystals Earned", value: "\(crystalsEarned)", color: theme.accentColor)
                        rewardRow(icon: "clock.fill", label: "Time Spent", value: formatTime(elapsedTime), color: theme.accentColor)
                    }
                    .padding(theme.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .fill(theme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                    )
                    .padding(.horizontal)
                    
                    Button(action: onDismiss) {
                        Text("CONTINUE")
                            .appTextStyle(.body, theme: theme)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity)
                            .padding(theme.cardPadding)
                            .background(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .fill(theme.accentColor)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func rewardRow(icon: String, label: String, value: String, color: Color) -> some View {
        let theme = themeManager.currentTheme
        
        return HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(label)
                .appTextStyle(.body, theme: theme)
            
            Spacer()
            
            Text(value)
                .appTextStyle(.title, theme: theme)
                .foregroundColor(color)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

#Preview {
    ImmersiveWorkingOnView(
        task: Task(
            userID: "preview-user",
            title: "Sample Task",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            category: .work
        )
    ) {
        print("Dismissed")
    }
}
