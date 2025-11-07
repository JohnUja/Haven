//
//  FirestoreService.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Service
@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var syncTimer: Timer?
    private var pendingChanges: [String: Any] = [:]
    
    private init() {
        // Start periodic sync (every 30 seconds)
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            _createConcurrencyTask {
                await self?.syncPendingChanges()
            }
        }
        
        // Sync on app background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _createConcurrencyTask {
                await self?.syncPendingChanges()
            }
        }
    }
    
    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Sync Gamification Stats
    func syncGamificationStats(
        uid: String,
        level: Int,
        currentXP: Int,
        nextLevelXP: Int,
        crystals: Int,
        momentumDays: Int,
        lastMomentumUpdate: Date?,
        weeklyProductivityScore: Int,
        weeklyResetDate: Date?
    ) async throws {
        guard !uid.isEmpty else { return }
        
        let userRef = db.collection("users").document(uid)
        
        var data: [String: Any] = [
            "level": level,
            "currentXP": currentXP,
            "nextLevelXP": nextLevelXP,
            "crystals": crystals,
            "momentumDays": momentumDays,
            "weeklyProductivityScore": weeklyProductivityScore,
            "lastActiveAt": Timestamp(date: Date())
        ]
        
        if let lastMomentumUpdate = lastMomentumUpdate {
            data["lastMomentumUpdate"] = Timestamp(date: lastMomentumUpdate)
        }
        
        if let weeklyResetDate = weeklyResetDate {
            data["weeklyResetDate"] = Timestamp(date: weeklyResetDate)
        }
        
        // Store as pending change (will sync in batch)
        pendingChanges.merge(data) { _, new in new }
        
        // Try immediate sync (non-blocking)
        try await userRef.setData(data, merge: true)
    }
    
    // MARK: - Sync Theme Unlocks
    func syncThemeUnlocks(uid: String, ownedThemeIDs: [String], activeThemeID: String) async throws {
        guard !uid.isEmpty else { return }
        
        let userRef = db.collection("users").document(uid)
        
        // Convert ownedThemeIDs to map format
        var themeOwnedMap: [String: [String: Any]] = [:]
        for themeID in ownedThemeIDs {
            themeOwnedMap[themeID] = [
                "unlockedAt": Timestamp(date: Date()),
                "source": "level" // Default source, can be updated based on unlock method
            ]
        }
        
        let data: [String: Any] = [
            "ownedThemeIDs": themeOwnedMap,
            "activeThemeID": activeThemeID
        ]
        
        try await userRef.setData(data, merge: true)
    }
    
    // MARK: - Sync Mood Event
    func syncMoodEvent(uid: String, moodType: String, timestamp: Date, note: String?) async throws {
        guard !uid.isEmpty else { return }
        
        let moodEventRef = db.collection("users").document(uid).collection("moodEvents").document()
        
        var data: [String: Any] = [
            "id": moodEventRef.documentID,
            "moodType": moodType,
            "timestamp": Timestamp(date: timestamp),
            "createdAt": Timestamp(date: Date())
        ]
        
        if let note = note {
            data["note"] = note
        }
        
        try await moodEventRef.setData(data)
    }
    
    // MARK: - Update Mood Jar Summary
    func updateMoodJarSummary(uid: String, moodSummary: [String: Int], completions: Int) async throws {
        guard !uid.isEmpty else { return }
        
        let userRef = db.collection("users").document(uid)
        
        let data: [String: Any] = [
            "moodJarSummary": moodSummary,
            "moodJarCompletions": completions
        ]
        
        try await userRef.setData(data, merge: true)
    }
    
    // MARK: - Create or Update User Document
    func createOrUpdateUser(
        uid: String,
        email: String,
        displayName: String,
        timezone: String = TimeZone.current.identifier,
        locale: String = Locale.current.identifier
    ) async throws {
        guard !uid.isEmpty else { return }
        
        let userRef = db.collection("users").document(uid)
        
        // Check if user exists
        let document = try await userRef.getDocument()
        
        var data: [String: Any] = [
            "uid": uid,
            "email": email,
            "displayName": displayName,
            "timezone": timezone,
            "locale": locale,
            "lastActiveAt": Timestamp(date: Date())
        ]
        
        if !document.exists {
            // New user - add creation time and default values
            data["createdAt"] = Timestamp(date: Date())
            data["onboardingComplete"] = false
            data["subscriptionStatus"] = "free"
            data["level"] = 1
            data["currentXP"] = 0
            data["nextLevelXP"] = 100
            data["crystals"] = 0
            data["momentumDays"] = 0
            data["weeklyProductivityScore"] = 0
            data["moodJarCompletions"] = 0
            data["ownedThemeIDs"] = ["default": [
                "unlockedAt": Timestamp(date: Date()),
                "source": "default"
            ]]
            data["activeThemeID"] = "default"
        }
        
        try await userRef.setData(data, merge: true)
    }
    
    // MARK: - Sync Pending Changes (Background)
    private func syncPendingChanges() async {
        guard let uid = Auth.auth().currentUser?.uid, !pendingChanges.isEmpty else {
            return
        }
        
        let userRef = db.collection("users").document(uid)
        
        do {
            try await userRef.setData(pendingChanges, merge: true)
            pendingChanges.removeAll()
        } catch {
            print("FirestoreService: Failed to sync pending changes: \(error)")
            // Keep pending changes for next sync
        }
    }
    
    // MARK: - Get User Data
    func getUserData(uid: String) async throws -> [String: Any]? {
        guard !uid.isEmpty else { return nil }
        
        let userRef = db.collection("users").document(uid)
        let document = try await userRef.getDocument()
        
        guard document.exists else { return nil }
        
        return document.data()
    }
}

