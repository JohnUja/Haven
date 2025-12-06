//
//  ActivityKitService.swift
//  Haven2.0
//
//  Created by John Uja on 2025-01-XX.
//  Service for Dynamic Island integration with Immersive View Mode
//

import Foundation
import ActivityKit
import WidgetKit

// Custom error type for ActivityKit operations
enum ActivityError: Error {
    case activitiesDisabled
    case alreadyActive
    case noActiveActivity
}

@available(iOS 16.1, *)
class ActivityKitService {
    static let shared = ActivityKitService()
    
    // 1. IMPROVEMENT: Store the active activity reference for reliable updates and ending.
    private var currentActivity: Activity<ImmersiveTaskAttributes>?
    
    private init() {
        // Optional: Monitor status of any existing activities on initialization
        // This is good practice for persistence across app launches.
        if let activity = Activity<ImmersiveTaskAttributes>.activities.first {
            self.currentActivity = activity
        }
    }
    
    // MARK: - Start Activity (Dynamic Island)
    // 2. IMPROVEMENT: Mark function as 'throws' to propagate errors to the caller.
    func startImmersiveActivity(taskTitle: String, timeRemaining: TimeInterval) async throws {
        // Check 1: Activities enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities are not enabled")
            throw ActivityError.activitiesDisabled
        }
        
        // Check 2: Prevent starting a new activity if one is already running
        if currentActivity != nil {
            print("Activity already active. Ending existing activity and restarting.")
            // Await the async end method
            await self.endImmersiveActivity()
            // Optionally, you could throw ActivityError.alreadyActive here instead of restarting
        }
        
        let attributes = ImmersiveTaskAttributes(taskTitle: taskTitle)
        let contentState = ImmersiveTaskAttributes.ContentState(timeRemaining: timeRemaining)
        
        do {
            // Use the non-deprecated API for iOS 16.2+
            let activity = try Activity<ImmersiveTaskAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil)
            )
            // Store the successful activity reference
            self.currentActivity = activity
            print("Activity started: \(activity.id)")
        } catch {
            print("Failed to start activity: \(error)")
            // Re-throw the error so the caller can handle it
            throw error
        }
    }
    
    // MARK: - Update Activity
    // 3. IMPROVEMENT: Mark function as 'async' for clearer concurrency management (optional but better practice)
    func updateImmersiveActivity(timeRemaining: TimeInterval) async {
        guard let activity = currentActivity else {
            print("No active activity to update.")
            return
        }
        
        let updatedState = ImmersiveTaskAttributes.ContentState(timeRemaining: timeRemaining)
        
        // 4. FIX/IMPROVEMENT: Use the non-deprecated update API for iOS 16.2+
        await activity.update(ActivityContent(state: updatedState, staleDate: nil))
    }
    
    // MARK: - End Activity
        func endImmersiveActivity() async {
            guard let activity = currentActivity else {
                return
            }
            
            // FIX: Create a final state (e.g., 0 time remaining or current state)
            // It is best practice to update the UI one last time before dismissing
            let finalState = activity.content.state
            let finalContent = ActivityContent(state: finalState, staleDate: nil)
            
            // End the activity immediately
            await activity.end(finalContent, dismissalPolicy: .immediate)
            
            // Clear the stored reference
            self.currentActivity = nil
            print("Activity ended: \(activity.id)")
        }
}

// MARK: - Activity Attributes
@available(iOS 16.1, *)
struct ImmersiveTaskAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
    }
    
    var taskTitle: String
}
