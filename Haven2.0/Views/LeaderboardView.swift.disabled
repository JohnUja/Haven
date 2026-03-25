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
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    // OPTIMIZED: Sort for Duolingo-style league grouping
    // Each league group contains exactly 30 users
    // Note: SwiftData @Query doesn't support fetchLimit, so we limit in code
    @Query(sort: [SortDescriptor(\User.level, order: .reverse), SortDescriptor(\User.currentXP, order: .reverse)]) 
    private var users: [User]
    
    // Tasks: Sort by start time for productivity score calculation
    @Query(sort: [SortDescriptor(\Task.startTime, order: .reverse)]) 
    private var tasks: [Task]
    
    // Goals: Sort by creation date for productivity score calculation
    @Query(sort: [SortDescriptor(\Goal.createdAt, order: .reverse)]) 
    private var goals: [Goal]
    
    @State private var leaderboardType: LeaderboardType = .local
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var timeUntilReset: (days: Int, hours: Int) = (0, 0)
    @State private var currentLeague: League = .gold // Placeholder - should be calculated from user score
    @State private var countdownTimer: Timer? // FIX: Store timer to invalidate on disappear
    @State private var showingTop3Award: Bool = false
    @State private var top3AwardRank: Int = 0
    
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
                        .padding(.top, 8) // Reduced from 16 to move content higher
                        
                        // Top bar with league name and time
                        HStack {
                            // League name (smaller, top left) with enhanced readability
                            Text("\(userLeague.displayName) League")
                                .font(themeManager.currentTheme.headerFont) // Theme font
                                .foregroundColor(themeManager.currentTheme.textPrimary) // Theme-aware
                                .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.3), radius: 3, x: 0, y: 1) // Theme-aware shadow
                            
                            Spacer()
                            
                            // Time remaining (top right) with increased backdrop opacity
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.currentTheme.accentColor) // Theme-aware
                                
                                Text("\(timeUntilReset.days) days")
                                    .font(themeManager.currentTheme.bodyFont) // Theme font
                                    .foregroundColor(themeManager.currentTheme.textPrimary) // Theme-aware
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.accentColor.opacity(0.25)) // Theme-aware
                                    .overlay(
                                        Capsule()
                                            .stroke(themeManager.currentTheme.accentColor.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // League Progression Trophies (closer to top)
                        leagueProgressionView
                            .padding(.horizontal, 20)
                        
                        // Top 30 Leaderboard (Duolingo style - clean, no nested containers)
                        VStack(alignment: .leading, spacing: 12) {
                            if League.canAdvance(rank: userRank) {
                                Text("Top 10 advance to next league")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 20)
                            }
                            
                            // Leaderboard entries - clean list with single background container
                            // Show all 30 users in the league group
                            VStack(spacing: 0) {
                                ForEach(Array(leaderboardEntries.prefix(30).enumerated()), id: \.element.id) { index, entry in
                                    let position = getLeaguePosition(for: index)
                                    
                                    // Zone Marker (Duolingo-style indicator on left edge)
                                    HStack(spacing: 0) {
                                        // Zone indicator bar (thin vertical bar on left)
                                        zoneIndicatorBar(position: position, theme: themeManager.currentTheme)
                                            .frame(width: 4)
                                        
                                        DuolingoLeaderboardRowView(
                                            entry: entry,
                                            rank: index + 1,
                                            isCurrentUser: entry.userID == currentUser?.id,
                                            leaguePosition: position
                                        )
                                    }
                                    .onAppear {
                                        // Show top 3 award popup when user reaches top 3
                                        if entry.userID == currentUser?.id && index < 3 && !showingTop3Award {
                                            top3AwardRank = index + 1
                                            showingTop3Award = true
                                        }
                                    }
                                    
                                    if index < 29 {
                                        Divider()
                                            .padding(.leading, 84) // Adjusted for zone indicator
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
                        
                        // Note: All 30 users are shown above, so no separate "Your Position" section needed
                        
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
        NavigationStack {
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
                        dismiss()
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
                
                // Note: LeaderboardView is a struct (value type), so no need for [weak self]
                // Structs don't have retain cycles. The timer will be invalidated in onDisappear.
                countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                    updateTimeUntilReset()
                }
            }
            .onDisappear {
                // FIX: Invalidate timer when view disappears
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
            .onChange(of: leaderboardType) { _, _ in
                refreshLeaderboard()
            }
            .refreshable {
                refreshLeaderboard()
            }
            .sheet(isPresented: $showingTop3Award) {
                top3AwardSheet
            }
        }
    }
    
    private func refreshLeaderboard() {
        // OPTIMIZED: Limit users to 30 for Duolingo-style league grouping
        // Since @Query doesn't support fetchLimit, we limit in code
        let limitedUsers = Array(users.prefix(30))
        let limitedTasks = Array(tasks.prefix(500))
        let limitedGoals = Array(goals.prefix(200))
        
        // Calculate and update leaderboard
        leaderboardEntries = LeaderboardService.getLeaderboard(
            users: limitedUsers,
            tasks: limitedTasks,
            goals: limitedGoals,
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
        
        // OPTIMIZED: Filter by league (Duolingo-style grouping)
        // Only show users in the same league as the current user
        if let userEntry = userEntry {
            let userLeague = League.leagueForScore(userEntry.score)
            leaderboardEntries = leaderboardEntries.filter { entry in
                League.leagueForScore(entry.score) == userLeague
            }
            // Re-rank after league filtering
            leaderboardEntries.sort { $0.score > $1.score }
            for (index, _) in leaderboardEntries.enumerated() {
                leaderboardEntries[index].rank = index + 1
            }
        }
        
        // FIX: Ensure modelContext.save() happens on MainActor (SwiftData requirement)
        _Concurrency.Task { @MainActor in
            try? modelContext.save()
        }
    }
    
    // MARK: - League Position Helper
    /// Determine league position status based on rank (Duolingo-style)
    /// - Top 3 (ranks 1-3): Get awards
    /// - Advancing (ranks 4-10): Advance to next league
    /// - Stationary (ranks 11-25): Stay in current league
    /// - Demoted (ranks 26-30): Get demoted
    private func getLeaguePosition(for index: Int) -> LeaguePosition {
        let rank = index + 1 // Convert 0-based index to 1-based rank
        
        if rank <= 3 {
            return .top3
        } else if rank <= 10 {
            return .advancing
        } else if rank <= 25 {
            return .stationary
        } else {
            return .demoted
        }
    }
    
    // MARK: - Zone Indicator Bar (Duolingo-style visual marker)
    @ViewBuilder
    private func zoneIndicatorBar(position: LeaguePosition, theme: any AppTheme) -> some View {
        Rectangle()
            .fill(position.color(theme: theme))
            .frame(maxHeight: .infinity)
            .opacity(0.7)
    }
    
    // MARK: - Top 3 Award Sheet
    private var top3AwardSheet: some View {
        let theme = themeManager.currentTheme
        let medalEmoji: String = {
            switch top3AwardRank {
            case 1: return "🥇"
            case 2: return "🥈"
            case 3: return "🥉"
            default: return "🏆"
            }
        }()
        let rankText: String = {
            switch top3AwardRank {
            case 1: return "1st Place"
            case 2: return "2nd Place"
            case 3: return "3rd Place"
            default: return "Top 3"
            }
        }()
        
        return ZStack {
            // Background
            theme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Medal
                Text(medalEmoji)
                    .font(.system(size: 80))
                
                // Title
                Text("Congratulations!")
                    .font(theme.headerFont)
                    .foregroundColor(theme.textPrimary)
                
                // Rank
                Text(rankText)
                    .font(theme.titleFont)
                    .foregroundColor(theme.accentColor)
                
                // Message
                Text("You're in the top 3!")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Button
                Button(action: {
                    showingTop3Award = false
                }) {
                    Text("Awesome!")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                .fill(theme.accentColor)
                        )
                }
            }
            .padding(40)
        }
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

// MARK: - League Position Status
enum LeaguePosition {
    case top3      // Ranks 1-3: Get awards
    case advancing // Ranks 4-10: Advance to next league
    case stationary // Ranks 11-25: Stay in current league
    case demoted   // Ranks 26-30: Get demoted
    
    var displayText: String {
        switch self {
        case .top3: return "🏆 Top 3"
        case .advancing: return "⬆️ Advancing"
        case .stationary: return "➡️ Staying"
        case .demoted: return "⬇️ Demoted"
        }
    }
    
    // Theme-aware colors (can be customized per theme)
    func color(theme: any AppTheme) -> Color {
        switch self {
        case .top3: return theme.accentColor // Use theme accent for top 3
        case .advancing: return .green // Static: promotion zone
        case .stationary: return theme.textSecondary // Theme-aware: neutral
        case .demoted: return .red // Static: danger zone
        }
    }
    
    // Zone indicator icon
    var zoneIcon: String {
        switch self {
        case .top3: return "star.fill"
        case .advancing: return "arrow.up.circle.fill"
        case .stationary: return "minus.circle.fill"
        case .demoted: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Duolingo Style Leaderboard Row
struct DuolingoLeaderboardRowView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let leaguePosition: LeaguePosition?
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
                    .foregroundColor(theme.textPrimary) // Theme-aware
                    .shadow(color: theme.textPrimary.opacity(0.3), radius: 3, x: 0, y: 1) // Theme-aware shadow
                
                HStack(spacing: 6) {
                    // Country flag placeholder (using emoji for now)
                    Text("🇺🇸")
                        .font(.system(size: 12))
                    
                    // Streak/Level number (placeholder)
                    Text("\(entry.level)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary) // Theme-aware
                }
            }
            
            Spacer()
            
            // Score - use rank badge color for harmony and high impact
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(rankBadgeColor) // Match rank badge color for harmony (theme-aware)
                    .shadow(color: rankBadgeColor.opacity(0.3), radius: 3, x: 0, y: 1) // Theme-aware shadow
                
                // League Position Badge (if provided and is current user)
                if let position = leaguePosition, isCurrentUser {
                    HStack(spacing: 4) {
                        Image(systemName: position.zoneIcon)
                            .font(.system(size: 8))
                        Text(position.displayText)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(position.color(theme: theme))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(position.color(theme: theme).opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(position.color(theme: theme), lineWidth: 1)
                            )
                    )
                }
            }
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
                        colors: isCurrentUser 
                            ? [theme.accentColor, theme.accentColor.opacity(0.7)] // Theme-aware for current user
                            : [theme.textSecondary.opacity(0.3), theme.textSecondary.opacity(0.2)], // Theme-aware for others
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            
            if isCurrentUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.textPrimary) // Theme-aware
            } else {
                // Placeholder: Use first letter of username
                Text(String(entry.username.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary) // Theme-aware
            }
        }
    }
    
    private var rankBadgeColor: Color {
        // Use theme accent for top 3, theme colors for others
        switch rank {
        case 1: return theme.accentColor // Gold - use theme accent
        case 2: return theme.textSecondary // Silver - theme-aware
        case 3: return theme.accentColor.opacity(0.8) // Bronze - theme accent variant
        default: return theme.textPrimary.opacity(0.6) // Others - theme-aware
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
