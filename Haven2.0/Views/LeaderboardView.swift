//
//  LeaderboardView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @Query private var goals: [Goal]
    
    @State private var leaderboardType: LeaderboardType = .local
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var timeUntilReset: (days: Int, hours: Int) = (0, 0)
    
    private var currentUser: User? {
        users.first
    }
    
    private var userRank: Int {
        guard let user = currentUser else { return 0 }
        return leaderboardEntries.firstIndex(where: { $0.userID == user.id })?.advanced(by: 1) ?? 0
    }
    
    private var userEntry: LeaderboardEntry? {
        guard let user = currentUser else { return nil }
        return leaderboardEntries.first(where: { $0.userID == user.id })
    }
    
    enum LeaderboardType: String, CaseIterable {
        case local = "Local"
        case global = "Global"
        
        var displayName: String {
            rawValue
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching home screen
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
                
                VStack(spacing: 0) {
                    // Header with countdown
                    VStack(spacing: 12) {
                        // Leaderboard type selector
                        Picker("Leaderboard Type", selection: $leaderboardType) {
                            ForEach(LeaderboardType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        
                        // Countdown timer with modern design
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 14))
                            
                            Text("Resets in \(timeUntilReset.days)d \(timeUntilReset.hours)h")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    
                    // Top 10 Leaderboard
                    List {
                        Section {
                            ForEach(leaderboardEntries.prefix(10)) { entry in
                                LeaderboardRowView(
                                    entry: entry,
                                    isCurrentUser: entry.userID == currentUser?.id
                                )
                            }
                        } header: {
                            Text("Top 10")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .textCase(nil)
                                .padding(.leading, 4)
                        }
                        
                        // Your Rank Section
                        if let userEntry = userEntry, userRank > 10 {
                            Section {
                                LeaderboardRowView(
                                    entry: userEntry,
                                    isCurrentUser: true
                                )
                            } header: {
                                Text("Your Rank")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                refreshLeaderboard()
                updateTimeUntilReset()
                
                // Update countdown every minute
                Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                    updateTimeUntilReset()
                }
            }
            .refreshable {
                refreshLeaderboard()
            }
        }
    }
    
    private func refreshLeaderboard() {
        // Calculate and update leaderboard
        leaderboardEntries = LeaderboardService.getLeaderboard(
            users: users,
            tasks: tasks,
            goals: goals
        )
        
        // Save context after score updates
        try? modelContext.save()
    }
    
    private func updateTimeUntilReset() {
        timeUntilReset = LeaderboardService.timeUntilReset()
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if entry.rank <= 3 {
                    Text(rankEmoji)
                        .font(.title2)
                } else {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rankColor)
                }
            }
            
            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(isCurrentUser ? .purple : .gray)
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.username)
                        .font(.headline)
                        .fontWeight(isCurrentUser ? .bold : .medium)
                        .foregroundColor(isCurrentUser ? .purple : .primary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Text("Level \(entry.level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(entry.score) points")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .background(
            isCurrentUser
            ? Color.purple.opacity(0.1)
            : Color.clear
        )
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankEmoji: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

#Preview {
    LeaderboardView()
        .modelContainer(for: [User.self, Task.self, Goal.self], inMemory: true)
}

