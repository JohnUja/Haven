//
//  MoodSliderCheckInView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//  Updated: Stoic-style slider with Smart Chips
//

import SwiftUI
import SwiftData
import AudioToolbox

struct MoodSliderCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    
    let onMoodSelected: (CoreMood, SubMood) -> Void
    var isAutomaticPrompt: Bool = false // Set to true when shown automatically on app launch
    
    @State private var sliderValue: Double = 0.5
    @State private var lastHapticIndex: Int = 3 // Start in the middle (calm zone)
    @State private var selectedSubMood: SubMood? = nil
    @State private var notes: String = ""
    @State private var currentPeriod: CheckInTime? = MoodJarService.currentCheckInPeriod()
    
    private var currentUser: User? {
        users.first
    }
    
    // Derived properties
    private var determinedCoreMood: CoreMood {
        sliderValue.toCoreMood()
    }
    
    private var determinedSubMood: SubMood {
        selectedSubMood ?? sliderValue.toDefaultSubMood()
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationStack {
            ZStack {
                theme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) { // Reduced spacing to give more room
                    // 1. Large Hero Icon (The "Stoic" Look)
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
                            
                            // The Icon (SF Symbol)
                            Image(systemName: determinedCoreMood.icon)
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(determinedCoreMood.color)
                                .symbolEffect(.bounce, value: determinedCoreMood)
                            
                        }
                        
                        Text(determinedCoreMood.displayName)
                            .font(.system(size: 28, weight: .medium, design: .default))
                            .foregroundColor(theme.textPrimary)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // 2. The Feedback Slider - Increased height, selector embedded inside
                    VStack(spacing: 18) {
                        // Slider Track
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let trackHeight: CGFloat = 50 // Increased height (was 37.5)
                            let thumbSize: CGFloat = 36 // Embedded inside, smaller than track height
                            
                            ZStack(alignment: .leading) { // Changed to .leading alignment
                                // Track Background
                                Capsule()
                                    .fill(theme.glassBackground)
                                    .frame(height: trackHeight)
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                    )
                                
                                // Gradient Fill (Dynamic width) - Starts from left, grows to right
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
                                    .frame(width: max(50, width * CGFloat(sliderValue)), height: trackHeight)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0.1), value: sliderValue) // Apple Health app style: fluid, responsive spring
                                
                                // The Thumb (Embedded inside slider, centered vertically, properly aligned) - Just circle, no icon
                                Circle()
                                    .fill(theme.glassBackground)
                                    .frame(width: thumbSize, height: thumbSize)
                                    .overlay(
                                        Circle()
                                            .stroke(theme.glassBorder, lineWidth: 1.5)
                                    )
                                    .position(
                                        x: thumbSize / 2 + (width - thumbSize) * CGFloat(sliderValue),
                                        y: trackHeight / 2 // Center vertically inside track
                                    )
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let newValue = max(0, min(1, value.location.x / width))
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                    sliderValue = newValue
                                                }
                                                triggerHapticFeedback(for: newValue)
                                            }
                                    )
                            }
                        }
                        .frame(height: 50) // Increased height
                        .padding(.horizontal, 24)
                        // Removed scaleEffect - use actual size
                        
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
                        
                        // 3. Mood Selections in rows of 3 - Fixed width and positions
                        let allSubMoods = determinedCoreMood.subMoods
                        let rows = stride(from: 0, to: allSubMoods.count, by: 3).map {
                            Array(allSubMoods[$0..<min($0 + 3, allSubMoods.count)])
                        }
                        
                        let screenWidth = UIScreen.main.bounds.width
                        let horizontalPadding: CGFloat = 24
                        let spacing: CGFloat = 12
                        let chipWidth = (screenWidth - (horizontalPadding * 2) - (spacing * 2)) / 3 // Fixed calculation: 3 chips per row
                        
                        VStack(spacing: 12) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                                HStack(spacing: spacing) {
                                    ForEach(row, id: \.self) { subMood in
                                        MoodChip(
                                            title: subMood.displayName,
                                            isSelected: selectedSubMood == subMood || (selectedSubMood == nil && subMood == determinedCoreMood.subMoods.first),
                                            color: determinedCoreMood.color,
                                            theme: theme
                                        ) {
                                            // If tapping the already-selected default, deselect (use default)
                                            if selectedSubMood == subMood {
                                                selectedSubMood = nil
                                            } else {
                                                selectedSubMood = subMood
                                            }
                                            playSelectionClick()
                                        }
                                        .frame(width: chipWidth, height: 44) // Fixed width AND height to prevent shifting
                                        .fixedSize(horizontal: false, vertical: true) // Prevent text from causing size changes
                                    }
                                    
                                    // Fill remaining space if row has less than 3 items
                                    if row.count < 3 {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: determinedCoreMood)
                    }
                    
                    // 4. Save Button
                    Button(action: {
                        saveMood()
                    }) {
                        Text("Check In")
                            .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundColor(theme.textPrimary) // Theme-aware text color
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.accentColor)
                            .cornerRadius(theme.smallCornerRadius)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isAutomaticPrompt {
                    // For automatic prompts, show period info instead of skip
                    ToolbarItem(placement: .principal) {
                        if let period = currentPeriod {
                            Text("\(period.displayName) Check-In")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                    }
                } else {
                    // For manual check-ins, show skip button
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Skip") {
                            dismiss()
                        }
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
            }
            .interactiveDismissDisabled(isAutomaticPrompt) // Prevent swipe-to-dismiss for automatic prompts
        }
    }
    
    // MARK: - Audio & Haptic Logic
    
    private func triggerHapticFeedback(for value: Double) {
        // Divide slider into 6 zones (0 to 5)
        let index = Int(value * 6)
        let clampedIndex = min(max(index, 0), 5)
        
        // Only trigger if we moved to a NEW zone (prevents spamming sound on every pixel)
        if clampedIndex != lastHapticIndex {
            // 1. Haptic: Light impact (feels like a notch)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            // 2. Sound: System Sound 1157 is the standard "Picker Click"
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
        guard let user = currentUser else { return }
        
        let coreMood = determinedCoreMood
        let subMood = determinedSubMood
        let checkInTime = currentPeriod ?? MoodJarService.currentCheckInPeriod() ?? .morning
        
        // Create mood entry
        let entry = MoodEntry(
            userID: user.id,
            coreMood: coreMood,
            subMood: subMood,
            checkInTime: checkInTime,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(entry)
        if user.moodHistory == nil {
            user.moodHistory = []
        }
        user.moodHistory?.append(entry)
        
        try? modelContext.save()
        
        // Check for rewards
        if let reward = MoodJarService.calculateMoodRewards(user: user, context: modelContext) {
            // Rewards applied automatically by service
        }
        
        onMoodSelected(coreMood, subMood)
        dismiss()
    }
}

// MARK: - Helper Chip View
struct MoodChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let theme: any AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.8) // Allow slight text scaling if needed
                .truncationMode(.tail)
                .frame(maxWidth: .infinity) // Fill available width
                .padding(.horizontal, 12)
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

#Preview {
    MoodSliderCheckInView(onMoodSelected: { _, _ in })
        .modelContainer(for: [User.self, MoodEntry.self], inMemory: true)
        .environment(ThemeManager())
}

