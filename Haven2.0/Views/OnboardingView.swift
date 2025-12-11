//
//  OnboardingView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    @StateObject private var onboardingService = OnboardingService.shared
    
    @State private var showingSkipConfirmation = false
    
    // Observe onboarding completion to auto-redirect
    @State private var hasCompleted = false
    
    private var isGuest: Bool {
        authService.currentUser?.isAnonymous ?? false
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return ZStack {
            // Background using theme gradient
            theme.primaryGradient
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                // Step content
                stepContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons
                navigationButtons
                    .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: onboardingService.isOnboardingComplete) { _, isComplete in
            if isComplete {
                hasCompleted = true
                // Force view update to trigger dismissal
                DispatchQueue.main.async {
                hasCompleted = true
                }
            }
        }
        .onAppear {
            checkOnboardingCompletion()
        }
        .onChange(of: hasCompleted) { _, completed in
            if completed {
                // Ensure onboarding is marked complete
                if !onboardingService.isOnboardingComplete {
                    onboardingService.markOnboardingComplete()
                }
            }
        }
        .alert("Skip Onboarding?", isPresented: $showingSkipConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                // Mark onboarding as complete
                onboardingService.markOnboardingComplete()
                hasCompleted = true
            }
        } message: {
            Text("You can always access these features later from Settings.")
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 8) {
            HStack {
                Text("Step \(onboardingService.getStepNumber(isGuest: isGuest).current) of \(onboardingService.getStepNumber(isGuest: isGuest).total)")
                    .font(AppStyleSheet.font(for: .settingsText))
                    .foregroundColor(theme.textPrimary.opacity(0.8))
                
                Spacer()
                
                Button("Skip") {
                    showingSkipConfirmation = true
                }
                .font(AppStyleSheet.font(for: .settingsText))
                .foregroundColor(theme.textPrimary.opacity(0.8))
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * onboardingService.getProgress(isGuest: isGuest), height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: onboardingService.getProgress(isGuest: isGuest))
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContentView: some View {
        switch onboardingService.currentStep {
        case .welcome:
            WelcomeStepView()
        case .usernameSelection:
            UsernameSelectionStepView()
        case .ageSelection:
            AgeSelectionStepView()
        case .quickWin:
            QuickWinStepView()
        case .featureTour:
            FeatureTourStepView()
        case .routineSetup:
            if !isGuest {
                RoutineSetupStepView()
            } else {
                // Should not reach here for guests, but handle gracefully
                WelcomeStepView()
            }
        case .themeSelection:
            ThemeSelectionStepView()
        case .moodJarIntro:
            // Use same mood check-in view as settings
            MoodSliderCheckInView(onMoodSelected: { coreMood, subMood in
                // Move to next step after mood is saved
                onboardingService.nextStep(isGuest: isGuest)
            })
        case .permissions:
            PermissionsStepView(onComplete: {
                onboardingService.nextStep(isGuest: isGuest)
            })
        case .accountPrompt:
            // Only show account prompt for logged-in users (not guests)
            if !isGuest {
                AccountPromptStepView()
            } else {
                // For guests, skip this step - go directly to completion
                AccountPromptStepView() // Show completion view for guests too
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if let previousStep = onboardingService.previousStep(isGuest: isGuest) {
                Button(action: {
                    withAnimation {
                        onboardingService.saveCurrentStep(previousStep)
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Next/Continue button
            Button(action: {
                handleNextStep()
            }) {
                HStack {
                    Text(onboardingService.currentStep == .accountPrompt ? "Continue" : "Next")
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Navigation Logic
    private func handleNextStep() {
        // If on account prompt step, complete onboarding
        if onboardingService.currentStep == .accountPrompt {
            onboardingService.markOnboardingComplete()
            hasCompleted = true
            // Force state update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasCompleted = true
            }
            return
        }
        
        if let nextStep = onboardingService.nextStep(isGuest: isGuest) {
            withAnimation {
                onboardingService.saveCurrentStep(nextStep)
            }
        } else {
            // Onboarding complete - mark as done
            onboardingService.markOnboardingComplete()
            hasCompleted = true
            // Force state update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hasCompleted = true
            }
        }
    }
    
    // Observe onboarding completion state
    private func checkOnboardingCompletion() {
        if onboardingService.isOnboardingComplete && !hasCompleted {
            hasCompleted = true
        }
    }
}

// MARK: - Individual Step Views (Placeholders - to be implemented)

struct WelcomeStepView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 24) {
            Spacer()
            
            // App logo/icon placeholder
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Welcome to Haven")
                .font(theme.titleFont) // Use theme font
                .foregroundColor(theme.textPrimary) // Use theme color
            
            Text("Your personal productivity haven")
                .font(theme.bodyFont) // Use theme font
                .foregroundColor(theme.textSecondary) // Use theme color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Username Selection Step
struct UsernameSelectionStepView: View {
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @State private var username: String = ""
    @State private var isCheckingAvailability = false
    @State private var isAvailable = true
    
    private var currentUser: User? {
        users.first
    }
    
    // Pre-fill from auth provider if available
    private var suggestedUsername: String {
        if let displayName = authService.currentUser?.displayName, !displayName.isEmpty {
            return displayName
        }
        if let email = authService.currentUser?.email {
            return String(email.split(separator: "@").first ?? "")
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Choose Your Username")
                .font(themeManager.currentTheme.titleFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textPrimary) // Use theme color
            
            Text("Pick a username to display on your profile")
                .font(themeManager.currentTheme.bodyFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textSecondary) // Use theme color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                transparentTextField(
                    placeholder: "Username",
                    text: $username,
                    theme: themeManager.currentTheme
                )
                .font(.system(size: 18, weight: .medium, design: .default))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(.horizontal, 40)
                    .onAppear {
                        // Pre-fill suggested username
                        if username.isEmpty && !suggestedUsername.isEmpty {
                            username = suggestedUsername
                        }
                    }
                
                if !username.isEmpty {
                    HStack {
                        if isCheckingAvailability {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking availability...")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        } else if isAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Available")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Username taken")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding(.top, 20)
            
            // Save username when valid
            .onChange(of: username) { _, newValue in
                // Check availability (simplified - in production, check against Firestore)
                // For now, just validate format
                let isValid = newValue.count >= 3 && newValue.count <= 20 && newValue.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
                isAvailable = isValid
                
                // Update user's display name if valid
                if isValid, let user = currentUser {
                    user.name = newValue
                    // Also update Firebase Auth display name
                    if let firebaseUser = authService.currentUser {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.displayName = newValue
                        _Concurrency.Task {
                            try? await changeRequest.commitChanges()
                        }
                    }
                    try? modelContext.save()
                }
            }
            
            Spacer()
        }
    }
}

struct QuickWinStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(ThemeManager.self) private var themeManager
    @StateObject private var onboardingService = OnboardingService.shared
    @Query private var tasks: [Task]
    @State private var showingAddTask = false
    @State private var taskCreated = false
    
    private var isGuest: Bool {
        authService.currentUser?.isAnonymous ?? false
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Create Your First Task")
                .font(themeManager.currentTheme.titleFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textPrimary) // Use theme color
            
            Text("Let's create your first task to get started")
                .font(themeManager.currentTheme.bodyFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textSecondary) // Use theme color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if taskCreated {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Task Created!")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                )
                .padding(.top, 20)
            } else {
                Button(action: {
                    showingAddTask = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Task")
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: Date(), prefillTaskName: "Have a fantastic day")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingTaskCreated"))) { _ in
            // Task was created - mark as created and allow user to continue
            taskCreated = true
        }
        .onChange(of: tasks.count) { oldCount, newCount in
            // Check if a task was actually created
            if newCount > oldCount && !taskCreated {
                taskCreated = true
            }
        }
    }
}

struct FeatureTourStepView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Explore Haven")
                .font(themeManager.currentTheme.titleFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textPrimary) // Use theme color
            
            Text("Take a quick tour of Haven's features")
                .font(themeManager.currentTheme.bodyFont) // Use theme font
                .foregroundColor(themeManager.currentTheme.textSecondary) // Use theme color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "house.fill", title: "Home Dashboard", description: "Manage your tasks and goals")
                featureRow(icon: "timeline.selection", title: "Timeline View", description: "Visual schedule of your day")
                featureRow(icon: "person.circle.fill", title: "Profile", description: "Track progress and unlock themes")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeManager.currentTheme.bodyFont) // Use theme font
                    .foregroundColor(themeManager.currentTheme.textPrimary) // Use theme color
                Text(description)
                    .font(themeManager.currentTheme.bodyFont) // Use theme font
                    .foregroundColor(themeManager.currentTheme.textSecondary) // Use theme color
            }
            
            Spacer()
        }
    }
}

struct RoutineSetupStepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var routines: [DailyRoutine]
    @State private var showingRoutineSetup = false
    @State private var routineCreated = false
    
    var body: some View {
        let theme = themeManager.currentTheme
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "repeat")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Set Up Your Routine")
                .font(theme.titleFont) // Use theme font
                .foregroundColor(theme.textPrimary) // Use theme color
            
            Text("Set up daily routines to automate your schedule")
                .font(theme.bodyFont) // Use theme font
                .foregroundColor(theme.textSecondary) // Use theme color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if routineCreated {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Routine Created!")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                )
                .padding(.top, 20)
            } else {
            Button(action: {
                showingRoutineSetup = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Set Up Routine")
                }
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 200)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.top, 20)
            }
            
            Button("Skip for now") {
                // Continue to next step - handled by navigation buttons
            }
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .sheet(isPresented: $showingRoutineSetup) {
            RoutineSetupView()
        }
        .onChange(of: routines.count) { oldCount, newCount in
            // Check if a routine was actually created
            if newCount > oldCount && !routineCreated {
                routineCreated = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RoutineCreated"))) { _ in
            routineCreated = true
        }
    }
}

