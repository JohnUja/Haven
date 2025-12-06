//
//  MoodCheckInView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//  Updated: Complete redesign matching reference images with 6 core moods + sub-moods
//

import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    let onMoodSelected: (CoreMood, SubMood) -> Void
    
    @State private var selectedIntensity: MoodIntensity? = nil
    @State private var selectedSubMood: SubMood? = nil
    @State private var notes: String = ""
    @State private var currentPeriod: CheckInTime? = MoodJarService.currentCheckInPeriod()
    
    private var currentUser: User? {
        users.first
    }
    
    private var canCheckIn: Bool {
        MoodJarService.canCheckIn().allowed || currentPeriod != nil
    }
    
    // Filter sub-moods based on selected intensity
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
        NavigationView {
            ZStack {
                // Background matching home screen style
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
                        // Current Period Indicator
                        if let period = currentPeriod {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("\(period.displayName) Check-in")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
                        
                        // Main Question
                        Text("How would you describe how you're feeling?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Mood Intensity Selectors (5 circular icons)
                        moodIntensityRow
                            .padding(.horizontal, 20)
                        
                        // Emotion/Feeling Words Grid
                        emotionGrid
                            .padding(.horizontal, 20)
                        
                        // Optional Notes
                        notesSection
                            .padding(.horizontal, 20)
                        
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
    
    // MARK: - Mood Intensity Row (5 circular selectors)
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
    
    // MARK: - Emotion Grid
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
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional thoughts (optional)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            TextEditor(text: $notes)
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
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveMood()
        }) {
            Text("Save")
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
    
    private var canSave: Bool {
        selectedIntensity != nil && selectedSubMood != nil
    }
    
    // MARK: - Save Action
    private func saveMood() {
        guard selectedIntensity != nil,
              let subMood = selectedSubMood,
              let user = currentUser else { return }
        
        let coreMood = subMood.coreMood
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
        
        onMoodSelected(coreMood, subMood)
        dismiss()
    }
}

#Preview {
    MoodCheckInView(onMoodSelected: { _, _ in })
        .modelContainer(for: [User.self, MoodEntry.self], inMemory: true)
}
