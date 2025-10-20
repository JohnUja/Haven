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
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("SwiftData Error: \(error)")
            // Fallback to in-memory storage for debugging
            let schema = Schema([User.self, Task.self, TaskBlock.self, Goal.self, GoalMilestone.self, Theme.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
