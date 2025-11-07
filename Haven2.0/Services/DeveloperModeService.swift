//
//  DeveloperModeService.swift
//  Haven2.0
//
//  Created by AI on 2025-11-05.
//  Developer/Test Account System for Testing
//

import Foundation
import SwiftUI
import FirebaseAuth

/// Service to manage developer/test accounts with bypass capabilities
@MainActor
class DeveloperModeService: ObservableObject {
    static let shared = DeveloperModeService()
    
    @Published var isDeveloperMode = false
    @Published var bypassLimits = false
    @Published var maxXP = false
    @Published var maxCrystals = false
    @Published var maxLevel = false
    @Published var unlimitedTasks = false
    
    // Developer account email (change this to your email)
    private let developerEmail = "developer@haven.app"
    
    // Test account email pattern
    private let testAccountPattern = "test@haven.app"
    
    private init() {
        // Check if current user is a developer or test account
        checkDeveloperStatus()
    }
    
    // MARK: - Check Developer Status
    func checkDeveloperStatus() {
        guard let user = Auth.auth().currentUser else {
            isDeveloperMode = false
            return
        }
        
        let email = user.email ?? ""
        
        // Check if user is developer or test account
        // Test account email pattern: test@haven.app or any email containing "test@haven"
        isDeveloperMode = email == developerEmail || 
                         email == testAccountPattern || 
                         email.contains("test@haven") ||
                         email.lowercased().contains("developer") ||
                         email.lowercased().contains("test")
        
        print("DeveloperModeService: Checked email '\(email)' - Developer mode: \(isDeveloperMode)")
        
        // Load developer preferences
        if isDeveloperMode {
            loadDeveloperPreferences()
            // Auto-enable bypass for test accounts
            if email.contains("test@haven") || email.lowercased().contains("test") {
                bypassLimits = true
                maxXP = true
                maxCrystals = true
                maxLevel = true
                unlimitedTasks = true
                saveDeveloperPreferences()
            }
        }
    }
    
    // MARK: - Developer Preferences
    private func loadDeveloperPreferences() {
        let defaults = UserDefaults.standard
        bypassLimits = defaults.bool(forKey: "dev_bypass_limits")
        maxXP = defaults.bool(forKey: "dev_max_xp")
        maxCrystals = defaults.bool(forKey: "dev_max_crystals")
        maxLevel = defaults.bool(forKey: "dev_max_level")
        unlimitedTasks = defaults.bool(forKey: "dev_unlimited_tasks")
    }
    
    func saveDeveloperPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(bypassLimits, forKey: "dev_bypass_limits")
        defaults.set(maxXP, forKey: "dev_max_xp")
        defaults.set(maxCrystals, forKey: "dev_max_crystals")
        defaults.set(maxLevel, forKey: "dev_max_level")
        defaults.set(unlimitedTasks, forKey: "dev_unlimited_tasks")
    }
    
    // MARK: - Bypass Methods
    
    /// Check if limits should be bypassed
    func shouldBypassLimits() -> Bool {
        return isDeveloperMode && bypassLimits
    }
    
    /// Check if unlimited tasks are allowed
    func hasUnlimitedTasks() -> Bool {
        return isDeveloperMode && unlimitedTasks
    }
    
    /// Get max XP for testing (if enabled)
    func getMaxXP() -> Int? {
        return (isDeveloperMode && maxXP) ? 999999 : nil
    }
    
    /// Get max crystals for testing (if enabled)
    func getMaxCrystals() -> Int? {
        return (isDeveloperMode && maxCrystals) ? 999999 : nil
    }
    
    /// Get max level for testing (if enabled)
    func getMaxLevel() -> Int? {
        return (isDeveloperMode && maxLevel) ? 999 : nil
    }
    
    // MARK: - Developer Account Creation
    /// Create a developer account for testing
    static func createDeveloperAccount(email: String, password: String) async throws -> FirebaseAuth.User {
        // This should create a custom claim in Firebase Auth
        // For now, we'll use email-based detection
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Set display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = "Developer"
        try await changeRequest.commitChanges()
        
        return result.user
    }
}

