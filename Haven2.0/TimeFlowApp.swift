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
    @StateObject private var calendarManager = CalendarManager()
    
    var sharedModelContainer: ModelContainer = createModelContainer()
    
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            User.self,
            Task.self,
            TaskBlock.self,
            Goal.self,
            GoalMilestone.self,
            Theme.self,
        ])
        
        do {
            // Store data persistently on disk
            let modelConfiguration = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If migration fails, delete old database and start fresh
            print("SwiftData Error: \(error)")
            print("Clearing old database and creating fresh one...")
            
            // Delete the old database file
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            // Try again with fresh database
            do {
                let modelConfiguration = ModelConfiguration(schema: schema)
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Last resort: in-memory
                print("Failed to create persistent container, using in-memory")
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch {
                    fatalError("Could not create even in-memory ModelContainer: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(themeManager)
                .environmentObject(timeSettings)
                .environmentObject(calendarManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
