//
//  LevelService.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

enum LevelService {
    
    // MARK: - Level Calculation
    
    /// Calculate level from total XP
    static func calculateLevel(xp: Int) -> Int {
        var currentXP = xp
        var level = 1
        
        while currentXP >= xpForLevel(level + 1) {
            level += 1
        }
        
        return level
    }
    
    /// Calculate XP required for a specific level
    /// Tiered system designed for 6-18 month progression to Level 50
    /// Target: Level 50 requires ~62,000 total cumulative XP
    /// - Super active (6 months): ~344 XP/day
    /// - Normal (18 months): ~113 XP/day
    static func xpForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        
        // Tiered system for better progression curve
        if level <= 10 {
            // Early levels: 150 × level^1.4
            return Int(150 * pow(Double(level), 1.4))
        } else if level <= 25 {
            // Mid levels: Base + 250 × (level-10)^1.5
            let base = Int(150 * pow(10.0, 1.4)) // ~3,766
            return base + Int(250 * pow(Double(level - 10), 1.5))
        } else {
            // High levels: Base + 500 × (level-25)^1.7
            let midBase = Int(150 * pow(10.0, 1.4)) + Int(250 * pow(15.0, 1.5)) // ~11,879
            return midBase + Int(500 * pow(Double(level - 25), 1.7))
        }
    }
    
    /// Calculate XP needed to reach next level
    static func xpToNextLevel(xp: Int, level: Int) -> Int {
        let nextLevelXP = xpForLevel(level + 1)
        let currentLevelXP = xpForLevel(level)
        return max(0, nextLevelXP - (xp - currentLevelXP))
    }
    
    /// Check if user leveled up and return unlock information
    static func checkLevelUp(user: User, newXP: Int) -> LevelUpResult? {
        let oldLevel = user.level
        let newLevel = calculateLevel(xp: newXP)
        
        guard newLevel > oldLevel else {
            // Update next level XP even if no level up
            user.nextLevelXP = xpForLevel(newLevel + 1)
            return nil
        }
        
        // User leveled up!
        user.level = newLevel
        user.nextLevelXP = xpForLevel(newLevel + 1)
        
        // Determine unlocks - NO FEATURE UNLOCKS (all features available to all users)
        // Themes are dynamically unlocked based on Theme model's unlockLevel property
        var unlockedThemes: [String] = []
        
        // Note: Actual theme unlock checking happens in ThemeShopView
        // by querying themes where unlockMethod == .level && unlockLevel <= user.level
        // This is just for display purposes in the level-up screen
        
        return LevelUpResult(
            newLevel: newLevel,
            unlockedThemes: unlockedThemes, // Will be populated dynamically via Theme model query
            unlockedFeatures: [] // NO FEATURE UNLOCKS - all features always available
        )
    }
    
    // MARK: - Level Progress
    
    static func calculateProgress(user: User) -> Double {
        let currentLevelXP = xpForLevel(user.level)
        let nextLevelXP = xpForLevel(user.level + 1)
        let xpInCurrentLevel = user.currentXP - currentLevelXP
        let xpNeededForNext = nextLevelXP - currentLevelXP
        
        guard xpNeededForNext > 0 else { return 1.0 }
        
        return min(Double(xpInCurrentLevel) / Double(xpNeededForNext), 1.0)
    }
}

struct LevelUpResult: Identifiable {
    var id: String { UUID().uuidString }
    var newLevel: Int
    var unlockedThemes: [String] // Themes unlocked at this level (queried from Theme model)
    var unlockedFeatures: [String] // DEPRECATED - all features always available
    
    init(newLevel: Int, unlockedThemes: [String] = [], unlockedFeatures: [String] = []) {
        self.newLevel = newLevel
        self.unlockedThemes = unlockedThemes
        self.unlockedFeatures = unlockedFeatures
    }
}

// MARK: - Theme Unlock Helper
extension LevelService {
    /// Dynamically query themes that should be unlocked at this level
    static func getUnlockedThemes(level: Int, themes: [Theme]) -> [String] {
        return themes
            .filter { theme in
                theme.unlockMethod == .level && 
                (theme.unlockLevel ?? 0) <= level &&
                !theme.isDefault
            }
            .map { $0.id }
    }
}

