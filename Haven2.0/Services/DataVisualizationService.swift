//
//  DataVisualizationService.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import Foundation
import SwiftData
import SwiftUI

class DataVisualizationService {
    static let shared = DataVisualizationService()
    
    private init() {}
    
    // MARK: - CSV Export
    func exportToCSV(user: User, tasks: [Task], goals: [Goal], moodEntries: [MoodEntry], routines: [DailyRoutine]) -> String {
        var csv = "Date,Tasks Completed,XP Gained,Time Crystals,Mood,Goal Progress,Routine Completed\n"
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        // Group data by day
        var dailyData: [Date: DailyStats] = [:]
        
        // Process tasks
        for task in tasks {
            if task.isComplete {
                let day = calendar.startOfDay(for: task.endTime)
                if day >= startDate {
                    if dailyData[day] == nil {
                        dailyData[day] = DailyStats(date: day)
                    }
                    dailyData[day]?.tasksCompleted += 1
                }
            }
        }
        
        // Process mood entries
        for mood in moodEntries {
            let day = calendar.startOfDay(for: mood.timestamp)
            if day >= startDate {
                if dailyData[day] == nil {
                    dailyData[day] = DailyStats(date: day)
                }
                dailyData[day]?.mood = mood.coreMood.rawValue
            }
        }
        
        // Sort by date
        let sortedDates = dailyData.keys.sorted()
        
        // Build CSV
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for date in sortedDates {
            guard let stats = dailyData[date] else { continue }
            let dateStr = dateFormatter.string(from: date)
            let moodStr = stats.mood ?? "N/A"
            csv += "\(dateStr),\(stats.tasksCompleted),\(stats.xpGained),\(stats.crystalsGained),\(moodStr),\(stats.goalProgress),\(stats.routineCompleted)\n"
        }
        
        return csv
    }
    
    // MARK: - Consistency Heatmap Data
    func getConsistencyHeatmapData(user: User, tasks: [Task], startDate: Date, endDate: Date) -> [Date: Int] {
        let calendar = Calendar.current
        var heatmapData: [Date: Int] = [:]
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // Count tasks completed on this day
            let tasksOnDay = tasks.filter { task in
                task.isComplete &&
                task.endTime >= dayStart &&
                task.endTime < dayEnd &&
                task.userID == user.id
            }
            
            heatmapData[dayStart] = tasksOnDay.count
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return heatmapData
    }
    
    // MARK: - Activity & Mood Correlation Data
    func getActivityMoodCorrelation(user: User, tasks: [Task], moodEntries: [MoodEntry]) -> [(activity: Int, mood: Double)] {
        let calendar = Calendar.current
        var correlationData: [(activity: Int, mood: Double)] = []
        
        // Group by day
        var dailyActivity: [Date: Int] = [:]
        var dailyMood: [Date: [CoreMood]] = [:]
        
        // Process tasks
        for task in tasks where task.isComplete && task.userID == user.id {
            let day = calendar.startOfDay(for: task.endTime)
            dailyActivity[day, default: 0] += 1
        }
        
        // Process moods
        for mood in moodEntries where mood.userID == user.id {
            let day = calendar.startOfDay(for: mood.timestamp)
            dailyMood[day, default: []].append(mood.coreMood)
        }
        
        // Calculate correlation
        for (date, activity) in dailyActivity {
            if let moods = dailyMood[date], !moods.isEmpty {
                let avgMoodScore = moods.map { moodScore($0) }.reduce(0, +) / Double(moods.count)
                correlationData.append((activity: activity, mood: avgMoodScore))
            }
        }
        
        return correlationData
    }
    
    // MARK: - Weekly Summary
    func getWeeklySummary(user: User, tasks: [Task], goals: [Goal], moodEntries: [MoodEntry]) -> WeeklySummary {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weekTasks = tasks.filter { task in
            task.isComplete &&
            task.endTime >= weekAgo &&
            task.userID == user.id
        }
        
        let weekGoals = goals.filter { goal in
            goal.status == .completed &&
            goal.userID == user.id
        }
        
        let weekMoods = moodEntries.filter { mood in
            mood.timestamp >= weekAgo &&
            mood.userID == user.id
        }
        
        return WeeklySummary(
            tasksCompleted: weekTasks.count,
            goalsCompleted: weekGoals.count,
            moodEntries: weekMoods.count,
            averageMood: weekMoods.isEmpty ? nil : weekMoods.map { moodScore($0.coreMood) }.reduce(0, +) / Double(weekMoods.count)
        )
    }
    
    // MARK: - Helper Functions
    private func moodScore(_ mood: CoreMood) -> Double {
        // Map moods to numeric scores (-2 to +2)
        switch mood {
        case .sad, .anxious: return -2.0
        case .tired: return -1.0
        case .calm: return 1.0
        case .happy, .energetic: return 2.0
        }
    }
}

// MARK: - Supporting Types
struct DailyStats {
    var date: Date
    var tasksCompleted: Int = 0
    var xpGained: Int = 0
    var crystalsGained: Int = 0
    var mood: String? = nil
    var goalProgress: Int = 0
    var routineCompleted: Int = 0
}

struct WeeklySummary {
    let tasksCompleted: Int
    let goalsCompleted: Int
    let moodEntries: Int
    let averageMood: Double?
}

