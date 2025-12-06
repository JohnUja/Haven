//
// LeaderboardView.swift
// TimeFlow
//
// Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @Query private var goals: [Goal]
    
    @State private var leaderboardType: LeaderboardType = .local
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var timeUntilReset: (days: Int, hours: Int) = (0, 0)
    @State private var currentLeague: League = .gold // Placeholder - should be calculated from user score
    
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
    
    private var userLeague: League {
        guard let entry = userEntry else { return .bronze }
        return League.leagueForScore(entry.score)
    }
    
    enum LeaderboardType: String, CaseIterable {
        case local = "Local"
        case global = "Global"
        
        var displayName: String {
            rawValue
        }
    }
    
    // MARK: - Fix for "Type-check expression in reasonable time" error
    // Moved the complex ScrollView content into a separate property
    private var scrollViewContent: some View {
        VStack(spacing: 16) {
            // Leaderboard Type Toggle - Similar to plan/focus tabs with same animation
            HStack(spacing: 0) {
                // Local Button
                Button(action: {
                    // Haptic feedback for polished feel
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.prepare()
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                        leaderboardType = .local
                    }
                }) {
                    Text("Local")
                        .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(leaderboardType == .local ? themeManager.currentTheme.textPrimary : themeManager.currentTheme.textPrimary.opacity(0.6))
                        .frame(maxWidth: .infinity) // Fixed equal width
                        .frame(height: 40)
                        .background(
                            Group {
                                if leaderboardType == .local {
                                    RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                        .fill(themeManager.currentTheme.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                                .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                        )
                                }
                            }
                        )
                }
                
                // Global Button
                Button(action: {
                    // Haptic feedback for polished feel
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.prepare()
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                        leaderboardType = .global
                    }
                }) {
                    Text("Global")
                        .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(leaderboardType == .global ? themeManager.currentTheme.textPrimary : themeManager.currentTheme.textPrimary.opacity(0.6))
                        .frame(maxWidth: .infinity) // Fixed equal width
                        .frame(height: 40)
                        .background(
                            Group {
                                if leaderboardType == .global {
                                    RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                        .fill(themeManager.currentTheme.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                                .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                        )
                                }
                            }
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                    .fill(themeManager.currentTheme.glassBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                            .stroke(themeManager.currentTheme.glassBorder.opacity(0.5), lineWidth: themeManager.currentTheme.cardBorderWidth)
                    )
            )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Top bar with league name and time
                        HStack {
                            // League name (smaller, top left) with enhanced readability
                            Text("\(userLeague.displayName) League")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1) // Enhanced shadow
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0) // Double shadow for depth
                            
                            Spacer()
                            
                            // Time remaining (top right) with increased backdrop opacity
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                
                                Text("\(timeUntilReset.days) days")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.25)) // Increased opacity for better backdrop
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // League Progression Trophies (closer to top)
                        leagueProgressionView
                            .padding(.horizontal, 20)
                        
                        // Top 10 Leaderboard (Duolingo style - clean, no nested containers)
                        VStack(alignment: .leading, spacing: 12) {
                            if League.canAdvance(rank: userRank) {
                                Text("Top 10 advance to next league")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 20)
                            }
                            
                            // Leaderboard entries - clean list with single background container
                            VStack(spacing: 0) {
                                ForEach(Array(leaderboardEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                                    DuolingoLeaderboardRowView(
                                        entry: entry,
                                        rank: index + 1,
                                        isCurrentUser: entry.userID == currentUser?.id
                                    )
                                    
                                    if index < 9 {
                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                    .fill(themeManager.currentTheme.glassBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                            .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // User's Position (if not in top 10)
                            if let userEntry = userEntry, userRank > 10 {
                            VStack(alignment: .leading, spacing: 12) {
                                // "Your Position" text outside the row container
                                Text("Your Position")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                // Row with single background container
                                DuolingoLeaderboardRowView(
                                    entry: userEntry,
                                    rank: userRank,
                                    isCurrentUser: true
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                        .fill(themeManager.currentTheme.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                                .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                        )
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Countdown timer
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 14))
                            
                            Text("Resets in \(timeUntilReset.days) day\(timeUntilReset.days == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background using theme gradient
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    scrollViewContent // <-- Using the extracted property
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Dismiss view - handled by environment dismiss
                    }) {
                        Image(systemName: "xmark") // Use xmark for modal dismissal
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimary) // Theme-aware color
                    }
                }
            }
            .onAppear {
                refreshLeaderboard()
                updateTimeUntilReset()
                
                // Update countdown every minute
                Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                    updateTimeUntilReset()
                }
            }
            .onChange(of: leaderboardType) { _, _ in
                refreshLeaderboard()
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
            goals: goals,
            includeFakeUsers: true // Include fake users for testing
        )
        
        // Filter by leaderboard type
        if leaderboardType == .local {
            // Show only real users (exclude fake users)
            leaderboardEntries = leaderboardEntries.filter { !$0.userID.starts(with: "fake_user_") }
        }
        // Global shows all (including fake users)
        
        // Re-sort and re-rank after filtering
        leaderboardEntries.sort { $0.score > $1.score }
        for (index, _) in leaderboardEntries.enumerated() {
            leaderboardEntries[index].rank = index + 1
        }
        
        // Save context after score updates
        try? modelContext.save()
    }
    
    private func updateTimeUntilReset() {
        // Assume LeaderboardService.timeUntilReset() returns (days: Int, hours: Int)
        timeUntilReset = LeaderboardService.timeUntilReset()
    }
    
    
    // MARK: - League Progression View
    private var leagueProgressionView: some View {
        let theme = themeManager.currentTheme
        return HStack(spacing: 16) {
            ForEach(League.allCases) { league in
                VStack(spacing: 8) {
                    ZStack {
                        // Trophy base
                        RoundedRectangle(cornerRadius: 8)
                            .fill(league == userLeague ? league.baseColor : Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        // Trophy icon
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundColor(league == userLeague ? league.color : Color.gray.opacity(0.5))
                    }
                    
                    Text(league.displayName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(league == userLeague ? theme.textPrimary : theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
}

// MARK: - Duolingo Style Leaderboard Row
struct DuolingoLeaderboardRowView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    @Environment(ThemeManager.self) private var themeManager
    
    private var theme: any AppTheme {
        themeManager.currentTheme
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            rankBadgeView
            
            // Avatar (placeholder for now)
            avatarView
            
            // User Info with enhanced shadows for better readability on gradient
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.username)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1) // Enhanced shadow for better contrast
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0) // Double shadow for depth
                
                HStack(spacing: 6) {
                    // Country flag placeholder (using emoji for now)
                    Text("🇺🇸")
                        .font(.system(size: 12))
                    
                    // Streak/Level number (placeholder)
                    Text("\(entry.level)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
            }
            
            Spacer()
            
            // Score - use rank badge color for harmony and high impact
            Text("\(entry.score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(rankBadgeColor) // Match rank badge color for harmony
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1) // Enhanced shadow for contrast
                .shadow(color: rankBadgeColor.opacity(0.3), radius: 1, x: 0, y: 0) // Subtle glow effect
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        // Removed background/stroke from individual rows - handled by outer container
    }
    
    private var rankBadgeView: some View {
        ZStack {
            // Circle background with gradient for top 3, solid for others
            if rank <= 3 {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rankBadgeColor.opacity(0.3), rankBadgeColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(rankBadgeColor.opacity(0.5), lineWidth: 2)
                    )
            } else {
            Circle()
                .fill(rankBadgeColor.opacity(0.2))
                .frame(width: 36, height: 36)
            }
            
            // Show rank number for all ranks (1, 2, 3, 4+) with special styling for top 3
            if rank <= 3 {
                // Top 3: Show number with icon overlay for distinction
                ZStack {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(rankBadgeColor)
                    
                    // Subtle sparkle effect for top 3
                Image(systemName: rankIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(rankBadgeColor.opacity(0.6))
                        .offset(x: 8, y: -8)
                }
            } else {
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(rankBadgeColor)
            }
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "sparkle"
        case 2: return "star.fill"
        case 3: return "star.fill"
        default: return "circle.fill"
        }
    }
    
    private var avatarView: some View {
        // Placeholder avatar - will be replaced with actual avatar when feature is implemented
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isCurrentUser ? [.purple, .pink] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            
            if isCurrentUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            } else {
                // Placeholder: Use first letter of username
                Text(String(entry.username.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var rankBadgeColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .green
        }
    }
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

// NOTE: This LeaderboardRowView (the original view) is likely superseded by DuolingoLeaderboardRowView.
// It is kept here for compilation completeness based on the provided code structure.
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
