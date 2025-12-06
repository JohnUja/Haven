//
//  Task.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Task {
    var id: String
    var userID: String
    var title: String
    var taskDescription: String?
    var startTime: Date
    var endTime: Date
    var priority: PriorityType
    var category: TaskCategory
    var isComplete: Bool
    // Relationships (replaced String IDs)
    var goal: Goal?
    var milestone: GoalMilestone?
    var taskBlock: TaskBlock?
    var color: String? // New: Custom color for task
    var completionAnimation: Bool // New: For cross-out animation
    var isLocked: Bool = false // New: For routine tasks that can't be moved
    var recurrenceSeriesID: String? // New: Link occurrences of a recurring series
    var hasBeenRewarded: Bool = false // Track if rewards already given to prevent duplicates
    var isRoutineTask: Bool = false // New: Indicates if task was generated from a routine
    var routineID: String? // New: Links to DailyRoutine that created this task
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         taskDescription: String? = nil,
         startTime: Date,
         endTime: Date,
         priority: PriorityType = .normal,
         category: TaskCategory = .personal,
         isComplete: Bool = false,
         goal: Goal? = nil,
         milestone: GoalMilestone? = nil,
         taskBlock: TaskBlock? = nil,
         color: String? = nil,
         recurrenceSeriesID: String? = nil,
         hasBeenRewarded: Bool = false,
         isRoutineTask: Bool = false,
         routineID: String? = nil) {
        self.id = id
        self.userID = userID
        self.title = title
        self.taskDescription = taskDescription
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.category = category
        self.isComplete = isComplete
        self.goal = goal
        self.milestone = milestone
        self.taskBlock = taskBlock
        self.color = color
        self.completionAnimation = false
        self.recurrenceSeriesID = recurrenceSeriesID
        self.hasBeenRewarded = hasBeenRewarded
        self.isRoutineTask = isRoutineTask
        self.routineID = routineID
        
        // Auto-lock routine tasks
        if isRoutineTask {
            self.isLocked = true
        }
    }
}

enum PriorityType: String, CaseIterable, Codable {
    case urgent = "urgent"
    case high = "high"
    case normal = "normal"
    case low = "low"
    
    var color: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .normal: return "green"
        case .low: return "blue"
        }
    }
}

enum RecurrenceType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekdays = "weekdays"
    case weekly = "weekly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays Only"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case work = "work"
    case personal = "personal"
    case fixed = "fixed"
    case flexible = "flexible"
    case hobbies = "hobbies"
    case selfCare = "selfCare"
    case leisure = "leisure"
    case growth = "growth"
    case reading = "reading"
    case skinCare = "skinCare"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .fixed: return "Health"
        case .flexible: return "Flexible"
        case .hobbies: return "Hobbies"
        case .selfCare: return "Self Care"
        case .leisure: return "Leisure"
        case .growth: return "Growth"
        case .reading: return "Reading"
        case .skinCare: return "Skin Care"
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .fixed: return "heart.circle.fill" // Health icon - more fitting
        case .flexible: return "arrow.triangle.2.circlepath"
        case .hobbies: return "paintbrush.fill"
        case .selfCare: return "heart.fill"
        case .leisure: return "gamecontroller.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .reading: return "book.fill"
        case .skinCare: return "sparkles"
        }
    }
    
    func color() -> Color {
        switch self {
        case .work: return .blue
        case .personal: return .purple
        case .fixed: return .red // Health - red
        case .flexible: return .green
        case .hobbies: return .orange // Changed to orange
        case .selfCare: return .pink // Changed to pink
        case .leisure: return .teal
        case .growth: return .purple.opacity(0.8)
        case .reading: return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        case .skinCare: return Color(red: 1.0, green: 0.84, blue: 0.0) // Golden
        }
    }
}