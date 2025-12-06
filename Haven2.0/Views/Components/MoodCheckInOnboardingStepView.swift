//
//  MoodCheckInOnboardingStepView.swift
//  Haven2.0
//
//  Mood check-in step for onboarding using the slider interface
//

import SwiftUI
import SwiftData
import AudioToolbox

struct MoodCheckInOnboardingStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    
    let onMoodSaved: () -> Void
    
    @State private var sliderValue: Double = 0.5
    @State private var lastHapticIndex: Int = 3
    @State private var selectedSubMood: SubMood? = nil
    @State private var hasSaved = false
    
    private var currentUser: User? {
        users.first
    }
    
    private var determinedCoreMood: CoreMood {
        sliderValue.toCoreMood()
    }
    
    private var determinedSubMood: SubMood {
        selectedSubMood ?? sliderValue.toDefaultSubMood()
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            theme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 12) {
                    Text("How are you feeling?")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Your answers will help shape the app around your needs")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(theme.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                // Large Hero Icon
                VStack(spacing: 20) {
                    ZStack {
                        // Outer Glow
                        Circle()
                            .fill(determinedCoreMood.color.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        
                        // The Circle Container
                        Circle()
                            .fill(theme.glassBackground)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                            )
                        
                        // The Icon
                        Image(systemName: determinedCoreMood.icon)
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(determinedCoreMood.color)
                            .symbolEffect(.bounce, value: determinedCoreMood)
                    }
                    
                    Text(determinedCoreMood.displayName)
                        .font(.system(size: 24, weight: .medium, design: .default))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                // The Feedback Slider (matching MoodSliderCheckInView)
                VStack(spacing: 24) {
                    // Slider Track
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            // Track Background
                            Capsule()
                                .fill(theme.glassBackground)
                                .frame(height: 50)
                                .overlay(
                                    Capsule()
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                            
                            // Gradient Fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            CoreMood.sad.color.opacity(0.3),
                                            determinedCoreMood.color
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(50, width * CGFloat(sliderValue)), height: 50)
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: sliderValue)
                            
                            // The Thumb
                            Circle()
                                .fill(theme.glassBackground)
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(theme.textPrimary.opacity(0.4))
                                )
                                .offset(x: (width - 42) * CGFloat(sliderValue))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newValue = max(0, min(1, value.location.x / width))
                                            sliderValue = newValue
                                            triggerHapticFeedback(for: newValue)
                                        }
                                )
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 24)
                    
                    // Labels
                    HStack {
                        Text("Terrible")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(theme.textPrimary.opacity(0.6))
                        Spacer()
                        Text("Great")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(theme.textPrimary.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    
                    // Smart Chips (Auto-Submoods)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(determinedCoreMood.subMoods, id: \.self) { subMood in
                                OnboardingMoodChip(
                                    title: subMood.displayName,
                                    isSelected: selectedSubMood == subMood || (selectedSubMood == nil && subMood == determinedCoreMood.subMoods.first),
                                    color: determinedCoreMood.color,
                                    theme: theme
                                ) {
                                    if selectedSubMood == subMood {
                                        selectedSubMood = nil
                                    } else {
                                        selectedSubMood = subMood
                                    }
                                    playSelectionClick()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 44)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: determinedCoreMood)
                }
                
                // Continue Button
                Button(action: {
                    saveMood()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.white) // White text for contrast on accentColor background
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.accentColor)
                        .cornerRadius(theme.smallCornerRadius)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                // Disclaimer
                Text("Your selections won't limit access to any features")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(theme.textPrimary.opacity(0.6))
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHapticFeedback(for value: Double) {
        let index = Int(value * 6)
        let clampedIndex = min(max(index, 0), 5)
        
        if clampedIndex != lastHapticIndex {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            AudioServicesPlaySystemSound(1157)
            
            lastHapticIndex = clampedIndex
        }
    }
    
    private func playSelectionClick() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Save Action
    
    private func saveMood() {
        guard let user = currentUser, !hasSaved else { return }
        hasSaved = true
        
        let coreMood = determinedCoreMood
        let subMood = determinedSubMood
        let checkInTime = MoodJarService.currentCheckInPeriod() ?? .morning
        
        // Create mood entry
        let entry = MoodEntry(
            userID: user.id,
            coreMood: coreMood,
            subMood: subMood,
            checkInTime: checkInTime,
            notes: nil
        )
        
        modelContext.insert(entry)
        if user.moodHistory == nil {
            user.moodHistory = []
        }
        user.moodHistory?.append(entry)
        
        do {
            try modelContext.save()
            
            // Check for rewards
            if let reward = MoodJarService.calculateMoodRewards(user: user, context: modelContext) {
                // Rewards applied automatically
            }
            
            // Call completion handler
            onMoodSaved()
        } catch {
            print("Failed to save mood entry: \(error)")
            hasSaved = false
        }
    }
}

// MARK: - Mood Chip View (reused from MoodSliderCheckInView)

struct OnboardingMoodChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let theme: any AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .default))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.15) : theme.glassBackground)
                )
                .foregroundColor(isSelected ? color : theme.textPrimary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

