//
//  GamificationService.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

// Freeze-investigation logging was intentionally disabled after the audit cleanup.
@inline(__always)
fileprivate func debugLog(location: String, message: String, data: [String: Any] = [:], hypothesisId: String = "") {}

enum GamificationService {
    
    // MARK: - Task Reward Calculation
    
    static func calculateTaskRewards(
        task: Task,
        goal: Goal?,
        momentumBonus: Double
    ) -> (crystals: Int, xp: Int, score: Int) {
        // #region agent log
        let calcStartTime = Date()
        debugLog(location: "GamificationService:calculateTaskRewards", message: "calculateTaskRewards started", data: ["taskId": task.id, "priority": task.priority.rawValue, "category": task.category.rawValue, "hasGoal": goal != nil, "momentumBonus": momentumBonus] as [String: Any], hypothesisId: "H")
        // #endregion
        
        // Base crystals by priority
        let baseCrystals: Int
        switch task.priority {
        case .urgent: baseCrystals = 15
        case .high: baseCrystals = 10
        case .normal: baseCrystals = 5
        case .low: baseCrystals = 3
        }
        
        // Category multiplier
        let categoryMultiplier: Double
        switch task.category {
        case .growth: categoryMultiplier = 1.5
        case .selfCare: categoryMultiplier = 1.3
        case .hobbies: categoryMultiplier = 1.2
        default: categoryMultiplier = 1.0
        }
        
        var crystalAmount = Double(baseCrystals) * categoryMultiplier
        
        // Goal bonuses
        if let goal = goal {
            crystalAmount *= 1.5 // +50% for goal-linked tasks
            
            if goal.effectivePriority == .critical {
                crystalAmount *= 1.5 // Additional +50% for critical goals
            }
        }
        
        // Time bonuses (on-time, early)
        let now = Date()
        let timeDifference = task.endTime.timeIntervalSince(now)
        let duration = task.endTime.timeIntervalSince(task.startTime)
        
        if timeDifference >= 0 && timeDifference <= duration {
            crystalAmount *= 1.2 // +20% on-time
        } else if timeDifference > duration {
            crystalAmount *= 1.1 // +10% early
        }
        // Late completion gets no bonus
        
        // Apply momentum bonus
        crystalAmount *= momentumBonus
        
        // #region agent log
        debugLog(location: "GamificationService:calculateTaskRewards", message: "Crystal calculation complete", data: ["taskId": task.id, "baseCrystals": baseCrystals, "categoryMultiplier": categoryMultiplier, "crystalAmount": crystalAmount, "momentumBonus": momentumBonus] as [String: Any], hypothesisId: "H")
        // #endregion
        
        // Base XP
        var xpAmount: Double = 10.0
        
        // Priority multiplier for XP
        switch task.priority {
        case .urgent: xpAmount *= 1.5
        case .high: xpAmount *= 1.3
        case .normal: xpAmount *= 1.0
        case .low: xpAmount *= 0.8
        }
        
        // Goal-linked XP bonus
        if goal != nil {
            xpAmount *= 1.5 // +50% XP for goal-linked tasks
        }
        
        // Apply momentum bonus to XP
        xpAmount *= momentumBonus
        
        // Productivity Score calculation (original higher values)
        var productivityScore: Double = 10.0 // Base score
        
        // Priority multiplier for score
        switch task.priority {
        case .urgent: productivityScore *= 2.0
        case .high: productivityScore *= 1.5
        case .normal: productivityScore *= 1.0
        case .low: productivityScore *= 0.5
        }
        
        // Goal-linked score bonus
        if goal != nil {
            productivityScore *= 1.3 // +30%
        }
        
        // Time bonus for score
        if timeDifference >= 0 && timeDifference <= duration {
            productivityScore += 20.0 // +20 points for on-time
        } else if timeDifference > duration {
            productivityScore += 10.0 // +10 points for early
        }
        
        let result = (
            crystals: Int(crystalAmount.rounded()),
            xp: Int(xpAmount.rounded()),
            score: Int(productivityScore.rounded())
        )
        
        // #region agent log
        let calcDuration = Date().timeIntervalSince(calcStartTime)
        debugLog(location: "GamificationService:calculateTaskRewards", message: "calculateTaskRewards completed", data: ["taskId": task.id, "crystals": result.crystals, "xp": result.xp, "score": result.score, "duration": calcDuration] as [String: Any], hypothesisId: "H")
        // #endregion
        
        return result
    }
    
    // MARK: - Momentum System
    
