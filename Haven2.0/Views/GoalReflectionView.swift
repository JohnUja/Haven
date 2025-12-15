//
//  GoalReflectionView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Stoic-style progression page for goal reflections
//

import SwiftUI
import SwiftData

struct GoalReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    
    let goalID: String
    let milestoneID: String?
    let taskID: String?
    let goalTitle: String
    
    @State private var selectedIntensity: MoodIntensity? = nil
    @State private var selectedSubMood: SubMood? = nil
    @State private var whatWentWell: String = ""
    @State private var whatCouldBeImproved: String = ""
    @State private var openNotes: String = ""
    
    private var currentUser: User? {
        users.first
    }
    
    private var canSave: Bool {
        selectedIntensity != nil &&
        selectedSubMood != nil &&
        !whatWentWell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !whatCouldBeImproved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Filter sub-moods based on selected intensity (same as MoodCheckInView)
    private var availableSubMoods: [SubMood] {
        guard let intensity = selectedIntensity else {
            return SubMood.allCases
        }
        
        // Map intensity to core moods, then get their sub-moods
        let coreMoods: [CoreMood]
        switch intensity {
        case .veryNegative:
            coreMoods = [.sad, .anxious, .tired]
        case .negative:
            coreMoods = [.sad, .anxious, .tired]
        case .neutral:
            coreMoods = [.calm, .tired]
        case .positive:
            coreMoods = [.happy, .calm, .energetic]
        case .veryPositive:
            coreMoods = [.happy, .energetic]
        }
        
        return coreMoods.flatMap { $0.subMoods }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching home screen style (same as MoodCheckInView)
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Reflect on Your Progress")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            
                            Text("How would you describe how you're feeling about this goal?")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Mood Intensity Selectors (5 circular icons) - Same as MoodCheckInView
                        moodIntensityRow
                            .padding(.horizontal, 20)
                        
                        // Emotion/Feeling Words Grid - Same as MoodCheckInView
                        emotionGrid
                            .padding(.horizontal, 20)
                        
                        // Structured Questions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What went well?")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            transparentTextEditor(
                                text: $whatWentWell,
                                theme: themeManager.currentTheme,
                                placeholder: "Reflect on what went well...",
                                minHeight: 100
                            )
                            .padding(.horizontal, 20)
                            
                            Text("What could be improved?")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            transparentTextEditor(
                                text: $whatCouldBeImproved,
                                theme: themeManager.currentTheme,
                                placeholder: "Think about what could be improved...",
                                minHeight: 100
                            )
                            .padding(.horizontal, 20)
                            
                            // Optional Notes
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional thoughts (optional)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                TextEditor(text: $openNotes)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.8))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                        
                        // Save Button
                        saveButton
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                }
                }
            }
        }
    }
    
    // MARK: - Mood Intensity Row (5 circular selectors) - Same as MoodCheckInView
    private var moodIntensityRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                ForEach(MoodIntensity.allCases, id: \.self) { intensity in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedIntensity = intensity
                            // Reset sub-mood when intensity changes
                            selectedSubMood = nil
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(selectedIntensity == intensity ? Color.black : Color.white)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.3), lineWidth: selectedIntensity == intensity ? 0 : 2)
                                )
                            
                            // Flat icon (not emoji)
                            Image(systemName: intensity.faceIcon)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(selectedIntensity == intensity ? .white : .black)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Pagination indicator (small dot)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.black.opacity(index == 1 ? 0.6 : 0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
    
    // MARK: - Emotion Grid - Same as MoodCheckInView
    private var emotionGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(availableSubMoods, id: \.self) { subMood in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedSubMood = subMood
                    }
                }) {
                    Text(subMood.displayName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selectedSubMood == subMood
                                        ? subMood.coreMood.color.opacity(0.2)
                                    : Color.white.opacity(0.8)
                            )
                            .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                            selectedSubMood == subMood
                                                ? subMood.coreMood.color.opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                        .shadow(color: selectedSubMood == subMood ? subMood.coreMood.color.opacity(0.2) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveReflection()
        }) {
            Text("Save Reflection")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            canSave
                                ? LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [.gray, .gray.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                )
            }
        .disabled(!canSave)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Save Action
    private func saveReflection() {
        guard let intensity = selectedIntensity,
              let subMood = selectedSubMood,
              let user = currentUser else { return }
        
        // Convert SubMood to ReflectionMood for storage
        // Map the core mood to a reflection mood
        let coreMood = subMood.coreMood
        let reflectionMood: ReflectionMood
        
        // Map CoreMood to ReflectionMood
        switch coreMood {
        case .happy:
            reflectionMood = intensity == .veryPositive ? .excited : .proud
        case .sad:
            reflectionMood = .tired
        case .anxious:
            reflectionMood = .challenged
        case .calm:
            reflectionMood = .calm
        case .energetic:
            reflectionMood = .motivated
        case .tired:
            reflectionMood = .tired
        }
        
        let reflection = GoalReflection(
            userID: user.id,
            goalID: goalID,
            milestoneID: milestoneID,
            taskID: taskID,
            selectedMood: reflectionMood,
            whatWentWell: whatWentWell.trimmingCharacters(in: .whitespacesAndNewlines),
            whatCouldBeImproved: whatCouldBeImproved.trimmingCharacters(in: .whitespacesAndNewlines),
            openNotes: openNotes.isEmpty ? nil : openNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(reflection)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    GoalReflectionView(
        goalID: "test-goal",
        milestoneID: nil,
        taskID: nil,
        goalTitle: "Test Goal"
    )
    .modelContainer(for: [User.self, GoalReflection.self], inMemory: true)
}

