//
//  MainTabView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import UIKit

// Freeze-investigation logging was intentionally disabled after the audit cleanup.
@inline(__always)
fileprivate func debugLog(location: String, message: String, data: [String: Any] = [:], hypothesisId: String = "") {}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @State private var selectedTab = 0
    @State private var showingMoodCheckIn = false
    @State private var hasCheckedMoodOnLaunch = false
    
    private var currentUser: User? {
        LocalUserProvisioningService.resolveCurrentUser(from: users)
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
    
    // Helper to get tab name for logging
    private func tabName(for tab: Int) -> String {
        switch tab {
        case 0: return "Home"
        case 1: return "Timeline"
        case 2: return "Goals"
        case 3: return "Profile"
        default: return "Unknown"
        }
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
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.purple)
        .onAppear {
            _Concurrency.Task { @MainActor in
                try? await LocalUserProvisioningService.ensureLocalUserExists(in: modelContext)
            }
            checkForMoodCheckIn()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // #region agent log
            debugLog(location: "MainTabView.swift:101", message: "Tab change started", data: ["oldTab": oldValue, "newTab": newValue, "tabName": tabName(for: newValue)] as [String: Any], hypothesisId: "A")
            // #endregion
            // Re-check when switching tabs (in case time window changed)
            // #region agent log
            let checkStartTime = Date()
            debugLog(location: "MainTabView.swift:103", message: "checkForMoodCheckIn called", data: ["tab": newValue] as [String: Any], hypothesisId: "A")
            // #endregion
            checkForMoodCheckIn()
            // #region agent log
            let checkDuration = Date().timeIntervalSince(checkStartTime)
            debugLog(location: "MainTabView.swift:103", message: "checkForMoodCheckIn completed", data: ["tab": newValue, "duration": checkDuration] as [String: Any], hypothesisId: "A")
            // #endregion
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
        // #region agent log
        let funcStartTime = Date()
        debugLog(location: "MainTabView.swift:126", message: "checkForMoodCheckIn entry", data: ["shouldShow": shouldShowMoodCheckIn, "showing": showingMoodCheckIn] as [String: Any], hypothesisId: "A")
        // #endregion
        // Small delay to ensure UI is ready
        _Concurrency.Task { @MainActor in
            // #region agent log
            debugLog(location: "MainTabView.swift:129", message: "Task.sleep started", data: ["duration": 0.5] as [String: Any], hypothesisId: "A")
            // #endregion
            try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            // #region agent log
            debugLog(location: "MainTabView.swift:129", message: "Task.sleep completed", data: [:], hypothesisId: "A")
            // #endregion
            if shouldShowMoodCheckIn && !showingMoodCheckIn {
                // #region agent log
                debugLog(location: "MainTabView.swift:131", message: "Setting showingMoodCheckIn to true", data: [:], hypothesisId: "A")
                // #endregion
                showingMoodCheckIn = true
            }
            // #region agent log
            let funcDuration = Date().timeIntervalSince(funcStartTime)
            debugLog(location: "MainTabView.swift:126", message: "checkForMoodCheckIn exit", data: ["duration": funcDuration] as [String: Any], hypothesisId: "A")
            // #endregion
        }
    }
    
}
