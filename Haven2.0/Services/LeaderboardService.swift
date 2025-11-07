//
//  LeaderboardService.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

enum LeaderboardService {
    
    // MARK: - Productivity Score Calculation
    
    /// Calculate weekly productivity score for a user
    static func calculateProductivityScore(
        user: User,
        tasks: [Task],
        goals: [Goal],
        weekStart: Date
    ) -> Int {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        
        // Get tasks completed this week
        let weekTasks = tasks.filter { task in
            task.isComplete &&
            task.startTime >= weekStart &&
            task.startTime < weekEnd
        }
        
        // Weekly Task Score (40%) - Original Higher Values
        var taskScore: Double = 0
        for task in weekTasks {
            var baseScore: Double = 10.0
            
            // Priority multiplier
            switch task.priority {
            case .urgent: baseScore *= 2.0
            case .high: baseScore *= 1.5
            case .normal: baseScore *= 1.0
            case .low: baseScore *= 0.5
            }
            
            // Goal-linked bonus
            if task.goalID != nil {
                baseScore *= 1.3 // +30%
            }
            
            taskScore += baseScore
        }
        // Cap at 200 points per day (max 1400 per week)
        taskScore = min(taskScore, 1400.0)
        
        // Goal Progress Score (30%) - Original Higher Values
        var goalScore: Double = 0
        for goal in goals.filter({ $0.status == .active || $0.status == .completed }) {
            // Check if goal made progress this week
            let goalTasks = weekTasks.filter { $0.goalID == goal.id }
            
            if !goalTasks.isEmpty {
                // Milestone progress bonus
                goalScore += 50.0
                
                // Goal completion bonus
                if goal.status == .completed {
                    goalScore += 500.0
                }
                
                // Critical priority bonus
                if goal.effectivePriority == .critical {
                    goalScore *= 1.5 // +50%
                }
            }
        }
        
        // Consistency Score (20%) - Original Higher Values
        var consistencyScore: Double = 0
        let uniqueDays = Set(weekTasks.map { calendar.startOfDay(for: $0.startTime) }).count
        
        switch uniqueDays {
        case 2...3: consistencyScore = 50.0
        case 4...6: consistencyScore = 100.0
        case 7: consistencyScore = 200.0
        default: consistencyScore = 0
        }
        
        // Quality Score (10%) - Original Higher Values
        var qualityScore: Double = 0
        
        // On-time completions
        let onTimeTasks = weekTasks.filter { task in
            let now = task.endTime
            let scheduledEnd = task.endTime
            let duration = task.endTime.timeIntervalSince(task.startTime)
            return now >= task.startTime && now.timeIntervalSince(scheduledEnd) <= duration
        }
        qualityScore += Double(onTimeTasks.count) * 20.0
        
        // Early completions
        let earlyTasks = weekTasks.filter { task in
            let now = task.endTime
            let scheduledEnd = task.endTime
            let duration = task.endTime.timeIntervalSince(task.startTime)
            return now > scheduledEnd.addingTimeInterval(duration)
        }
        qualityScore += Double(earlyTasks.count) * 10.0
        
        // Category balance bonus
        let uniqueCategories = Set(weekTasks.map { $0.category }).count
        if uniqueCategories >= 3 {
            qualityScore += 50.0
        }
        
        // Calculate final score
        let finalScore = (taskScore * 0.4) + (goalScore * 0.3) + (consistencyScore * 0.2) + (qualityScore * 0.1)
        
        return Int(finalScore.rounded())
    }
    
    // MARK: - Leaderboard Management
    
    /// Get leaderboard entries (currently local-only, placeholder for future social features)
    static func getLeaderboard(
        users: [User],
        tasks: [Task],
        goals: [Goal],
        location: String? = nil,
        radius: Double = 100.0 // miles
    ) -> [LeaderboardEntry] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysToSubtract = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
        let weekStartStartOfDay = calendar.startOfDay(for: weekStart)
        
        // Calculate scores for all users
        var entries: [LeaderboardEntry] = []
        
        for (index, user) in users.enumerated() {
            // Reset weekly score if needed
            resetWeeklyScores(user: user)
            
            // Calculate current week's productivity score
            let score = calculateProductivityScore(
                user: user,
                tasks: tasks.filter { $0.userID == user.id },
                goals: goals.filter { $0.userID == user.id },
                weekStart: weekStartStartOfDay
            )
            
            // Update user's weekly score
            user.weeklyProductivityScore = score
            
            let entry = LeaderboardEntry(
                userID: user.id,
                username: user.name,
                score: score,
                level: user.level,
                rank: 0 // Will be set after sorting
            )
            
            entries.append(entry)
        }
        
        // Sort by score (descending) and assign ranks
        entries.sort { $0.score > $1.score }
        for (index, _) in entries.enumerated() {
            entries[index].rank = index + 1
        }
        
        return entries
    }
    
    // MARK: - Weekly Reset
    
    static func resetWeeklyScores(user: User) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current week (Monday)
        let weekday = calendar.component(.weekday, from: now)
        let daysToSubtract = (weekday + 5) % 7
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
    
    // MARK: - Time Until Reset
    
    static func timeUntilReset() -> (days: Int, hours: Int) {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysToSubtract = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
        let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        
        let components = calendar.dateComponents([.day, .hour], from: now, to: nextWeekStart)
        return (days: components.day ?? 0, hours: components.hour ?? 0)
    }
}

struct LeaderboardEntry: Identifiable {
    var id: String { userID }
    var userID: String
    var username: String
    var score: Int
    var level: Int
    var rank: Int
}

