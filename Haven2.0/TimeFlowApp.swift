//
//  TimeFlowApp.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

@main
struct TimeFlowApp: App {
    @State private var themeManager = ThemeManager()
    @StateObject private var timeSettings = TimeSettingsManager()
    
    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                User.self,
                Task.self,
                TaskBlock.self,
                Goal.self,
                GoalMilestone.self,
                Theme.self,
            ])
            // Use in-memory storage temporarily to avoid migration issues
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("SwiftData Error: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(themeManager)
                .environmentObject(timeSettings)
        }
        .modelContainer(sharedModelContainer)
    }
}
