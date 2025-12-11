//
//  MoodJarView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct MoodJarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @State private var showingCheckIn = false
    @State private var selectedMood: MoodType? = nil
    
    private var currentUser: User? {
        users.first
    }
    
    private var moodHistory: [MoodEntry] {
        currentUser?.moodHistory ?? []
    }
    
    private var todayEntries: [MoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return moodHistory.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
    }
    
    private var canCheckIn: (allowed: Bool, period: CheckInTime?) {
        MoodJarService.canCheckIn()
    }
    
    private var hasMaxCheckIns: Bool {
        guard let user = currentUser else { return false }
        return MoodJarService.hasMaxCheckInsToday(user: user)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background using theme gradient
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.5), radius: 10)
                            
                            Text("Mood Jar")
                                .font(themeManager.currentTheme.titleFont) // Use theme font
                                .foregroundColor(themeManager.currentTheme.textPrimary) // Use theme color
                            
                            Text("Fill up mood jars to unlock mood themes")
                                .font(themeManager.currentTheme.bodyFont) // Use theme font
                                .foregroundColor(themeManager.currentTheme.textSecondary) // Use theme color
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                    
                    // Individual Mood Jars
                    jarVisualView
                        .frame(maxHeight: 600)
                        .padding(.horizontal)
                        .padding(.bottom, 24) // Add spacing before Today's Check-in
                    
                    // Today's Check-ins
                    todayCheckInsView
                        .padding(.horizontal)
                    
                    // Stats
                    moodStatsView
                        .padding(.horizontal)
                    
                    // Check-in Button
                    checkInButtonView
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .drawingGroup() // Performance optimization
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCheckIn) {
                MoodSliderCheckInView(onMoodSelected: { coreMood, subMood in
                    // Entry is already created in MoodSliderCheckInView
                    // Just close the sheet
                    showingCheckIn = false
                })
            }
        }
    }
    
    // MARK: - Individual Mood Jars View
    private var jarVisualView: some View {
        // Count moods by core mood (all-time or recent)
        // Group by coreMood - each entry goes into its core mood jar
        let moodCounts: [CoreMood: Int] = Dictionary(grouping: moodHistory) { $0.coreMood }
            .mapValues { min($0.count, 15) } // Cap at 15 per jar
        
        return LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 24) { // Increased spacing to prevent overlapping
                ForEach(CoreMood.allCases, id: \.self) { coreMood in
                    IndividualMoodJar(
                        coreMood: coreMood,
                        count: moodCounts[coreMood] ?? 0,
                        onCashIn: {
                            cashInJar(coreMood: coreMood)
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true) // Prevent compression
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24) // Increased vertical padding to prevent bottom overlap
            .drawingGroup() // Performance optimization
    }
    
    private func cashInJar(coreMood: CoreMood) {
        guard let user = currentUser else { return }
        
        // Calculate reward (scales with multiple full jars)
        let baseReward = 350 // Base crystals
        let xpReward = 150 // Base XP
        
        // Give reward
        user.gamificationCurrency += baseReward
        user.currentXP += xpReward
        user.moodJarCompletions += 1
        
        // Sync to Firestore
        if let uid = Auth.auth().currentUser?.uid {
            _Concurrency.Task {
                do {
                    let firestoreService = FirestoreService.shared
                    // Update mood jar completions and stats in Firestore
                    try await firestoreService.syncGamificationStats(
                        uid: uid,
                        level: user.level,
                        currentXP: user.currentXP,
                        nextLevelXP: user.nextLevelXP,
                        crystals: user.gamificationCurrency,
                        momentumDays: user.momentumDays,
                        lastMomentumUpdate: user.lastMomentumUpdate,
                        weeklyProductivityScore: user.weeklyProductivityScore,
                        weeklyResetDate: user.weeklyResetDate
                    )
                    // Also update mood jar completions specifically
                    try await firestoreService.updateMoodJarSummary(
                        uid: uid,
                        moodSummary: [:], // Empty for now, can be populated later
                        completions: user.moodJarCompletions
                    )
                } catch {
                    print("MoodJarView: Failed to sync treats to Firestore: \(error)")
                }
            }
        }
        
        try? modelContext.save()
    }
    
    
    // MARK: - Today's Check-ins View
    private var todayCheckInsView: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Check-ins")
                .font(theme.headerFont) // Use theme font
                .foregroundColor(theme.textPrimary) // Use theme color
            
            if todayEntries.isEmpty {
                Text("No check-ins yet today")
                    .font(theme.bodyFont) // Use theme font
                    .foregroundColor(theme.textSecondary) // Use theme color
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEntries, id: \.id) { entry in
                        HStack {
                            Image(systemName: entry.coreMood.icon)
                                .font(.title2)
                                .foregroundColor(entry.coreMood.color)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.subMood.displayName)
                                    .font(theme.bodyFont) // Use theme font
                                    .foregroundColor(theme.textPrimary) // Use theme color
                                
                                Text(entry.coreMood.displayName)
                                    .font(theme.bodyFont) // Use theme font
                                    .foregroundColor(theme.textSecondary) // Use theme color
                                
                                Text(entry.checkInTime.displayName)
                                    .font(theme.bodyFont) // Use theme font
                                    .foregroundColor(theme.textSecondary) // Use theme color
                                
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(theme.bodyFont) // Use theme font
                                        .foregroundColor(theme.textSecondary) // Use theme color
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            Text(entry.timestamp, style: .time)
                                .font(theme.bodyFont) // Use theme font
                                .foregroundColor(theme.textSecondary) // Use theme color
                        }
                        .padding(12) // Removed duplicate padding
                        .background(
                            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                .fill(theme.glassBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                                )
                        )
                    }
                }
            }
        }
        .padding(theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Stats View
    private var moodStatsView: some View {
        let theme = themeManager.currentTheme
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let weekEntries = moodHistory.filter { $0.timestamp >= weekAgo }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(theme.headerFont) // Use theme font
                .foregroundColor(theme.textPrimary) // Use theme color
            
            if weekEntries.isEmpty {
                Text("No check-ins this week")
                    .font(theme.bodyFont) // Use theme font
                    .foregroundColor(theme.textSecondary) // Use theme color
            } else {
                // Mood distribution by core mood
                let moodDistribution = Dictionary(grouping: weekEntries) { $0.coreMood }
                
                VStack(spacing: 8) {
                    ForEach(CoreMood.allCases, id: \.self) { coreMood in
                        if let entries = moodDistribution[coreMood], !entries.isEmpty {
                            HStack {
                                Image(systemName: coreMood.icon)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(coreMood.color)
                                    .frame(width: 20, height: 20)
                                
                                Text(coreMood.displayName)
                                    .font(theme.bodyFont) // Use theme font
                                    .foregroundColor(theme.textPrimary) // Use theme color
                                
                                Spacer()
                                
                                Text("\(entries.count)")
                                    .font(theme.bodyFont) // Use theme font
                                    .foregroundColor(theme.textPrimary) // Use theme color
                            }
                        }
                    }
                }
            }
        }
        .padding(theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Check-in Button
    @ViewBuilder
    private var checkInButtonView: some View {
        let theme = themeManager.currentTheme
        
        Button(action: {
            showingCheckIn = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                
                Text(hasMaxCheckIns ? "Max Check-ins Reached" : "Check In")
                    .font(theme.titleFont) // Use theme font
                    .fontWeight(.semibold)
            }
            .foregroundColor(hasMaxCheckIns ? theme.textSecondary : theme.textPrimary) // Use theme color
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonBackground(theme: theme))
        }
        .disabled(hasMaxCheckIns)
    }
    
    @ViewBuilder
    private func buttonBackground(theme: any AppTheme) -> some View {
        if hasMaxCheckIns {
            Capsule()
                .fill(theme.glassBackground.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        }
    }
    
    // MARK: - Helper
    private func addMoodEntry(coreMood: CoreMood, subMood: SubMood) {
        guard let user = currentUser else { return }
        
        let checkInTime = MoodJarService.currentCheckInPeriod() ?? .afternoon
        
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
        
        try? modelContext.save()
        showingCheckIn = false
    }
}

#Preview {
    MoodJarView()
        .modelContainer(for: [User.self, MoodEntry.self], inMemory: true)
}

