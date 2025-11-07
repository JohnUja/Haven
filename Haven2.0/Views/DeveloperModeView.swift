//
//  DeveloperModeView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-05.
//  Developer Mode Settings for Testing
//

import SwiftUI
import SwiftData
import FirebaseAuth
import Combine

struct DeveloperModeView: View {
    @EnvironmentObject var developerService: DeveloperModeService
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var showingMaxXPAlert = false
    @State private var showingMaxCrystalsAlert = false
    @State private var showingMaxLevelAlert = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        List {
            Section {
                Text("Developer Mode is enabled for this account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Status")
            }
            
            Section("Bypass Options") {
                Toggle("Bypass All Limits", isOn: $developerService.bypassLimits)
                    .onChange(of: developerService.bypassLimits) { _, newValue in
                        developerService.saveDeveloperPreferences()
                    }
                
                Toggle("Unlimited Tasks", isOn: $developerService.unlimitedTasks)
                    .onChange(of: developerService.unlimitedTasks) { _, newValue in
                        developerService.saveDeveloperPreferences()
                    }
            }
            
            Section("Testing Options") {
                Toggle("Set Max XP", isOn: $developerService.maxXP)
                    .onChange(of: developerService.maxXP) { _, newValue in
                        if newValue, let user = currentUser {
                            applyMaxXP(to: user)
                        }
                        developerService.saveDeveloperPreferences()
                    }
                
                Toggle("Set Max Crystals", isOn: $developerService.maxCrystals)
                    .onChange(of: developerService.maxCrystals) { _, newValue in
                        if newValue, let user = currentUser {
                            applyMaxCrystals(to: user)
                        }
                        developerService.saveDeveloperPreferences()
                    }
                
                Toggle("Set Max Level", isOn: $developerService.maxLevel)
                    .onChange(of: developerService.maxLevel) { _, newValue in
                        if newValue, let user = currentUser {
                            applyMaxLevel(to: user)
                        }
                        developerService.saveDeveloperPreferences()
                    }
            }
            
            Section("Quick Actions") {
                Button(action: {
                    if let user = currentUser {
                        applyMaxXP(to: user)
                        applyMaxCrystals(to: user)
                        applyMaxLevel(to: user)
                    }
                }) {
                    Label("Set All Max Values", systemImage: "sparkles")
                }
                
                Button(action: {
                    if let user = currentUser {
                        resetToNormal(user: user)
                    }
                }) {
                    Label("Reset to Normal", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.red)
                }
            }
            
            Section("Level Progression Testing") {
                Button(action: {
                    if let user = currentUser {
                        testLevelProgression(user: user)
                    }
                }) {
                    Label("Test Level Up Animation", systemImage: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    if let user = currentUser {
                        incrementXPForLevelUp(user: user)
                    }
                }) {
                    Label("Add XP to Trigger Level Up", systemImage: "plus.circle.fill")
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Level: \(currentUser?.level ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Current XP: \(currentUser?.currentXP ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let user = currentUser {
                        let nextLevelXP = LevelService.xpForLevel(user.level + 1)
                        let currentLevelXP = LevelService.xpForLevel(user.level)
                        let xpNeeded = nextLevelXP - user.currentXP
                        
                        Text("XP Needed for Next Level: \(xpNeeded)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Account Info") {
                if let firebaseUser = Auth.auth().currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email: \(firebaseUser.email ?? "N/A")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("UID: \(firebaseUser.uid)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Developer Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Methods
    
    private func applyMaxXP(to user: User) {
        user.currentXP = 999999
        user.level = calculateLevel(fromXP: user.currentXP)
        // Update next level XP requirement
        user.nextLevelXP = calculateXPForLevel(user.level + 1)
        try? modelContext.save()
        
        showingMaxXPAlert = true
    }
    
    private func applyMaxCrystals(to user: User) {
        user.gamificationCurrency = 999999
        try? modelContext.save()
        
        showingMaxCrystalsAlert = true
    }
    
    private func applyMaxLevel(to user: User) {
        user.level = 999
        user.currentXP = calculateXPForLevel(999)
        user.nextLevelXP = calculateXPForLevel(1000) // Next level after max
        try? modelContext.save()
        
        showingMaxLevelAlert = true
    }
    
    private func resetToNormal(user: User) {
        user.currentXP = 0
        user.level = 1
        user.gamificationCurrency = 0
        user.nextLevelXP = 100
        try? modelContext.save()
    }
    
    private func calculateLevel(fromXP xp: Int) -> Int {
        // Level calculation formula (adjust as needed)
        return min(Int(sqrt(Double(xp) / 100)) + 1, 999)
    }
    
    private func calculateXPForLevel(_ level: Int) -> Int {
        // Reverse level calculation
        return max((level - 1) * (level - 1) * 100, 0)
    }
    
    // MARK: - Level Progression Testing
    
    /// Test level up animation by setting XP to trigger a level up
    private func testLevelProgression(user: User) {
        let currentLevel = user.level
        let targetLevel = currentLevel + 1
        
        // Calculate XP needed for next level
        let xpForNextLevel = LevelService.xpForLevel(targetLevel)
        
        // Set XP to exactly trigger level up
        user.currentXP = xpForNextLevel
        user.level = targetLevel
        user.nextLevelXP = LevelService.xpForLevel(targetLevel + 1)
        
        try? modelContext.save()
        
        // Post notification to trigger level up animation
        NotificationCenter.default.post(
            name: NSNotification.Name("DeveloperTestLevelUp"),
            object: nil,
            userInfo: [
                "newLevel": targetLevel,
                "unlockedThemes": [] as [String],
                "unlockedFeatures": [] as [String]
            ]
        )
    }
    
    /// Increment XP by a small amount to test gradual progression
    private func incrementXPForLevelUp(user: User) {
        let currentLevel = user.level
        let xpForNextLevel = LevelService.xpForLevel(currentLevel + 1)
        
        // Add enough XP to trigger level up
        let xpToAdd = max(xpForNextLevel - user.currentXP + 1, 100)
        user.currentXP += xpToAdd
        
        // Check if level up occurred
        if let levelUp = LevelService.checkLevelUp(user: user, newXP: user.currentXP) {
            try? modelContext.save()
            
            // Post notification to trigger level up animation
            NotificationCenter.default.post(
                name: NSNotification.Name("DeveloperTestLevelUp"),
                object: nil,
                userInfo: [
                    "newLevel": levelUp.newLevel,
                    "unlockedThemes": levelUp.unlockedThemes,
                    "unlockedFeatures": levelUp.unlockedFeatures
                ]
            )
        } else {
            // Just update next level XP
            user.nextLevelXP = LevelService.xpForLevel(user.level + 1)
            try? modelContext.save()
        }
    }
}

#Preview {
    DeveloperModeView()
        .environmentObject(DeveloperModeService.shared)
        .modelContainer(for: [User.self], inMemory: true)
}

