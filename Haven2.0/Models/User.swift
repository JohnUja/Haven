//
//  User.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var email: String
    var name: String
    var level: Int
    var currentXP: Int
    var nextLevelXP: Int
    var gamificationCurrency: Int // "Time Crystals"
    var ownedThemeIDs: [String]
    var activeThemeID: String
    var calendarSyncToken: String?
    
    // Gamification additions
    var weeklyProductivityScore: Int
    var weeklyResetDate: Date?
    var momentumDays: Int
    var lastMomentumUpdate: Date?
    var moodJarCompletions: Int // Track rewards earned via mood jar
    var age: Int? // User's age (optional)
    
    // Relationship to mood entries
    @Relationship(deleteRule: .cascade, inverse: \MoodEntry.user)
    var moodHistory: [MoodEntry]?
    
    init(id: String = UUID().uuidString, 
         email: String, 
         name: String, 
         level: Int = 1, 
         currentXP: Int = 0, 
         nextLevelXP: Int = 100, 
         gamificationCurrency: Int = 0, 
         ownedThemeIDs: [String] = ["default"], 
         activeThemeID: String = "default", 
         calendarSyncToken: String? = nil,
         weeklyProductivityScore: Int = 0,
         weeklyResetDate: Date? = nil,
         momentumDays: Int = 0,
         lastMomentumUpdate: Date? = nil,
         moodJarCompletions: Int = 0,
         age: Int? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.level = level
        self.currentXP = currentXP
        self.nextLevelXP = nextLevelXP
        self.gamificationCurrency = gamificationCurrency
        self.ownedThemeIDs = ownedThemeIDs
        self.activeThemeID = activeThemeID
        self.calendarSyncToken = calendarSyncToken
        self.weeklyProductivityScore = weeklyProductivityScore
        self.weeklyResetDate = weeklyResetDate
        self.momentumDays = momentumDays
        self.lastMomentumUpdate = lastMomentumUpdate
        self.moodJarCompletions = moodJarCompletions
        self.age = age
        self.moodHistory = []
    }
}
