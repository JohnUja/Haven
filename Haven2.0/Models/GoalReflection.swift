//
//  GoalReflection.swift
//  Haven2.0
//
//  Created by John Uja on 2025-01-XX.
//  New GoalReflection model for Stoic-style reflections
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class GoalReflection {
    var id: String
    var userID: String
    var goalID: String
    var milestoneID: String? // Optional - if reflection is for a specific milestone
    var taskID: String? // Optional - if reflection is for a specific task
    var timestamp: Date
    
    // Mood/Emotion Selection
    var selectedMood: ReflectionMood
    
    // Structured Questions
    var whatWentWell: String // "What went well?"
    var whatCouldBeImproved: String // "What could be improved?"
    
    // Open-ended Notes
    var openNotes: String? // Optional additional thoughts
    
    init(id: String = UUID().uuidString,
         userID: String,
         goalID: String,
         milestoneID: String? = nil,
         taskID: String? = nil,
         timestamp: Date = Date(),
         selectedMood: ReflectionMood,
         whatWentWell: String,
         whatCouldBeImproved: String,
         openNotes: String? = nil) {
        self.id = id
        self.userID = userID
        self.goalID = goalID
        self.milestoneID = milestoneID
        self.taskID = taskID
        self.timestamp = timestamp
        self.selectedMood = selectedMood
        self.whatWentWell = whatWentWell
        self.whatCouldBeImproved = whatCouldBeImproved
        self.openNotes = openNotes
    }
}

// MARK: - Reflection Mood (Flat Icons, not emojis)
enum ReflectionMood: String, CaseIterable, Codable {
    case focused = "focused"
    case proud = "proud"
    case challenged = "challenged"
    case tired = "tired"
    case motivated = "motivated"
    case calm = "calm"
    case excited = "excited"
    case grateful = "grateful"
    
    var displayName: String {
        switch self {
        case .focused: return "Focused"
        case .proud: return "Proud"
        case .challenged: return "Challenged"
        case .tired: return "Tired"
        case .motivated: return "Motivated"
        case .calm: return "Calm"
        case .excited: return "Excited"
        case .grateful: return "Grateful"
        }
    }
    
    // Flat SF Symbols (not emojis)
    var icon: String {
        switch self {
        case .focused: return "target"
        case .proud: return "star.fill"
        case .challenged: return "exclamationmark.triangle.fill"
        case .tired: return "moon.fill"
        case .motivated: return "flame.fill"
        case .calm: return "leaf.fill"
        case .excited: return "sparkles"
        case .grateful: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .focused: return .blue
        case .proud: return .yellow
        case .challenged: return .orange
        case .tired: return .indigo
        case .motivated: return .red
        case .calm: return .green
        case .excited: return .purple
        case .grateful: return .pink
        }
    }
}

