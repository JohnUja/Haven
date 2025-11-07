//
//  Goal.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class GoalMilestone {
    var id: String
    var title: String
    var targetValue: Int
    var isComplete: Bool
    var deadline: Date?
    
    init(id: String = UUID().uuidString, title: String, targetValue: Int, isComplete: Bool = false, deadline: Date? = nil) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.isComplete = isComplete
        self.deadline = deadline
    }
}

enum GoalStatus: String, CaseIterable, Codable {
    case active
    case paused
    case completed
    case atRisk
}

enum GoalPriority: String, CaseIterable, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case critical = "Critical"
    
    var order: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .green
        case .high: return .orange
        case .critical: return .red
        }
    }
}

@Model
final class Goal {
    var id: String
    var userID: String
    var title: String
    var goalDescription: String?
    var category: GoalCategory
    var priority: GoalPriority?
    var targetValue: Int
    var currentValue: Int
    var status: GoalStatus
    var createdAt: Date
    var startDate: Date
    var deadline: Date?
    var milestones: [GoalMilestone]
    var timeCrystalsReward: Int = 10
    var themeReward: String?
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         goalDescription: String? = nil,
         category: GoalCategory,
         priority: GoalPriority = .normal,
         targetValue: Int,
         currentValue: Int = 0,
         status: GoalStatus = .active,
         createdAt: Date = Date(),
         startDate: Date = Date(),
         deadline: Date? = nil,
         milestones: [GoalMilestone] = [],
         timeCrystalsReward: Int = 10,
         themeReward: String? = nil) {
        self.id = id
        self.userID = userID
        self.title = title
        self.goalDescription = goalDescription
        self.category = category
        self.priority = priority
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.status = status
        self.createdAt = createdAt
        self.startDate = startDate
        self.deadline = deadline
        self.milestones = milestones
        self.timeCrystalsReward = timeCrystalsReward
        self.themeReward = themeReward
    }
    
    // Auto-calculate target from linked tasks (milestone tasks if using milestones, otherwise direct goal tasks)
    func effectiveTargetValue(tasks: [Task]) -> Int {
        // If using milestones, count all tasks in milestones
        if !milestones.isEmpty {
            return tasks.filter { task in
                task.goalID == self.id && task.milestoneID != nil
            }.count
        } else {
            // Otherwise count tasks linked directly to goal
            return tasks.filter { task in
                task.goalID == self.id && task.milestoneID == nil
            }.count
        }
    }
    
    func progressPercentage(tasks: [Task] = []) -> Double {
        let effectiveTarget = tasks.isEmpty ? targetValue : effectiveTargetValue(tasks: tasks)
        guard effectiveTarget > 0 else { return 0 }
        return min(Double(currentValue) / Double(effectiveTarget), 1.0)
    }
    
    // Safe accessor for priority (handles existing goals without priority)
    var effectivePriority: GoalPriority {
        return priority ?? .normal
    }
}

enum GoalCategory: String, CaseIterable, Codable {
    case health = "health"
    case work = "work"
    case learning = "learning"
    case personal = "personal"
    case financial = "financial"
    case fitness = "fitness"
    case creative = "creative"
    case social = "social"
    case spiritual = "spiritual"
    case productivity = "productivity"
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .work: return "Work"
        case .learning: return "Learning"
        case .personal: return "Personal"
        case .financial: return "Financial"
        case .fitness: return "Fitness"
        case .creative: return "Creative"
        case .social: return "Social"
        case .spiritual: return "Spiritual"
        case .productivity: return "Productivity"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.circle.fill"
        case .work: return "briefcase.fill"
        case .learning: return "graduationcap.fill"
        case .personal: return "heart.text.square.fill"
        case .financial: return "dollarsign.circle.fill"
        case .fitness: return "figure.strengthtraining.traditional"
        case .creative: return "paintbrush.fill"
        case .social: return "person.2.fill"
        case .spiritual: return "leaf.circle.fill"
        case .productivity: return "target"
        }
    }
    
    var colorString: String {
        switch self {
        case .health: return "green"
        case .work: return "blue"
        case .learning: return "purple"
        case .personal: return "orange"
        case .financial: return "yellow"
        case .fitness: return "red"
        case .creative: return "pink"
        case .social: return "cyan"
        case .spiritual: return "mint"
        case .productivity: return "indigo"
        }
    }
    
    func color() -> Color {
        switch self {
        case .health: return .green
        case .work: return .blue
        case .learning: return .purple
        case .personal: return .orange
        case .financial: return .yellow
        case .fitness: return .red
        case .creative: return .pink
        case .social: return .cyan
        case .spiritual: return .mint
        case .productivity: return .indigo
        }
    }
}
