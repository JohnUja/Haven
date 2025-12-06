//
//  MoodEntry.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//  Updated: Redesigned with 6 core moods and sub-moods system
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class MoodEntry {
    var id: String
    var userID: String
    var coreMood: CoreMood // The main mood jar (6 core moods)
    var subMood: SubMood // The specific emotion/marble
    var timestamp: Date
    var checkInTime: CheckInTime // morning, afternoon, night
    var notes: String? // optional notes
    
    // Relationship back to user
    var user: User?
    
    init(id: String = UUID().uuidString,
         userID: String,
         coreMood: CoreMood,
         subMood: SubMood,
         timestamp: Date = Date(),
         checkInTime: CheckInTime,
         notes: String? = nil) {
        self.id = id
        self.userID = userID
        self.coreMood = coreMood
        self.subMood = subMood
        self.timestamp = timestamp
        self.checkInTime = checkInTime
        self.notes = notes
    }
}

// MARK: - Core Moods (6 Mood Jars)
enum CoreMood: String, CaseIterable, Codable {
    case happy = "happy"
    case sad = "sad"
    case anxious = "anxious"
    case calm = "calm"
    case energetic = "energetic"
    case tired = "tired"
    
    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .calm: return "Calm"
        case .energetic: return "Energetic"
        case .tired: return "Tired"
        }
    }
    
    var icon: String {
        switch self {
        case .happy: return "sun.max"
        case .sad: return "cloud.heavyrain"
        case .anxious: return "wind"
        case .calm: return "leaf"
        case .energetic: return "bolt"
        case .tired: return "moon.zzz"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .sad: return .blue
        case .anxious: return .orange
        case .calm: return .green
        case .energetic: return .purple
        case .tired: return .indigo
        }
    }
    
    var subMoods: [SubMood] {
        SubMood.allCases.filter { $0.coreMood == self }
    }
}

// MARK: - Sub Moods (Marbles - 6 per core mood)
enum SubMood: String, CaseIterable, Codable {
    // Happy sub-moods
    case happy = "happy"
    case excited = "excited"
    case proud = "proud"
    case grateful = "grateful"
    case content = "content"
    case optimistic = "optimistic"
    
    // Sad sub-moods
    case sad = "sad"
    case lonely = "lonely"
    case disappointed = "disappointed"
    case grieved = "grieved"
    case melancholic = "melancholic"
    case despairful = "despairful"
    
    // Anxious sub-moods
    case anxious = "anxious"
    case nervous = "nervous"
    case worried = "worried"
    case stressed = "stressed"
    case overwhelmed = "overwhelmed"
    case fearful = "fearful"
    
    // Calm sub-moods
    case calm = "calm"
    case peaceful = "peaceful"
    case relaxed = "relaxed"
    case balanced = "balanced"
    case serene = "serene"
    case centered = "centered"
    
    // Energetic sub-moods
    case energetic = "energetic"
    case motivated = "motivated"
    case enthusiastic = "enthusiastic"
    case active = "active"
    case vibrant = "vibrant"
    case inspired = "inspired"
    
    // Tired sub-moods
    case tired = "tired"
    case exhausted = "exhausted"
    case drained = "drained"
    case weary = "weary"
    case fatigued = "fatigued"
    case sleepy = "sleepy"
    
    var displayName: String {
        switch self {
        // Happy
        case .happy: return "Happy"
        case .excited: return "Excited"
        case .proud: return "Proud"
        case .grateful: return "Grateful"
        case .content: return "Content"
        case .optimistic: return "Optimistic"
        
        // Sad
        case .sad: return "Sad"
        case .lonely: return "Lonely"
        case .disappointed: return "Disappointed"
        case .grieved: return "Grieved"
        case .melancholic: return "Melancholic"
        case .despairful: return "Despairful"
        
        // Anxious
        case .anxious: return "Anxious"
        case .nervous: return "Nervous"
        case .worried: return "Worried"
        case .stressed: return "Stressed"
        case .overwhelmed: return "Overwhelmed"
        case .fearful: return "Fearful"
        
        // Calm
        case .calm: return "Calm"
        case .peaceful: return "Peaceful"
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .serene: return "Serene"
        case .centered: return "Centered"
        
        // Energetic
        case .energetic: return "Energetic"
        case .motivated: return "Motivated"
        case .enthusiastic: return "Enthusiastic"
        case .active: return "Active"
        case .vibrant: return "Vibrant"
        case .inspired: return "Inspired"
        
        // Tired
        case .tired: return "Tired"
        case .exhausted: return "Exhausted"
        case .drained: return "Drained"
        case .weary: return "Weary"
        case .fatigued: return "Fatigued"
        case .sleepy: return "Sleepy"
        }
    }
    
