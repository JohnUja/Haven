//
//  TimeFlowApp.swift
//  Haven
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
    @State private var authService: FirebaseAuthService
    @State private var themeManager = ThemeManager()
    @StateObject private var timeSettings = TimeSettingsManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var onboardingService = OnboardingService.shared
    
    var sharedModelContainer: ModelContainer = TimeFlowApp.createModelContainer()
    
    init() {
        // Initialize Firebase FIRST, before anything else
        // Guard against double configuration (can crash if called twice)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Initialize authService AFTER Firebase is configured
        _authService = State(initialValue: FirebaseAuthService.shared)
        
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
            // Feed and leaderboard are deferred until the v2 11cope is revisited.
            // FeedReaction.self,
            // FeedComment.self,
            MoodEntry.self,
            GoalReflection.self,
        ])
        
        // Use explicit store URL to ensure we delete the correct file
        let storeURL = URL.applicationSupportDirectory.appending(path: "Haven.store")
        
        do {
            // Store data persistently on disk with explicit URL
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If migration fails, delete old database and start fresh
            print("SwiftData Error: \(error)")
            print("Clearing old database and creating fresh one...")
            
            // Delete the explicit store file (works for both file and directory)
            try? FileManager.default.removeItem(at: storeURL)
            
            // Also try to delete legacy "default.store" if it exists
            let legacyURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: legacyURL)
            
            // Try again with fresh database
            do {
                let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Last resort: in-memory (but log error instead of fatalError for production)
                print("ERROR: Failed to create persistent container, using in-memory")
                print("Error details: \(error.localizedDescription)")
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch {
                    // In production, log and use in-memory; fatalError only in debug
                    #if DEBUG
                    fatalError("Could not create even in-memory ModelContainer: \(error)")
                    #else
                    print("CRITICAL: Could not create ModelContainer. App may not function correctly.")
                    // Return in-memory container as last resort (data will be lost on app close)
                    return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
                    #endif
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
                print("Haven: Auth state changed - authenticated: \(isAuthenticated)")
            }
            .onChange(of: onboardingService.isOnboardingComplete) { _, isComplete in
                if isComplete {
                    print("Haven: Onboarding completed, switching to MainTabView")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
