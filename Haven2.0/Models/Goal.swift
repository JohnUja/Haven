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
    
    init(id: String = UUID().uuidString, title: String, targetValue: Int, isComplete: Bool = false) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.isComplete = isComplete
    }
}

@Model
final class Goal {
    var id: String
    var userID: String
    var title: String
    var category: GoalCategory
    var targetValue: Int
    var currentValue: Int
    var isComplete: Bool
    var createdAt: Date
    var deadline: Date?
    var milestones: [GoalMilestone]
    var timeCrystalsReward: Int
    var themeReward: String?
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         category: GoalCategory,
         targetValue: Int,
         currentValue: Int = 0,
         isComplete: Bool = false,
         createdAt: Date = Date(),
         deadline: Date? = nil,
         milestones: [GoalMilestone] = [],
         timeCrystalsReward: Int = 10,
         themeReward: String? = nil) {
        self.id = id
        self.userID = userID
        self.title = title
        self.category = category
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isComplete = isComplete
        self.createdAt = createdAt
        self.deadline = deadline
        self.milestones = milestones
        self.timeCrystalsReward = timeCrystalsReward
        self.themeReward = themeReward
    }
    
    func progressPercentage() -> Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
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
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .learning: return "book.fill"
        case .personal: return "person.fill"
        case .financial: return "dollarsign.circle.fill"
        case .fitness: return "figure.run"
        case .creative: return "paintbrush.fill"
        case .social: return "person.2.fill"
        case .spiritual: return "leaf.fill"
        case .productivity: return "chart.line.uptrend.xyaxis"
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
