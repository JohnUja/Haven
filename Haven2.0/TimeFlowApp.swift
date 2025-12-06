//
//  TimeFlowApp.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct TimeFlowApp: App {
    @State private var authService = FirebaseAuthService.shared
    @State private var themeManager = ThemeManager()
    @StateObject private var timeSettings = TimeSettingsManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var onboardingService = OnboardingService.shared
    
    var sharedModelContainer: ModelContainer = createModelContainer()
    
    init() {
        // Initialize Firebase FIRST, before anything else
        FirebaseApp.configure()
        
        // DEBUG: Connect to Firebase Emulator Suite if running locally
        #if DEBUG
        // Connect to local emulator (comment out if testing against production)
        // Uncomment the lines below to use Firebase Emulator:
        /*
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        print("DEBUG: Connected to Firebase Auth Emulator on localhost:9099")
        */
        #endif
        
        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("Google Sign-In configured with client ID: \(clientID)")
        } else {
            print("WARNING: GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        // DEBUG: Clear guest auth on launch for testing
        #if DEBUG
        if let user = Auth.auth().currentUser, user.isAnonymous {
            print("DEBUG: Clearing guest auth on launch for testing")
            _Concurrency.Task { @MainActor in
                do {
                    try Auth.auth().signOut()
                    print("DEBUG: Guest auth cleared")
                } catch {
                    print("DEBUG: Error clearing guest auth: \(error)")
                }
            }
        }
        #endif
    }
    
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            User.self,
            Task.self,
            TaskBlock.self,
            Goal.self,
            GoalMilestone.self,
            Theme.self,
            DailyRoutine.self,
            FeedReaction.self,
            FeedComment.self,
            MoodEntry.self,
            GoalReflection.self,
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
            Group {
                if authService.isAuthenticated {
                    if onboardingService.isOnboardingComplete {
                        MainTabView()
                            .environment(themeManager)
                            .environmentObject(timeSettings)
                            .environmentObject(calendarManager)
                            .environment(authService)
                            .environmentObject(DeveloperModeService.shared)
                    } else {
                        OnboardingView()
                            .environment(themeManager)
                            .environmentObject(timeSettings)
                            .environment(authService)
                            .environmentObject(onboardingService)
                    }
                } else {
                    FirebaseAuthenticationView()
                        .environment(themeManager)
                        .environment(authService)
                        .environmentObject(DeveloperModeService.shared)
                }
            }
            .onOpenURL { url in
                // Handle Google Sign-In URL callbacks
                GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                print("TimeFlowApp: Auth state changed - authenticated: \(isAuthenticated)")
            }
            .onChange(of: onboardingService.isOnboardingComplete) { _, isComplete in
                if isComplete {
                    print("TimeFlowApp: Onboarding completed, switching to MainTabView")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
