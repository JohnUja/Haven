//
//  MoodEntry.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class MoodEntry {
    var id: String
    var userID: String
    var moodType: MoodType
    var timestamp: Date
    var checkInTime: CheckInTime // morning, afternoon, night
    var notes: String? // optional notes
    
    // Relationship back to user
    var user: User?
    
    init(id: String = UUID().uuidString,
         userID: String,
         moodType: MoodType,
         timestamp: Date = Date(),
         checkInTime: CheckInTime,
         notes: String? = nil) {
        self.id = id
        self.userID = userID
        self.moodType = moodType
        self.timestamp = timestamp
        self.checkInTime = checkInTime
        self.notes = notes
    }
}

enum MoodType: String, CaseIterable, Codable {
    case happy = "happy"
    case sad = "sad"
    case anxious = "anxious"
    case calm = "calm"
    case energetic = "energetic"
    case tired = "tired"
    case excited = "excited"
    case frustrated = "frustrated"
    
    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .calm: return "Calm"
        case .energetic: return "Energetic"
        case .tired: return "Tired"
        case .excited: return "Excited"
        case .frustrated: return "Frustrated"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .anxious: return "😰"
        case .calm: return "😌"
        case .energetic: return "⚡️"
        case .tired: return "😴"
        case .excited: return "🤩"
        case .frustrated: return "😤"
        }
    }
    
    var icon: String {
        switch self {
        case .happy: return "face.smiling.fill"
        case .sad: return "face.dashed.fill"
        case .anxious: return "heart.fill"
        case .calm: return "leaf.fill"
        case .energetic: return "bolt.fill"
        case .tired: return "moon.fill"
        case .excited: return "star.fill"
        case .frustrated: return "exclamationmark.triangle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .happy, .excited: return .yellow
        case .sad, .tired: return .blue
        case .anxious, .frustrated: return .orange
        case .calm: return .green
        case .energetic: return .purple
        }
    }
    
    var isPositive: Bool {
        switch self {
        case .happy, .calm, .energetic, .excited: return true
        case .sad, .anxious, .tired, .frustrated: return false
        }
    }
}

enum CheckInTime: String, CaseIterable, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case night = "night"
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .night: return "Night"
        }
    }
    
    var timeWindow: (start: Int, end: Int) {
        switch self {
        case .morning: return (7, 11) // 7 AM - 11 AM
        case .afternoon: return (12, 17) // 12 PM - 5 PM
        case .night: return (18, 23) // 6 PM - 11 PM
        }
    }
}

