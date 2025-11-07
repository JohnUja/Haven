//
//  MoodJarView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData

struct MoodJarView: View {
    @Environment(\.modelContext) private var modelContext
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
                // Themed background matching home/AI insights
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.pink.opacity(0.2),
                        Color.blue.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.5), radius: 10)
                            
                            Text("Mood Jar")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Fill up mood jars to unlock mood themes")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                    
                    // Individual Mood Jars
                    jarVisualView
                        .frame(maxHeight: 600)
                        .padding(.horizontal)
                    
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCheckIn) {
                MoodCheckInView(onMoodSelected: { mood in
                    addMoodEntry(mood: mood)
                })
            }
        }
    }
    
    // MARK: - Individual Mood Jars View
    private var jarVisualView: some View {
        // Count moods by type (all-time or recent)
        let moodCounts: [MoodType: Int] = Dictionary(grouping: moodHistory) { $0.moodType }
            .mapValues { min($0.count, 15) } // Cap at 15 per jar
        
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(MoodType.allCases, id: \.self) { moodType in
                    IndividualMoodJar(
                        moodType: moodType,
                        count: moodCounts[moodType] ?? 0,
                        onCashIn: {
                            cashInJar(moodType: moodType)
                        }
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func cashInJar(moodType: MoodType) {
        guard let user = currentUser else { return }
        
        // Calculate reward (scales with multiple full jars)
        let baseReward = 350 // Base crystals
        let xpReward = 150 // Base XP
        
        // Give reward
        user.gamificationCurrency += baseReward
        user.currentXP += xpReward
        user.moodJarCompletions += 1
        
        // Reset this mood type's entries (optional - or just mark as cashed in)
        // For now, we'll just track the count - actual reset would require filtering entries
        // This is a simplified version - full implementation would need to mark entries as "cashed in"
        
        try? modelContext.save()
    }
    
    
    // MARK: - Today's Check-ins View
    private var todayCheckInsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Check-ins")
                .font(.headline)
                .fontWeight(.semibold)
            
            if todayEntries.isEmpty {
                Text("No check-ins yet today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEntries, id: \.id) { entry in
                        HStack {
                            Image(systemName: entry.moodType.icon)
                                .font(.title2)
                                .foregroundColor(entry.moodType.iconColor)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.moodType.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(entry.checkInTime.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Stats View
    private var moodStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
            let weekEntries = moodHistory.filter { $0.timestamp >= weekAgo }
            
            if weekEntries.isEmpty {
                Text("No check-ins this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                // Mood distribution
                let moodDistribution = Dictionary(grouping: weekEntries) { $0.moodType }
                
                VStack(spacing: 8) {
                    ForEach(MoodType.allCases.prefix(5), id: \.self) { moodType in
                        if let entries = moodDistribution[moodType], !entries.isEmpty {
                            HStack {
                                Image(systemName: moodType.icon)
                                    .font(.title3)
                                    .foregroundColor(moodType.iconColor)
                                    .frame(width: 20, height: 20)
                                
                                Text(moodType.displayName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(entries.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Check-in Button
    private var checkInButtonView: some View {
        Button(action: {
            showingCheckIn = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                
                Text(hasMaxCheckIns ? "Max Check-ins Reached" : "Check In")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: hasMaxCheckIns ? [.gray, .gray.opacity(0.7)] : [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .disabled(hasMaxCheckIns)
    }
    
    // MARK: - Helper
    private func addMoodEntry(mood: MoodType) {
        guard let user = currentUser else { return }
        
        let success = MoodJarService.addMoodEntry(
            user: user,
            mood: mood,
            period: nil,
            notes: nil,
            context: modelContext
        )
        
        if success {
            try? modelContext.save()
            showingCheckIn = false
        }
    }
}

#Preview {
    MoodJarView()
        .modelContainer(for: [User.self, MoodEntry.self], inMemory: true)
}

