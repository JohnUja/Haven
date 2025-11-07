//
//  Theme.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData

@Model
final class Theme {
    var id: String
    var name: String
    var themeDescription: String
    var unlockMethod: UnlockMethod
    var unlockRequirement: String
    var currencyPrice: Int
    var iapProductID: String?
    var isDefault: Bool
    
    // New unlock fields
    var unlockLevel: Int? // For level-based unlocks
    var moodRequirementData: Data? // Encoded MoodRequirement for mood-based unlocks
    
    init(id: String = UUID().uuidString,
         name: String,
         themeDescription: String,
         unlockMethod: UnlockMethod,
         unlockRequirement: String,
         currencyPrice: Int = 0,
         iapProductID: String? = nil,
         isDefault: Bool = false,
         unlockLevel: Int? = nil,
         moodRequirement: MoodRequirement? = nil) {
        self.id = id
        self.name = name
        self.themeDescription = themeDescription
        self.unlockMethod = unlockMethod
        self.unlockRequirement = unlockRequirement
        self.currencyPrice = currencyPrice
        self.iapProductID = iapProductID
        self.isDefault = isDefault
        self.unlockLevel = unlockLevel
        // Encode mood requirement to Data
        if let moodReq = moodRequirement,
           let encoded = try? JSONEncoder().encode(moodReq) {
            self.moodRequirementData = encoded
        } else {
            self.moodRequirementData = nil
        }
    }
    
    var moodRequirement: MoodRequirement? {
        get {
            guard let data = moodRequirementData,
                  let decoded = try? JSONDecoder().decode(MoodRequirement.self, from: data) else {
                return nil
            }
            return decoded
        }
        set {
            if let req = newValue,
               let encoded = try? JSONEncoder().encode(req) {
                moodRequirementData = encoded
            } else {
                moodRequirementData = nil
            }
        }
    }
}

enum UnlockMethod: String, CaseIterable, Codable {
    case level = "level"
    case currency = "currency"
    case mood = "mood"
    case achievement = "achievement"
    case defaultTheme = "defaultTheme"
    case iap = "iap" // Keep for backwards compatibility
    
    var displayName: String {
        switch self {
        case .level: return "Level Unlock"
        case .currency: return "Crystal Purchase"
        case .mood: return "Mood Unlock"
        case .achievement: return "Achievement Unlock"
        case .defaultTheme: return "Default Theme"
        case .iap: return "In-App Purchase"
        }
    }
}

struct MoodRequirement: Codable {
    var requiredMoods: [MoodType]
    var requiredCount: Int // e.g., 10 happy moods
    var pattern: String? // e.g., "balanced", "improving", "perfect_week"
}
