//
//  MainTabView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var selectedTab = 0
    
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
            
            AIInsightsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Insights")
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
            
            // Add default theme
            let defaultTheme = Theme(
                name: "Default",
                themeDescription: "Clean and minimal design",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Default theme",
                isDefault: true
            )
            modelContext.insert(defaultTheme)
            
            // Add level-based themes
            let energeticTheme = Theme(
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
                name: "Calm",
                themeDescription: "Peaceful and soothing",
                unlockMethod: .level,
                unlockRequirement: "Reach Level 10",
                currencyPrice: 0,
                isDefault: false,
                unlockLevel: 10
            )
            modelContext.insert(calmTheme)
            
            // Add crystal-purchased themes
            let vintageTheme = Theme(
                name: "Vintage",
                themeDescription: "Classic and timeless",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 500,
                isDefault: false
            )
            modelContext.insert(vintageTheme)
            
            let neonTheme = Theme(
                name: "Neon",
                themeDescription: "Bright and modern",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 750,
                isDefault: false
            )
            modelContext.insert(neonTheme)
            
            // Add mood-based themes
            let balancedTheme = Theme(
                name: "Balanced",
                themeDescription: "Achieve balanced moods",
                unlockMethod: .mood,
                unlockRequirement: "7 days of balanced moods",
                currencyPrice: 0,
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [.happy, .calm],
                    requiredCount: 7,
                    pattern: "balanced"
                )
            )
            modelContext.insert(balancedTheme)
            
            let consistencyTheme = Theme(
                name: "Consistency",
                themeDescription: "Perfect week achievement",
                unlockMethod: .mood,
                unlockRequirement: "Perfect week (21 check-ins)",
                currencyPrice: 0,
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [],
                    requiredCount: 0,
                    pattern: "perfect_week"
                )
            )
            modelContext.insert(consistencyTheme)
            
            try? modelContext.save()
        }
    }
}