struct ThemeSelectionStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var themes: [Theme]
    @Query private var users: [User]
    
    private var defaultThemes: [Theme] {
        themes.filter { $0.unlockMethod == .defaultTheme }
    }
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Choose Your Theme")
                    .font(theme.titleFont) // Use theme font
                    .foregroundColor(theme.textPrimary) // Use theme color
                
                Text("Pick a theme that matches your style")
                    .font(theme.bodyFont) // Use theme font
                    .foregroundColor(theme.textSecondary) // Use theme color
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Theme grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(defaultThemes) { themeOption in
                        ThemeSelectionCard(theme: themeOption, currentUser: currentUser, themeManager: themeManager)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding(.vertical, 40)
        }
    }
}

struct ThemeSelectionCard: View {
    let theme: Theme
    let currentUser: User?
    let themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    private var isSelected: Bool {
        currentUser?.activeThemeID == theme.id
    }
    
    var body: some View {
        let currentTheme = themeManager.currentTheme
        
        return Button(action: {
            if let user = currentUser {
                user.activeThemeID = theme.id
                try? modelContext.save()
                // Force theme update by setting theme in ThemeManager
                themeManager.setTheme(to: theme.id)
            }
        }) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeGradient)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? currentTheme.accentColor : Color.clear, lineWidth: 3)
                    )
                
                Text(theme.name)
                    .font(currentTheme.bodyFont) // Use theme font
                    .foregroundColor(currentTheme.textPrimary) // Use theme color
            }
        }
    }
    
    private var themeGradient: LinearGradient {
        switch theme.id.lowercased() {
        case "purple":
            return LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.6), .pink.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "light":
            return LinearGradient(colors: [.white.opacity(0.9), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dark":
            return LinearGradient(colors: [.black.opacity(0.9), .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "calm":
            return LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "energetic":
            return LinearGradient(colors: [.yellow.opacity(0.8), .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "sunset":
            return LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Age Selection Step
struct AgeSelectionStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @State private var selectedAgeRange: AgeRange? = nil
    
    private var currentUser: User? {
        users.first
    }
    
    // Age range categories
    enum AgeRange: String, CaseIterable {
        case range16_24 = "16-24"
        case range25_29 = "25-29"
        case range30_39 = "30-39"
        case range40_49 = "40-49"
        case range50_59 = "50-59"
        case range60Plus = "60+"
        
        var displayName: String {
            rawValue
        }
        
        var averageAge: Int {
            switch self {
            case .range16_24: return 20
            case .range25_29: return 27
            case .range30_39: return 35
            case .range40_49: return 45
            case .range50_59: return 55
            case .range60Plus: return 65
            }
        }
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(theme.textPrimary)
                
                Text("How old are you?")
                    .font(theme.titleFont) // Use theme font
                    .foregroundColor(theme.textPrimary)
                
                Text("This helps us personalize your experience")
                    .font(theme.bodyFont) // Use theme font
                    .foregroundColor(theme.textSecondary) // Use theme color
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Age range selection buttons - REDUCED SIZE
                VStack(spacing: 12) {
                    ForEach(AgeRange.allCases, id: \.self) { range in
                        Button(action: {
                            selectedAgeRange = range
                            // Save immediately
                            if let user = currentUser {
                                user.age = range.averageAge
                                try? modelContext.save()
                            }
                        }) {
                            HStack {
                                Text(range.displayName)
                                    .font(theme.bodyFont) // Use theme font instead of hardcoded
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                if selectedAgeRange == range {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16)) // Reduced from 20
                                        .foregroundColor(theme.accentColor)
                                }
                            }
                            .padding(.horizontal, 16) // Reduced from 24
                            .padding(.vertical, 10) // Reduced from 16
                            .background(
                                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                    .fill(selectedAgeRange == range ? theme.accentColor.opacity(0.3) : theme.glassBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                            .stroke(selectedAgeRange == range ? theme.accentColor : theme.glassBorder, lineWidth: selectedAgeRange == range ? 2 : theme.cardBorderWidth)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            // Set selected range based on existing age
            if let user = currentUser, let age = user.age {
                selectedAgeRange = ageRangeForAge(age)
            }
            }
        }
    
    private func ageRangeForAge(_ age: Int) -> AgeRange {
        switch age {
        case 16...24: return .range16_24
        case 25...29: return .range25_29
        case 30...39: return .range30_39
        case 40...49: return .range40_49
        case 50...59: return .range50_59
        default: return .range60Plus
        }
    }
}

struct MoodJarIntroStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "face.smiling")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Track Your Mood")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white)
            
            Text("Track your mood to unlock special themes")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Mood jar preview
            VStack(spacing: 12) {
                Text("Check in 3x daily to fill your mood jars")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                // Placeholder for mood jar visualization
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                    )
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct AccountPromptStepView: View {
    @Environment(FirebaseAuthService.self) private var authService
    
    private var isGuest: Bool {
        authService.currentUser?.isAnonymous ?? false
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // For guests, skip this step entirely (shouldn't reach here)
            // For logged-in users, show completion message
            if !isGuest {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                
                Text("You're signed in and ready to go")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // Fallback for guests (shouldn't reach here, but handle gracefully)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Continue to start using Haven")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

