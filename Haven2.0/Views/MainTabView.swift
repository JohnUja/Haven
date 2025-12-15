//
//  MainTabView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import UIKit

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @State private var selectedTab = 0
    @State private var showingMoodCheckIn = false
    @State private var hasCheckedMoodOnLaunch = false
    
    private var currentUser: User? {
        users.first
    }
    
    // Check if user needs to check in
    private var shouldShowMoodCheckIn: Bool {
        guard let user = currentUser else { return false }
        
        // Don't show if already checked on this launch
        if hasCheckedMoodOnLaunch { return false }
        
        // Check if within a check-in time window
        let checkInResult = MoodJarService.canCheckIn()
        guard checkInResult.allowed, let period = checkInResult.period else {
            return false
        }
        
        // Check if user already checked in for this period today
        if MoodJarService.hasCheckedInToday(user: user, period: period) {
            return false
        }
        
        // Check if user has reached max check-ins
        if MoodJarService.hasMaxCheckInsToday(user: user) {
            return false
        }
        
        return true
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            TimelineView()
                .tabItem {
                    Image(systemName: "timeline.selection")
                    Text("Timeline")
                }
                .tag(1)
            
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(2)
            
            FeedView()
                .tabItem {
                    ZStack {
                        Image(systemName: "square.grid.2x2")
                            .symbolVariant(.none)
                        
                        // Notification badge - RED
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: 8, y: -8)
                    }
                    Text("Feed")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.purple)
        .onAppear {
            setupDefaultUser()
            checkForMoodCheckIn()
        }
        .onChange(of: selectedTab) { _, _ in
            // Re-check when switching tabs (in case time window changed)
            checkForMoodCheckIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reset check flag when app comes to foreground
            hasCheckedMoodOnLaunch = false
            checkForMoodCheckIn()
        }
        .fullScreenCover(isPresented: $showingMoodCheckIn) {
            MoodSliderCheckInView(
                onMoodSelected: { _, _ in
                    // Mark that we've checked mood on this launch
                    hasCheckedMoodOnLaunch = true
                    showingMoodCheckIn = false
                },
                isAutomaticPrompt: true // Mark as automatic prompt
            )
            .environment(themeManager) // Pass ThemeManager to fullScreenCover
            .environment(\.modelContext, modelContext) // Ensure modelContext is available
        }
    }
    
    // MARK: - Mood Check-In Logic
    
    private func checkForMoodCheckIn() {
        // Small delay to ensure UI is ready
        _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            if shouldShowMoodCheckIn && !showingMoodCheckIn {
                showingMoodCheckIn = true
            }
        }
    }
    
    private func setupDefaultUser() {
        if users.isEmpty {
            let defaultUser = User(
                email: "user@timeflow.app",
                name: "TimeFlow User",
                gamificationCurrency: 100
            )
            modelContext.insert(defaultUser)
            
            // Seed default routines (sleep/eat) if none exist yet
            let defaultUserID = defaultUser.id
            let routinesFetch = FetchDescriptor<DailyRoutine>(
                predicate: #Predicate<DailyRoutine> { routine in
                    routine.userID == defaultUserID
                }
            )
            let hasExistingRoutines = ((try? modelContext.fetch(routinesFetch))?.isEmpty == false)
            if !hasExistingRoutines {
                _ = RoutineService.shared.createDefaultRoutines(userID: defaultUserID, in: modelContext)
            }
            
            // Add default themes (Light, Dark, Purple) - FREE and in shop
            let purpleTheme = Theme(
                id: "purple",
                name: "Purple",
                themeDescription: "Default purple gradient theme",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Free",
                currencyPrice: 0,
                isDefault: true
            )
            modelContext.insert(purpleTheme)
            
            // Light and Dark themes - FREE (changed from currency)
            let lightTheme = Theme(
                id: "light",
                name: "Light",
                themeDescription: "Clean white theme with black accents",
                unlockMethod: .defaultTheme, // Changed from .currency
                unlockRequirement: "Free",
                currencyPrice: 0, // Changed from 300
                isDefault: true
            )
            modelContext.insert(lightTheme)
            
            let darkTheme = Theme(
                id: "dark",
                name: "Dark",
                themeDescription: "Dark theme with white accents",
                unlockMethod: .defaultTheme, // Changed from .currency
                unlockRequirement: "Free",
                currencyPrice: 0, // Changed from 300
                isDefault: true
            )
            modelContext.insert(darkTheme)
            
            // Add level-based themes (must match AppTheme IDs)
            let energeticTheme = Theme(
                id: "energetic",
                name: "Energetic",
                themeDescription: "Vibrant and motivating",
                unlockMethod: .level,
                unlockRequirement: "Reach Level 5",
                currencyPrice: 0,
                isDefault: false,
                unlockLevel: 5
            )
            modelContext.insert(energeticTheme)
            
            let calmTheme = Theme(
                id: "calm",
                name: "Calm",
                themeDescription: "Peaceful and soothing",
                unlockMethod: .level,
                unlockRequirement: "Reach Level 10",
                currencyPrice: 0,
                isDefault: false,
                unlockLevel: 10
            )
            modelContext.insert(calmTheme)
            
            // Add crystal-purchasable shop themes (must match AppTheme IDs)
            let sunsetTheme = Theme(
                id: "sunset",
                name: "Sunset",
                themeDescription: "Warm orange and red gradient",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 500,
                isDefault: false
            )
            modelContext.insert(sunsetTheme)
            
            let vintageTheme = Theme(
                id: "vintage",
                name: "Vintage",
                themeDescription: "Classic and timeless brown tones",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 500,
                isDefault: false
            )
            modelContext.insert(vintageTheme)
            
            let neonTheme = Theme(
                id: "neon",
                name: "Neon",
                themeDescription: "Bright cyan and pink neon colors",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 750,
                isDefault: false
            )
            modelContext.insert(neonTheme)
            
            // Add mood-based themes (with IDs matching AppTheme)
            let balancedTheme = Theme(
                id: "balanced", // Added ID
                name: "Balanced",
                themeDescription: "Achieve balanced moods",
                unlockMethod: .currency, // Changed to currency for now (all unlocked)
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 400, // Price for now
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [.happy, .calm],
                    requiredCount: 7,
                    pattern: "balanced"
                )
            )
            modelContext.insert(balancedTheme)
            
            let consistencyTheme = Theme(
                id: "consistency", // Added ID
                name: "Consistency",
                themeDescription: "Perfect week achievement",
                unlockMethod: .currency, // Changed to currency for now (all unlocked)
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 600, // Price for now
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [],
                    requiredCount: 0,
                    pattern: "perfect_week"
                )
            )
            modelContext.insert(consistencyTheme)
            
            // BETA TESTING: Unlock all themes for testing
            defaultUser.ownedThemeIDs = [
                "purple", "light", "dark", // Default themes
                "energetic", "calm", // Level unlock themes
                "sunset", "vintage", "neon", // Crystal-purchasable themes
                "balanced", "consistency" // Mood-based themes
            ]
            
            try? modelContext.save()
        }
    }
}
