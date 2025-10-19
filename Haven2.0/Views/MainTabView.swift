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
                unlockMethod: .progress,
                unlockRequirement: "Default theme",
                isDefault: true
            )
            modelContext.insert(defaultTheme)
        }
    }
}
