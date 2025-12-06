//
//  MoodJarService.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

enum MoodJarService {
    
    // MARK: - Check-In Validation
    
    /// Check if user can check in at current time
    static func canCheckIn(currentTime: Date = Date()) -> (allowed: Bool, period: CheckInTime?) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // Check each time window
        for period in CheckInTime.allCases {
            let window = period.timeWindow
            let currentTimeMinutes = hour * 60 + minute
            
            // Morning: 5:00 AM - 11:59 AM (300 - 719 minutes)
            // Afternoon: 12:00 PM - 4:59 PM (720 - 1079 minutes)
            // Night: 5:00 PM - 11:59 PM (1020 - 1439 minutes)
            let windowStartMinutes = window.start * 60
            let windowEndMinutes = window.end * 60 + 59 // Include 59 minutes
            
            if currentTimeMinutes >= windowStartMinutes && currentTimeMinutes <= windowEndMinutes {
                return (true, period)
            }
        }
        
        return (false, nil)
    }
    
    /// Get current check-in period if within window
    static func currentCheckInPeriod(currentTime: Date = Date()) -> CheckInTime? {
        let result = canCheckIn(currentTime: currentTime)
        return result.period
    }
    
    /// Check if user has already checked in for current period today
    static func hasCheckedInToday(user: User, period: CheckInTime) -> Bool {
        guard let moodHistory = user.moodHistory else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return moodHistory.contains { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today) &&
            entry.checkInTime == period
        }
    }
    
    /// Check if user has reached max check-ins for today
    static func hasMaxCheckInsToday(user: User) -> Bool {
        guard let moodHistory = user.moodHistory else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todayEntries = moodHistory.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
        
        return todayEntries.count >= 3 // Maximum 3 check-ins per day
    }
    
    // MARK: - Add Mood Entry
    
    static func addMoodEntry(
        user: User,
        mood: MoodType,
        period: CheckInTime? = nil,
        notes: String? = nil,
        context: ModelContext
    ) -> Bool {
        // Get current period if not provided
        let checkInPeriod = period ?? currentCheckInPeriod() ?? .afternoon
        
        // Validate check-in time window
        // If outside window, only allow if user hasn't checked in today (minimum 1 check-in on app launch)
        if !canCheckIn().allowed {
            // Check if user has already checked in today - if yes, deny (outside window and already checked in)
            if hasCheckedInToday(user: user, period: checkInPeriod) {
                return false // Already checked in, can't check in again outside window
            }
            // Allow check-in on app launch even if outside window (minimum 1 check-in per day)
            // Continue to create the entry
        }
        
        // Check max check-ins
        guard !hasMaxCheckInsToday(user: user) else {
            return false
        }
        
        // Check if already checked in for this period
        guard !hasCheckedInToday(user: user, period: checkInPeriod) else {
            return false
        }
        
        // Create mood entry
        let entry = MoodEntry(
            userID: user.id,
            coreMood: mood.coreMood,
            subMood: mood.subMood,
            timestamp: Date(),
            checkInTime: checkInPeriod,
            notes: notes
        )
        
        entry.user = user
        
        // Add to user's mood history
        if user.moodHistory == nil {
            user.moodHistory = []
        }
        user.moodHistory?.append(entry)
        
        context.insert(entry)
        
        // Check for rewards
        if calculateMoodRewards(user: user, context: context) != nil {
            // Rewards will be applied by caller
            return true
        }
        
        return true
    }
    
    // MARK: - Mood Pattern Analysis
    
    static func analyzeMoodPattern(
        entries: [MoodEntry],
        days: Int = 7
    ) -> MoodPattern {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let recentEntries = entries.filter { $0.timestamp >= cutoffDate }
        
        // Count mood distribution
        var moodDistribution: [MoodType: Int] = [:]
        for entry in recentEntries {
            // Convert CoreMood to MoodType for compatibility
            let moodType = moodTypeFromCoreMood(entry.coreMood)
            moodDistribution[moodType, default: 0] += 1
        }
        
        // Find dominant mood
        let dominantMood = moodDistribution.max(by: { $0.value < $1.value })?.key ?? .calm
        
        // Calculate consistency (how similar moods are)
        let totalEntries = recentEntries.count
        let maxCount = moodDistribution.values.max() ?? 0
        let consistency = totalEntries > 0 ? Double(maxCount) / Double(totalEntries) : 0.0
        
        // Calculate trend (improving, declining, stable)
        let trend = calculateTrend(entries: recentEntries)
        
        return MoodPattern(
            dominantMood: dominantMood,
            moodDistribution: moodDistribution,
            consistency: consistency,
            trend: trend
        )
    }
    
    static func calculateTrend(entries: [MoodEntry]) -> MoodTrend {
        guard entries.count >= 5 else { return .stable }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        
        // Split into first half and second half
        let midpoint = sortedEntries.count / 2
        let firstHalf = Array(sortedEntries.prefix(midpoint))
        let secondHalf = Array(sortedEntries.suffix(midpoint))
        
        // Calculate average mood score (positive moods = 1, negative = -1)
        func averageMoodScore(_ entries: [MoodEntry]) -> Double {
            let scores = entries.map { entry in
                let moodType = moodTypeFromCoreMood(entry.coreMood)
                return moodType.isPositive ? 1.0 : -1.0
            }
            return scores.reduce(0, +) / Double(scores.count)
        }
        
        let firstScore = averageMoodScore(firstHalf)
        let secondScore = averageMoodScore(secondHalf)
        
        if secondScore > firstScore + 0.2 {
            return .improving
        } else if secondScore < firstScore - 0.2 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Mood Rewards
    
    static func calculateMoodRewards(user: User, context: ModelContext) -> MoodReward? {
        guard let moodHistory = user.moodHistory, !moodHistory.isEmpty else {
            return nil
        }
        
        let pattern = analyzeMoodPattern(entries: Array(moodHistory))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get entries from last 7 days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let recentEntries = moodHistory.filter { $0.timestamp >= sevenDaysAgo }
        
        // Check for reward conditions
        var crystals: Int? = nil
        var xp: Int? = nil
        var themeUnlock: String? = nil
        
        // 7-Day Completion: Any 7 days of check-ins
        let uniqueDays = Set(recentEntries.map { calendar.startOfDay(for: $0.timestamp) }).count
        if uniqueDays >= 7 {
            crystals = (crystals ?? 0) + 200
            xp = (xp ?? 0) + 100
        }
        
        // Mood Collection: 10+ of specific mood type
        for (_, count) in pattern.moodDistribution {
            if count >= 10 {
                crystals = (crystals ?? 0) + 300
                xp = (xp ?? 0) + 150
                break // Only one reward per check
            }
        }
        
        // Balanced Week: Equal mix of positive/neutral moods
        let positiveCount = recentEntries.filter { entry in
            let moodType = moodTypeFromCoreMood(entry.coreMood)
            return moodType.isPositive
        }.count
        let totalCount = recentEntries.count
        if totalCount >= 14 && Double(positiveCount) / Double(totalCount) >= 0.5 {
            crystals = (crystals ?? 0) + 250
            xp = (xp ?? 0) + 125
            themeUnlock = "balanced"
        }
        
        // Improving Trend: 5+ days showing improvement
        if pattern.trend == .improving && uniqueDays >= 5 {
            crystals = (crystals ?? 0) + 400
            xp = (xp ?? 0) + 200
        }
        
        // Perfect Week: All 3 check-ins daily for 7 days (21 entries)
        if recentEntries.count >= 21 {
            crystals = (crystals ?? 0) + 500
            xp = (xp ?? 0) + 250
            themeUnlock = themeUnlock ?? "consistency"
        }
        
        // Apply rewards if any
        if let crystalsReward = crystals, let xpReward = xp {
            user.gamificationCurrency += crystalsReward
            user.currentXP += xpReward
            user.moodJarCompletions += 1
            
            // Update user level if needed
            if LevelService.checkLevelUp(user: user, newXP: user.currentXP) != nil {
                // Handle level up (caller should show animation)
            }
            
            try? context.save()
            
            return MoodReward(
                crystals: crystalsReward,
                xp: xpReward,
                themeUnlock: themeUnlock
            )
        }
        
        return nil
    }
    
    // MARK: - Check Mood Requirements
    
    static func checkMoodRequirement(_ requirement: MoodRequirement, user: User) -> Bool {
        guard let moodHistory = user.moodHistory else { return false }
        
        // Check pattern-based requirements
        if let pattern = requirement.pattern {
            let moodPattern = analyzeMoodPattern(entries: Array(moodHistory))
            
            switch pattern {
            case "balanced":
                let positiveCount = moodHistory.filter { entry in
                    let moodType = moodTypeFromCoreMood(entry.coreMood)
                    return moodType.isPositive
                }.count
                let totalCount = moodHistory.count
                return totalCount >= 14 && Double(positiveCount) / Double(totalCount) >= 0.5
                
            case "improving":
                return moodPattern.trend == .improving
                
            case "perfect_week":
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
                let recentEntries = moodHistory.filter { $0.timestamp >= sevenDaysAgo }
                return recentEntries.count >= 21
                
            default:
                break
            }
        }
        
        // Check mood count requirements
        var moodCounts: [MoodType: Int] = [:]
        for entry in moodHistory {
            // Convert CoreMood to MoodType for compatibility
            let moodType = moodTypeFromCoreMood(entry.coreMood)
            moodCounts[moodType, default: 0] += 1
        }
        
        for requiredMood in requirement.requiredMoods {
            if (moodCounts[requiredMood] ?? 0) < requirement.requiredCount {
                return false
            }
        }
        
        return true
    }
}

struct MoodPattern {
    var dominantMood: MoodType
    var moodDistribution: [MoodType: Int]
    var consistency: Double // 0-1 scale
    var trend: MoodTrend // improving, declining, stable
}

enum MoodTrend {
    case improving, declining, stable
}

// MARK: - Helper Functions

/// Convert CoreMood to MoodType for backwards compatibility
private func moodTypeFromCoreMood(_ coreMood: CoreMood) -> MoodType {
    switch coreMood {
    case .happy: return .happy
    case .sad: return .sad
    case .anxious: return .anxious
    case .calm: return .calm
    case .energetic: return .energetic
    case .tired: return .tired
    }
}

struct MoodReward {
    var crystals: Int
    var xp: Int
    var themeUnlock: String?
}

