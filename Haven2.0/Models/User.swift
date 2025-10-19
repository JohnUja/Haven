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
    
    init(id: String = UUID().uuidString, 
         email: String, 
         name: String, 
         level: Int = 1, 
         currentXP: Int = 0, 
         nextLevelXP: Int = 100, 
         gamificationCurrency: Int = 0, 
         ownedThemeIDs: [String] = ["default"], 
         activeThemeID: String = "default", 
         calendarSyncToken: String? = nil) {
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
    }
}