    static func updateMomentumDays(user: User, tasks: [Task]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we've already updated today
        if let lastUpdate = user.lastMomentumUpdate,
           calendar.isDate(lastUpdate, inSameDayAs: today) {
            return user.momentumDays
        }
        
        // Get completed tasks for today
        let todayTasks = tasks.filter { task in
            calendar.isDate(task.startTime, inSameDayAs: today) && task.isComplete
        }
        
        if !todayTasks.isEmpty {
            // Has completed tasks today - increment momentum
            user.momentumDays += 1
            user.lastMomentumUpdate = today
        } else {
            // No tasks completed today - graceful degradation (reduce by 2-3 days)
            user.momentumDays = max(0, user.momentumDays - 2)
            user.lastMomentumUpdate = today
        }
        
        return user.momentumDays
    }
    
    static func getMomentumBonus(user: User) -> Double {
        let days = user.momentumDays
        switch days {
        case 0..<2: return 1.0 // No bonus
        case 2..<4: return 1.10 // +10%
        case 4..<7: return 1.20 // +20%
        case 7..<14: return 1.30 // +30%
        case 14..<30: return 1.40 // +40%
        default: return 1.50 // +50% for 30+ days
        }
    }
    
    // MARK: - Weekly Reset
    
    static func resetWeeklyScores(user: User) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current week (Monday)
        let weekday = calendar.component(.weekday, from: now)
        let daysToSubtract = (weekday + 5) % 7 // Convert to Monday = 0
        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
        let weekStartStartOfDay = calendar.startOfDay(for: weekStart)
        
        // Check if we need to reset
        if let lastReset = user.weeklyResetDate {
            if !calendar.isDate(lastReset, inSameDayAs: weekStartStartOfDay) {
                // New week started - reset score
                user.weeklyProductivityScore = 0
                user.weeklyResetDate = weekStartStartOfDay
            }
        } else {
            // First time - set reset date
            user.weeklyResetDate = weekStartStartOfDay
            user.weeklyProductivityScore = 0
        }
    }
    
    // MARK: - Special Completion Bonuses
    
    static func calculateFirstTaskBonus() -> (crystals: Int, xp: Int) {
        return (crystals: 5, xp: 20)
    }
    
    static func calculateMilestoneCompletionBonus() -> (crystals: Int, xp: Int, score: Int) {
        return (crystals: 100, xp: 200, score: 50)
    }
    
    static func calculateGoalCompletionBonus() -> (crystals: Int, xp: Int, score: Int) {
        return (crystals: 200, xp: 500, score: 500)
    }
    
    static func calculateDailyTaskBonus(completedTasks: Int) -> (crystals: Int, xp: Int) {
        if completedTasks >= 5 {
            return (crystals: 0, xp: 50)
        }
        return (crystals: 0, xp: 0)
    }
    
    // MARK: - Time-Based Rewards
    
    /// Calculate time-based rewards for individual tasks
    static func calculateTimeBasedTaskRewards(task: Task) -> (crystals: Int, xp: Int) {
        let duration = task.endTime.timeIntervalSince(task.startTime)
        let hours = duration / 3600
        
        let baseXP = 15
        let baseCrystals = 7
        
        let timeMultiplier: Double
        switch hours {
        case 0..<0.5: // Less than 30 min
            timeMultiplier = 0.7
        case 0.5..<1: // 30 min - 1 hour
            timeMultiplier = 1.0
        case 1..<3: // 1-3 hours
            timeMultiplier = 1.3
        case 3..<6: // 3-6 hours
            timeMultiplier = 1.6
        default: // 6+ hours
            timeMultiplier = 2.0
        }
        
        return (
            crystals: Int(Double(baseCrystals) * timeMultiplier),
            xp: Int(Double(baseXP) * timeMultiplier)
        )
    }
    
    /// Calculate rewards for task blocks based on total duration
    static func calculateTaskBlockRewards(tasks: [Task]) -> (crystals: Int, xp: Int) {
        guard !tasks.isEmpty else { return (crystals: 0, xp: 0) }
        
        // Calculate total duration of the block
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        let startTime = sortedTasks.first?.startTime ?? Date()
        let endTime = sortedTasks.last?.endTime ?? Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        let hours = totalDuration / 3600
        
        // Base rewards scaled by duration
        let baseXP = 50 // Base XP for completing a block
        let baseCrystals = 25 // Base crystals
        
        // Time-based multipliers
        let timeMultiplier: Double
        switch hours {
        case 0..<1:
            timeMultiplier = 1.0 // 1 hour or less
        case 1..<3:
            timeMultiplier = 1.5 // 1-3 hours
        case 3..<6:
            timeMultiplier = 2.0 // 3-6 hours
        default:
            timeMultiplier = 2.5 // 6+ hours
        }
        
        // Also scale by number of tasks (more tasks = more effort)
        let taskCountMultiplier = min(1.0 + (Double(tasks.count - 1) * 0.1), 2.0) // Cap at 2x
        
        let xp = Int(Double(baseXP) * timeMultiplier * taskCountMultiplier)
        let crystals = Int(Double(baseCrystals) * timeMultiplier * taskCountMultiplier)
        
        return (crystals: crystals, xp: xp)
    }
}

