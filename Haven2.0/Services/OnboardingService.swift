//
//  OnboardingService.swift
//  Haven2.0
//
//  Created by John Uja on 2025-01-XX.
//

import Foundation
import SwiftUI
import FirebaseAuth

class OnboardingService: ObservableObject {
    static let shared = OnboardingService()
    
    @Published var isOnboardingComplete: Bool = false
    @Published var currentStep: OnboardingStep = .welcome
    
    private let onboardingCompleteKey = "onboardingComplete"
    private let currentStepKey = "currentOnboardingStep"
    
    private init() {
        loadOnboardingStatus()
    }
    
    // MARK: - Onboarding Steps
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case usernameSelection = 1 // New step for username selection
        case ageSelection = 2 // New step for age selection
        case quickWin = 3
        case featureTour = 4
        case routineSetup = 5
        case themeSelection = 6
        case moodJarIntro = 7
        case permissions = 8 // New step for location and calendar permissions
        case accountPrompt = 9
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to Haven"
            case .usernameSelection: return "Choose Your Username"
            case .ageSelection: return "How old are you?"
            case .quickWin: return "Create Your First Task"
            case .featureTour: return "Explore Haven"
            case .routineSetup: return "Set Up Your Routine"
            case .themeSelection: return "Choose Your Theme"
            case .moodJarIntro: return "Track Your Mood"
            case .permissions: return "Enable Permissions"
            case .accountPrompt: return "Save Your Progress"
            }
        }
        
        var description: String {
            switch self {
            case .welcome: return "Your personal productivity haven"
            case .usernameSelection: return "Pick a username to display on your profile"
            case .ageSelection: return "This helps us personalize your experience"
            case .quickWin: return "Let's create your first task to get started"
            case .featureTour: return "Take a quick tour of Haven's features"
            case .routineSetup: return "Set up daily routines to automate your schedule"
            case .themeSelection: return "Pick a theme that matches your style"
            case .moodJarIntro: return "Track your mood to unlock special themes"
            case .permissions: return "Enable location and calendar access for better features"
            case .accountPrompt: return "Create an account to save your progress"
            }
        }
    }
    
    // MARK: - Load/Save Status
    private func loadOnboardingStatus() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingCompleteKey)
        let savedStep = UserDefaults.standard.integer(forKey: currentStepKey)
        if let step = OnboardingStep(rawValue: savedStep) {
            currentStep = step
        }
    }
    
    func markOnboardingComplete() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingCompleteKey)
        
        // Sync to Firestore if user is authenticated
        if let uid = Auth.auth().currentUser?.uid {
            // Use fully qualified name to avoid conflict with Task model
            // FirestoreService is @MainActor, so we need to run on main actor
            typealias ConcurrencyTask = _Concurrency.Task
            ConcurrencyTask { @MainActor in
                do {
                    let firestoreService = FirestoreService.shared
                    try await firestoreService.createOrUpdateUser(
                        uid: uid,
                        email: Auth.auth().currentUser?.email ?? "",
                        displayName: Auth.auth().currentUser?.displayName ?? "User"
                    )
                    // Update onboarding status in Firestore
                    try await firestoreService.updateOnboardingStatus(uid: uid, isComplete: true)
                } catch {
                    print("OnboardingService: Failed to sync completion to Firestore: \(error)")
                }
            }
        }
    }
    
    func saveCurrentStep(_ step: OnboardingStep) {
        currentStep = step
        UserDefaults.standard.set(step.rawValue, forKey: currentStepKey)
    }
    
    func resetOnboarding() {
        isOnboardingComplete = false
        currentStep = .welcome
        UserDefaults.standard.removeObject(forKey: onboardingCompleteKey)
        UserDefaults.standard.removeObject(forKey: currentStepKey)
    }
    
    // MARK: - Step Navigation
    func nextStep(isGuest: Bool) -> OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        
        // If guest, skip routine setup and account prompt
        let stepsToShow = isGuest ? allSteps.filter { $0 != .routineSetup && $0 != .accountPrompt } : allSteps
        
        guard let currentIndex = stepsToShow.firstIndex(of: currentStep) else {
            return stepsToShow.first
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < stepsToShow.count {
            return stepsToShow[nextIndex]
        }
        
        return nil // Onboarding complete
    }
    
    func previousStep(isGuest: Bool) -> OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        
        // If guest, skip routine setup and account prompt
        let stepsToShow = isGuest ? allSteps.filter { $0 != .routineSetup && $0 != .accountPrompt } : allSteps
        
        guard let currentIndex = stepsToShow.firstIndex(of: currentStep) else {
            return stepsToShow.first
        }
        
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            return stepsToShow[previousIndex]
        }
        
        return nil
    }
    
    func getProgress(isGuest: Bool) -> Double {
        let allSteps = OnboardingStep.allCases
        let stepsToShow = isGuest ? allSteps.filter { $0 != .routineSetup && $0 != .accountPrompt } : allSteps
        
        guard let currentIndex = stepsToShow.firstIndex(of: currentStep) else {
            return 0.0
        }
        
        return Double(currentIndex + 1) / Double(stepsToShow.count)
    }
    
    func getStepNumber(isGuest: Bool) -> (current: Int, total: Int) {
        let allSteps = OnboardingStep.allCases
        let stepsToShow = isGuest ? allSteps.filter { $0 != .routineSetup && $0 != .accountPrompt } : allSteps
        
        guard let currentIndex = stepsToShow.firstIndex(of: currentStep) else {
            return (1, stepsToShow.count)
        }
        
        return (currentIndex + 1, stepsToShow.count)
    }
}