    var coreMood: CoreMood {
        switch self {
        case .happy, .excited, .proud, .grateful, .content, .optimistic:
            return .happy
        case .sad, .lonely, .disappointed, .grieved, .melancholic, .despairful:
            return .sad
        case .anxious, .nervous, .worried, .stressed, .overwhelmed, .fearful:
            return .anxious
        case .calm, .peaceful, .relaxed, .balanced, .serene, .centered:
            return .calm
        case .energetic, .motivated, .enthusiastic, .active, .vibrant, .inspired:
            return .energetic
        case .tired, .exhausted, .drained, .weary, .fatigued, .sleepy:
            return .tired
        }
    }
}

// MARK: - Mood Intensity (for the circular selectors)
enum MoodIntensity: Int, CaseIterable {
    case veryNegative = 1
    case negative = 2
    case neutral = 3
    case positive = 4
    case veryPositive = 5
    
    var icon: String {
        switch self {
        case .veryNegative: return "face.dashed.fill"
        case .negative: return "minus.circle.fill"
        case .neutral: return "minus"
        case .positive: return "plus.circle.fill"
        case .veryPositive: return "face.smiling.fill"
        }
    }
    
    var faceIcon: String {
        // Flat icon representation (SF Symbols)
        switch self {
        case .veryNegative: return "arrow.down.circle.fill"
        case .negative: return "arrow.down"
        case .neutral: return "minus"
        case .positive: return "arrow.up"
        case .veryPositive: return "arrow.up.circle.fill"
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
        case .morning: return (5, 11) // 5 AM - 11:59 AM
        case .afternoon: return (12, 16) // 12:00 PM - 4:59 PM
        case .night: return (17, 23) // 5 PM - 11:59 PM
        }
    }
}

// MARK: - Legacy Support (for migration)
extension MoodType {
    var coreMood: CoreMood {
        switch self {
        case .happy, .excited: return .happy
        case .sad: return .sad
        case .anxious, .frustrated: return .anxious
        case .calm: return .calm
        case .energetic: return .energetic
        case .tired: return .tired
        }
    }
    
    var subMood: SubMood {
        switch self {
        case .happy: return .happy
        case .excited: return .excited
        case .sad: return .sad
        case .anxious: return .anxious
        case .frustrated: return .stressed
        case .calm: return .calm
        case .energetic: return .energetic
        case .tired: return .tired
        }
    }
}

// Keep old MoodType for backwards compatibility during migration
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

// MARK: - Slider Value Mapping
extension Double {
    /// Maps slider value (0.0-1.0) to CoreMood
    func toCoreMood() -> CoreMood {
        switch self {
        case 0.0..<0.167: return .sad           // 0.0 - 0.166
        case 0.167..<0.333: return .anxious    // 0.167 - 0.332
        case 0.333..<0.5: return .tired         // 0.333 - 0.499
        case 0.5..<0.667: return .calm         // 0.5 - 0.666
        case 0.667..<0.833: return .happy       // 0.667 - 0.832
        default: return .energetic              // 0.833 - 1.0
        }
    }
    
    /// Maps slider value to SubMood within the determined CoreMood
    /// Returns the first (default) sub-mood for that core mood
    func toDefaultSubMood() -> SubMood {
        let coreMood = self.toCoreMood()
        return coreMood.subMoods.first ?? .happy
    }
    
    /// Gets the mood text label (like "Not great", "Okay", etc.)
    func toMoodText() -> String {
        switch self {
        case 0.0..<0.2: return "Terrible"
        case 0.2..<0.4: return "Not great"
        case 0.4..<0.6: return "Okay"
        case 0.6..<0.8: return "Good"
        default: return "Great"
        }
    }
}
