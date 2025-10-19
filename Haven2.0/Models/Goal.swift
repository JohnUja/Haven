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
final class Goal {
    var id: String
    var userID: String
    var title: String
    var category: GoalCategory
    var targetValue: Int
    var currentValue: Int
    var isComplete: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         category: GoalCategory,
         targetValue: Int,
         currentValue: Int = 0,
         isComplete: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.title = title
        self.category = category
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isComplete = isComplete
        self.createdAt = createdAt
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
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .work: return "Work"
        case .learning: return "Learning"
        case .personal: return "Personal"
        }
    }
    
    var colorString: String {
        switch self {
        case .health: return "green"
        case .work: return "blue"
        case .learning: return "purple"
        case .personal: return "orange"
        }
    }
    
    func color() -> Color {
        switch self {
        case .health: return .green
        case .work: return .blue
        case .learning: return .purple
        case .personal: return .orange
        }
    }
}
