//
//  DailyRewardService.swift
//  Haven2.0
//
//  Created by AI on 2025-01-13.
//  Duolingo-style reward checking when app opens
//

import Foundation

@MainActor
class DailyRewardService {
    static let shared = DailyRewardService()
    
    private let lastRewardCheckKey = "lastRewardCheckDate"
    private let lastAppCloseTimeKey = "lastAppCloseTime"
    
    private init() {}
    
    // MARK: - Save App Close Time
    func saveAppCloseTime() {
        UserDefaults.standard.set(Date(), forKey: lastAppCloseTimeKey)
    }
    
    // MARK: - Check for Earned Rewards (Duolingo Style)
    func checkForEarnedRewards() -> (xp: Int, crystals: Int, date: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last app close time
        guard let lastCloseTime = UserDefaults.standard.object(forKey: lastAppCloseTimeKey) as? Date else {
            // First time opening - no rewards to show
            saveAppCloseTime()
            return nil
        }
        
        // Get last reward check date
        let lastCheckDate = UserDefaults.standard.object(forKey: lastRewardCheckKey) as? Date
        
        // Check if we've already shown rewards for today
        if let lastCheck = lastCheckDate, calendar.isDate(lastCheck, inSameDayAs: now) {
            // Already checked today
            return nil
        }
        
        // Calculate time since last close
        let timeSinceClose = now.timeIntervalSince(lastCloseTime)
        let hoursSinceClose = timeSinceClose / 3600
        
        // Only show if app was closed for more than 1 hour
        guard hoursSinceClose >= 1.0 else {
            return nil
        }
        
        // Mark that we've checked today
        UserDefaults.standard.set(now, forKey: lastRewardCheckKey)
        
        // Return the date to check for rewards (yesterday or the day before app closed)
        let checkDate = calendar.isDate(lastCloseTime, inSameDayAs: now) ? 
            calendar.date(byAdding: .day, value: -1, to: now) ?? now :
            lastCloseTime
        
        // Return placeholder values - actual values will be calculated from completed tasks
        return (xp: 0, crystals: 0, date: checkDate)
    }
}

