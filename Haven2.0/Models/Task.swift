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
    var goalID: String?
    var taskBlockID: String? // New: Link to task block
    var color: String? // New: Custom color for task
    var completionAnimation: Bool // New: For cross-out animation
    var isLocked: Bool = false // New: For routine tasks that can't be moved
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         taskDescription: String? = nil,
         startTime: Date,
         endTime: Date,
         priority: PriorityType = .normal,
         category: TaskCategory = .personal,
         isComplete: Bool = false,
         goalID: String? = nil,
         taskBlockID: String? = nil,
         color: String? = nil) {
        self.id = id
        self.userID = userID
        self.title = title
        self.taskDescription = taskDescription
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.category = category
        self.isComplete = isComplete
        self.goalID = goalID
        self.taskBlockID = taskBlockID
        self.color = color
        self.completionAnimation = false
    }
}

enum PriorityType: String, CaseIterable, Codable {
    case urgent = "urgent"
    case high = "high"
    case normal = "normal"
    
    var color: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .normal: return "green"
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
        case .fixed: return "Fixed"
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
        case .fixed: return "clock.fill"
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
        case .personal: return .green
        case .fixed: return .orange
        case .flexible: return .purple
        case .hobbies: return .pink
        case .selfCare: return .mint
        case .leisure: return .cyan
        case .growth: return .indigo
        case .reading: return .brown
        case .skinCare: return .yellow
        }
    }
}
