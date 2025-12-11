//
//  FeedView.swift
//  Haven2.0
//
//  Created by John Uja
//  Updated: Fixed 'themeManager not found' scope errors in child views
//

import SwiftUI
import SwiftData
import AudioToolbox

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @Query private var goals: [Goal]
    @Query private var routines: [DailyRoutine]
    @Query private var reactions: [FeedReaction]
    @Query private var comments: [FeedComment]
    @Query private var moodEntries: [MoodEntry]
    
    @State private var feedMode: FeedMode = .personal
    @State private var selectedReaction: ReactionType? = nil
    @State private var showingCommentOptions: String? = nil // feedItemID
    @State private var showingCommentsForItem: String? = nil // feedItemID - to show all comments
    @State private var showingFeedSettings = false
    @State private var showingLeaderboard = false
    
    private var currentUser: User? {
        users.first
    }
    
    // Calculate unread notification count (reactions + comments on user's feed items)
    private var unreadNotificationCount: Int {
        guard let user = currentUser else { return 0 }
        let userFeedItemIDs = personalFeedItems.map { $0.id }
        let unreadReactions = reactions.filter { reaction in
            userFeedItemIDs.contains(reaction.feedItemID) && 
            reaction.userID != user.id // Not from self
        }.count
        let unreadComments = comments.filter { comment in
            userFeedItemIDs.contains(comment.feedItemID) && 
            comment.userID != user.id // Not from self
        }.count
        return unreadReactions + unreadComments
    }
    
    enum FeedMode: String, CaseIterable {
        case personal = "My Activity"
        case global = "Community"
        
        var displayName: String {
            rawValue
        }
    }
    
    // MARK: - Feed Items
        private var personalFeedItems: [FeedItem] {
            guard let user = currentUser else { return [] }
            var items: [FeedItem] = []
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
           
            // Routine Highlights - Show completed routines from last month
            let completedRoutines = routines.filter { routine in
                routine.userID == user.id && 
                routine.endDate != nil && 
                routine.endDate! >= monthAgo &&
                routine.endDate! <= Date()
            }
            for routine in completedRoutines.prefix(10) {
                items.append(.routineCompleted(user: user, routine: routine))
            }
           
            // Mood Logs (Private) - Show from last month
            let recentMoods = moodEntries.filter { 
                $0.userID == user.id && $0.timestamp >= monthAgo 
            }
            for mood in recentMoods.prefix(5) {
                items.append(.moodLog(user: user, moodEntry: mood))
            }
           
            // Goal Milestone Completions (Private) - Show from last month
            for goal in goals.filter({ $0.userID == user.id }) {
                let completedMilestones = (goal.milestones ?? []).filter { $0.isComplete }
                
                for milestone in completedMilestones {
                    let milestoneDate = milestone.deadline ?? goal.createdAt
                    if milestoneDate >= monthAgo {
                        items.append(.goalMilestoneCompleted(user: user, goal: goal, milestone: milestone))
                    }
                }
            }
           
            // Goal Completions - Show completed goals from last month
            let completedGoals = goals.filter { 
                $0.userID == user.id && 
                $0.status == .completed && 
                $0.createdAt >= monthAgo 
            }
            for goal in completedGoals.prefix(5) {
                items.append(.goalCompleted(user: user, goal: goal))
            }
           
            // Level Up - Show if user leveled up recently (check if level > 1)
            if user.level > 1 {
                items.append(.levelUp(user: user, level: user.level))
            }
           
            // Momentum Status - Always show if user has momentum
            if user.momentumDays > 0 {
                items.append(.momentumStatus(user: user, days: user.momentumDays))
            }
           
            return items.sorted { $0.timestamp > $1.timestamp }
        }
    
    private var globalFeedItems: [FeedItem] {
        var items: [FeedItem] = []
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        // Only show items from users who opted in to sharing
        // For now, show all (will add privacy check later)
        
        // XP Level Progression (Public by default)
        for user in users {
            if user.level > 1 {
                items.append(.levelUp(user: user, level: user.level))
            }
        }
        
        // Goal Completions (Opt-in)
        let completedGoals = goals.filter { $0.status == .completed && $0.createdAt >= weekAgo }
        for goal in completedGoals.prefix(20) {
            if let user = users.first(where: { $0.id == goal.userID }) {
                items.append(.goalCompleted(user: user, goal: goal))
            }
        }
        
        // Routine Milestones (Opt-in)
        // TODO: Add routine milestone tracking
        
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var currentFeedItems: [FeedItem] {
        feedMode == .personal ? personalFeedItems : globalFeedItems
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching home screen
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Feed Heading (reduced size, changed to "Feed")
                    HStack {
                        // Trophy icon leading to leaderboard - REDUCED THICKNESS
                        Button(action: {
                            showingLeaderboard = true
                        }) {
                            Image(systemName: "trophy") // Outline instead of fill
                                .font(.system(size: 20, weight: .regular)) // REDUCED: from .semibold to .regular
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                        
                        // Feed text - Bigger font (similar to plan/focus tabs)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Feed")
                                .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold) - bigger
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Heart icon for notifications (with dynamic badge) - REDUCED THICKNESS
                        HStack(spacing: 20) { // Increased spacing between icons
                            Button(action: {
                                // Show notifications/interactions
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "heart") // Outline instead of fill
                                        .font(.system(size: 20, weight: .regular)) // REDUCED: from .semibold to .regular
                                        .foregroundColor(themeManager.currentTheme.textPrimary)
                                    
                                    // Dynamic notification badge - only show if there are unread notifications
                                    if unreadNotificationCount > 0 {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text(unreadNotificationCount > 99 ? "99+" : "\(unreadNotificationCount)")
                                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 6, y: -6)
                                    }
                                }
                            }
                            
                            // Settings icon - REDUCED THICKNESS
                            Button(action: {
                                showingFeedSettings = true
                            }) {
                                Image(systemName: "gearshape") // Outline instead of fill
                                    .font(.system(size: 20, weight: .regular)) // REDUCED: from .semibold to .regular
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Feed Mode Toggle - Similar to plan/focus tabs with same animation
                    HStack(spacing: 0) {
                        // My Activity Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                                feedMode = .personal
                            }
                        }) {
                            Text("My Activity")
                                .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular) - smaller than Feed
                                .fontWeight(.bold)
                                .foregroundColor(feedMode == .personal ? themeManager.currentTheme.textPrimary : themeManager.currentTheme.textPrimary.opacity(0.6))
                                .frame(maxWidth: .infinity) // Fixed equal width
                                .frame(height: 40)
                                .background(
                                    Group {
                                        if feedMode == .personal {
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
                        
                        // Community Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { // Bubble bounce animation
                                feedMode = .global
                            }
                        }) {
                            Text("Community")
                                .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular) - smaller than Feed
                                .fontWeight(.bold)
                                .foregroundColor(feedMode == .global ? themeManager.currentTheme.textPrimary : themeManager.currentTheme.textPrimary.opacity(0.6))
                                .frame(maxWidth: .infinity) // Fixed equal width
                                .frame(height: 40)
                    .background(
                                    Group {
                                        if feedMode == .global {
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
                    
                    // Feed Content
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if currentFeedItems.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(currentFeedItems.prefix(50), id: \.id) { item in
                                    FeedItemCardView(
                                        item: item,
                                        currentUserID: currentUser?.id,
                                        reactions: reactions.filter { $0.feedItemID == item.id },
                                        comments: comments.filter { $0.feedItemID == item.id },
                                        selectedReaction: $selectedReaction,
                                        showingCommentOptions: $showingCommentOptions,
                                        showingComments: showingCommentsForItem == item.id,
                                        onReaction: { reactionType in
                                            handleReaction(itemID: item.id, reactionType: reactionType)
                                        },
                                        onComment: { commentText, reactionType in
                                            handleComment(itemID: item.id, commentText: commentText, reactionType: reactionType)
                                        },
                                        onToggleComments: {
                                            showingCommentsForItem = showingCommentsForItem == item.id ? nil : item.id
                                        },
                                        onProfileTap: { user in
                                            // Navigate to profile - handled by navigation
                                            if user.id == currentUser?.id {
                                                // Navigate to own profile (editable)
                                                // This will be handled by MainTabView navigation
                                            } else {
                                                // Navigate to other user's profile (read-only)
                                                // This will be handled by MainTabView navigation
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                    .drawingGroup() // Performance optimization
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline) // Remove large heading
            .navigationBarHidden(true) // Remove feed header text completely
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingFeedSettings) {
                FeedSettingsView()
            }
            .sheet(isPresented: $showingLeaderboard) {
                NavigationView {
                    LeaderboardView()
                }
            }
        }
    }
    
    // MARK: - Find Users/Friends Section
    private var findUsersSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Navigate to find users/friends
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    Text("Find Users / Friends")
                        .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                        .fill(themeManager.currentTheme.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60, design: .rounded)) // Keep large icon size
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(feedMode == .personal ? "No Activity Yet" : "No Community Activity")
                .appTextStyle(.sectionHeader, theme: themeManager.currentTheme)
            
            Text(feedMode == .personal
                 ? "Complete tasks and goals to see your activity here"
                 : "Community activity will appear here when users share their achievements")
                .appTextStyle(.body, theme: themeManager.currentTheme)
                .opacity(themeManager.currentTheme.textSecondaryOpacity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }
    
    // MARK: - Actions
    private func handleReaction(itemID: String, reactionType: ReactionType) {
        guard let user = currentUser else { return }
        
        // Check if user already reacted
        if let existingReaction = reactions.first(where: { $0.feedItemID == itemID && $0.userID == user.id }) {
            if existingReaction.reactionType == reactionType {
                // Remove reaction if same type clicked
                modelContext.delete(existingReaction)
            } else {
                // Update reaction type
                existingReaction.reactionType = reactionType
            }
        } else {
            // Create new reaction
            let reaction = FeedReaction(
                feedItemID: itemID,
                userID: user.id,
                reactionType: reactionType
            )
            modelContext.insert(reaction)
        }
        
        // Haptic feedback
        AudioServicesPlaySystemSound(1520)
        
        // Sound feedback - changed to a better sound (peek sound)
        AudioServicesPlaySystemSound(1519) // Peek sound - more satisfying
        
        // Show comment options
        withAnimation {
            selectedReaction = reactionType
            showingCommentOptions = itemID
        }
        
        try? modelContext.save()
    }
    
    private func handleComment(itemID: String, commentText: String, reactionType: ReactionType) {
        guard let user = currentUser else { return }
        
        let comment = FeedComment(
            feedItemID: itemID,
            userID: user.id,
            commentText: commentText,
            reactionType: reactionType
        )
        modelContext.insert(comment)
        
        // Hide comment options
        withAnimation {
            showingCommentOptions = nil
            selectedReaction = nil
        }
        
        try? modelContext.save()
    }
}

// MARK: - Feed Item Types
enum FeedItem: Identifiable {
    case routineCompleted(user: User, routine: DailyRoutine)
    case routineStreak(user: User, routine: DailyRoutine, days: Int)
    case moodLog(user: User, moodEntry: MoodEntry)
    case moodTrendSummary(user: User, trend: String)
    case levelUp(user: User, level: Int)
    case skillProgress(user: User, skill: String, progress: Int)
    case momentumStatus(user: User, days: Int)
    case achievementUnlocked(user: User, achievement: String)
    case goalMilestoneCompleted(user: User, goal: Goal, milestone: GoalMilestone)
    case goalCompleted(user: User, goal: Goal)
    
    var id: String {
        switch self {
        case .routineCompleted(let user, let routine):
            return "routine-\(user.id)-\(routine.id)"
        case .routineStreak(let user, let routine, let days):
            return "streak-\(user.id)-\(routine.id)-\(days)"
        case .moodLog(let user, let moodEntry):
            return "mood-\(user.id)-\(moodEntry.id)"
        case .moodTrendSummary(let user, _):
            return "mood-trend-\(user.id)"
        case .levelUp(let user, let level):
            return "level-\(user.id)-\(level)"
        case .skillProgress(let user, let skill, _):
            return "skill-\(user.id)-\(skill)"
        case .momentumStatus(let user, let days):
            return "momentum-\(user.id)-\(days)"
        case .achievementUnlocked(let user, let achievement):
            return "achievement-\(user.id)-\(achievement)"
        case .goalMilestoneCompleted(let user, let goal, let milestone):
            return "milestone-\(user.id)-\(goal.id)-\(milestone.id)"
        case .goalCompleted(let user, let goal):
            return "goal-\(user.id)-\(goal.id)"
        }
    }
    
    var timestamp: Date {
        switch self {
        case .routineCompleted(_, let routine):
            return routine.endDate ?? routine.updatedAt
        case .routineStreak(_, _, _):
            return Date()
        case .moodLog(_, let moodEntry):
            return moodEntry.timestamp
        case .moodTrendSummary(_, _):
            return Date()
        case .levelUp(_, _):
            return Date()
        case .skillProgress(_, _, _):
            return Date()
        case .momentumStatus(_, _):
            return Date()
        case .achievementUnlocked(_, _):
            return Date()
        case .goalMilestoneCompleted(_, let goal, let milestone):
            return milestone.deadline ?? goal.createdAt
        case .goalCompleted(_, let goal):
            return goal.createdAt
        }
    }
    
    var isPrivate: Bool {
        switch self {
        case .moodLog, .moodTrendSummary, .goalMilestoneCompleted, .momentumStatus:
            return true
        case .levelUp, .goalCompleted, .routineCompleted, .routineStreak, .achievementUnlocked, .skillProgress:
            return false
        }
    }
    
    var supportsComments: Bool {
        // Only certain feed element types support comments
        switch self {
        case .routineCompleted, .routineStreak, .levelUp, .goalCompleted, .achievementUnlocked:
            return true // Public achievements support comments
        case .moodLog, .moodTrendSummary, .goalMilestoneCompleted, .momentumStatus, .skillProgress:
            return false // Private items don't support comments
        }
    }
}

// MARK: - Feed Item Card View
struct FeedItemCardView: View {
    let item: FeedItem
    let currentUserID: String?
    let reactions: [FeedReaction]
    let comments: [FeedComment]
    @Binding var selectedReaction: ReactionType?
    @Binding var showingCommentOptions: String?
    let showingComments: Bool
    let onReaction: (ReactionType) -> Void
    let onComment: (String, ReactionType) -> Void
    let onToggleComments: () -> Void
    let onProfileTap: (User) -> Void
    
    @State private var userReaction: ReactionType? = nil
    @State private var showingReactionMenu = false
    
    // MARK: - FIXED: Added Environment Object
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    
    @Query private var allUsers: [User]
    
    private var reactionCounts: [ReactionType: Int] {
        var counts: [ReactionType: Int] = [:]
        for reaction in reactions {
            counts[reaction.reactionType, default: 0] += 1
        }
        return counts
    }
    
    private var dominantReaction: ReactionType? {
        reactionCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var totalReactions: Int {
        reactions.count
    }
    
    private var commentCount: Int {
        comments.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            timeAgoSection
            reactionsAndCommentsRow
            commentOptionsSection
            commentsListSection
            engagementTextSection
        }
        .padding()
        .background(cardBackground)
        .onAppear {
            setUserReaction()
        }
    }
    
    // MARK: - Sub-views to help compiler type-checking
    private var headerSection: some View {
            HStack(spacing: 12) {
                iconView
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemTitle)
                        .appTextStyle(.caption, theme: themeManager.currentTheme)
                    
                    Text(itemDescription)
                        .font(AppStyleSheet.font(for: .caption))
                        .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                }
                
                Spacer()
        }
    }
            
    private var timeAgoSection: some View {
            Text(timeAgoText)
                .font(AppStyleSheet.font(for: .caption))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
    }
            
    private var reactionsAndCommentsRow: some View {
            HStack(spacing: 16) {
            reactionsSection
            Spacer()
            commentCountButton
            profileIconButton
        }
    }
    
    private var reactionsSection: some View {
                HStack(spacing: 12) {
                    ForEach(ReactionType.allCases, id: \.self) { reactionType in
                        ReactionButton(
                            reactionType: reactionType,
                            isSelected: userReaction == reactionType,
                            count: reactionCounts[reactionType] ?? 0,
                    showCount: false,
                            onTap: {
                                onReaction(reactionType)
                                userReaction = userReaction == reactionType ? nil : reactionType
                            }
                        )
            }
                    }
                }
                
    @ViewBuilder
    private var commentCountButton: some View {
                if commentCount > 0 {
            Button(action: {
                onToggleComments()
            }) {
                    HStack(spacing: 4) {
                    Image(systemName: showingComments ? "bubble.right.fill" : "bubble.right")
                            .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                        Text("\(commentCount)")
                            .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                    }
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textTertiaryOpacity))
            }
        }
                }
                
    @ViewBuilder
    private var profileIconButton: some View {
                if let user = itemUser {
            Button(action: {
                onProfileTap(user)
            }) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(user.name.prefix(1).uppercased())
                                .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                                .foregroundColor(.white)
                        )
            }
                }
            }
            
    @ViewBuilder
    private var commentOptionsSection: some View {
            if showingCommentOptions == item.id,
               let reaction = selectedReaction,
               item.supportsComments {
                CommentOptionsView(
                    reactionType: reaction,
                    feedItemType: itemType,
                    onSelect: { commentText in
                        onComment(commentText, reaction)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
    }
    
    @ViewBuilder
    private var commentsListSection: some View {
        if showingComments && !comments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(comments.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { comment in
                    commentRowView(for: comment)
                }
            }
            .padding(.top, 8)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    private func commentRowView(for comment: FeedComment) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if let commentUser = allUsers.first(where: { $0.id == comment.userID }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(commentUser.name.prefix(1).uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let commentUser = allUsers.first(where: { $0.id == comment.userID }) {
                    Text(commentUser.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                
                Text(comment.commentText)
                    .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textSecondaryOpacity))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var engagementTextSection: some View {
            if totalReactions > 0 || commentCount > 0 {
                Text(engagementText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textTertiaryOpacity))
            }
        }
    
    private var cardBackground: some View {
        let theme = themeManager.currentTheme
        return RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(
                        dominantReaction?.color.opacity(0.3) ?? Color.clear,
                        lineWidth: totalReactions > 0 ? theme.selectedStrokeWidth : 0
                    )
            )
    }
    
    private var cardShadowColor: Color {
        dominantReaction?.color.opacity(Double(min(totalReactions, 10)) * 0.05) ?? Color.clear
    }
    
    private var cardShadowRadius: CGFloat {
        CGFloat(min(totalReactions, 10)) * 2
    }
    
    private func setUserReaction() {
            if let userID = currentUserID,
               let reaction = reactions.first(where: { $0.userID == userID }) {
                userReaction = reaction.reactionType
        }
    }
    
    private var iconView: some View {
        let theme = themeManager.currentTheme
        return ZStack {
            Circle()
                .fill(iconColor.opacity(theme.iconBackgroundOpacity))
                .frame(width: theme.iconCircleSize - 4, height: theme.iconCircleSize - 4)
            
            Image(systemName: iconName)
                .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                .foregroundColor(iconColor)
        }
    }
    
    private var iconName: String {
        switch item {
        case .routineCompleted, .routineStreak: return "repeat.circle"
        case .moodLog, .moodTrendSummary: return "heart.text.square"
        case .levelUp: return "star"
        case .skillProgress: return "chart.line.uptrend.xyaxis"
        case .momentumStatus: return "flame"
        case .achievementUnlocked: return "trophy"
        case .goalMilestoneCompleted, .goalCompleted: return "flag"
        }
    }
    
    private var iconColor: Color {
        switch item {
        case .routineCompleted, .routineStreak: return .blue
        case .moodLog, .moodTrendSummary: return .purple
        case .levelUp: return .yellow
        case .skillProgress: return .green
        case .momentumStatus: return .orange
        case .achievementUnlocked: return .yellow
        case .goalMilestoneCompleted, .goalCompleted: return .blue
        }
    }
    
    private var itemTitle: String {
        switch item {
        case .routineCompleted(_, _):
            return "Routine Completed"
        case .routineStreak(_, _, let days):
            return "\(days) Day Streak!"
        case .moodLog(_, _):
            return "Mood Logged"
        case .moodTrendSummary(_, _):
            return "Mood Trend"
        case .levelUp(_, let level):
            return "Level \(level)!"
        case .skillProgress(_, let skill, let progress):
            return "+\(progress)% \(skill)"
        case .momentumStatus(_, let days):
            return "\(days) Day Momentum"
        case .achievementUnlocked(_, _):
            return "Achievement Unlocked"
        case .goalMilestoneCompleted(_, _, let milestone):
            return "Milestone: \(milestone.title)"
        case .goalCompleted(_, let goal):
            return "Goal Completed: \(goal.title)"
        }
    }
    
    private var itemDescription: String {
        switch item {
        case .routineCompleted(_, let routine):
            return "Completed \(routine.title)"
        case .routineStreak(let user, let routine, _):
            return "You've done \(routine.title) for \(user.momentumDays) days straight!"
        case .moodLog(_, let moodEntry):
            return "Logged \(moodEntry.coreMood.displayName) mood"
        case .moodTrendSummary(_, let trend):
            return trend
        case .levelUp(_, let level):
            return "Reached level \(level)"
        case .skillProgress(_, let skill, _):
            return "Progress on \(skill)"
        case .momentumStatus(_, _):
            return "Keep it up!"
        case .achievementUnlocked(_, let achievement):
            return achievement
        case .goalMilestoneCompleted(_, let goal, _):
            return "Completed milestone for goal: \(goal.title)"
        case .goalCompleted(_, let goal):
            return "Completed goal: \(goal.title)"
        }
    }
    
    private var itemUser: User? {
        switch item {
        case .routineCompleted(let user, _), .routineStreak(let user, _, _),
             .moodLog(let user, _), .moodTrendSummary(let user, _),
             .levelUp(let user, _), .skillProgress(let user, _, _),
             .momentumStatus(let user, _), .achievementUnlocked(let user, _),
             .goalMilestoneCompleted(let user, _, _), .goalCompleted(let user, _):
            return user
        }
    }
    
    private var itemType: String {
        switch item {
        case .routineCompleted, .routineStreak: return "routine"
        case .moodLog, .moodTrendSummary: return "mood"
        case .levelUp: return "level"
        case .skillProgress: return "progress"
        case .momentumStatus: return "momentum"
        case .achievementUnlocked: return "achievement"
        case .goalMilestoneCompleted, .goalCompleted: return "goal"
        }
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
    
    private var engagementText: String {
        if totalReactions == 0 && commentCount == 0 {
            return "Be the first to react"
        } else if totalReactions > 0 && commentCount == 0 {
            return "People liked this"
        } else if totalReactions > 0 && commentCount > 0 {
            if totalReactions + commentCount > 10 {
                return "Lots of people engaged with this +"
            } else {
                return "People engaged with this"
            }
        } else {
            return "People commented"
        }
    }
}

// MARK: - Reaction Button
struct ReactionButton: View {
    @Environment(ThemeManager.self) private var themeManager
    
    let reactionType: ReactionType
    let isSelected: Bool
    let count: Int
    let showCount: Bool
    let onTap: () -> Void
    
    private var iconName: String {
        // Use outline version, fill when selected
        switch reactionType {
        case .joy: return isSelected ? "heart.fill" : "heart"
        case .inspired: return isSelected ? "sparkles" : "sparkles" // Sparkles is already outline
        case .calm: return isSelected ? "moon.stars.fill" : "moon.stars"
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onTap()
            }
        }) {
            Image(systemName: iconName)
                .font(isSelected ? themeManager.currentTheme.headerFont : themeManager.currentTheme.titleFont) // Use theme fonts
                .foregroundColor(isSelected ? reactionType.color : reactionType.color.opacity(0.6))
                .scaleEffect(isSelected ? 1.15 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comment Options View
struct CommentOptionsView: View {
    let reactionType: ReactionType
    let feedItemType: String
    let onSelect: (String) -> Void
    
    // MARK: - FIXED: Added Environment Object
    @Environment(ThemeManager.self) private var themeManager
    
    private var commentOptions: [String] {
        // Dynamic comments based on reaction type and feed item type
        switch (reactionType, feedItemType) {
        case (.joy, "routine"):
            return ["This made me smile!", "Way to go!", "Amazing!"]
        case (.joy, "level"):
            return ["Congratulations!", "So proud!", "Incredible!"]
        case (.joy, "goal"):
            return ["Well done!", "Fantastic!", "You did it!"]
        case (.inspired, "routine"):
            return ["This inspired me", "Keep it up!", "So motivating!"]
        case (.inspired, "level"):
            return ["You're amazing!", "This motivates me", "Keep going!"]
        case (.inspired, "goal"):
            return ["Inspiring!", "You're on fire!", "This is great!"]
        case (.calm, "routine"):
            return ["Peaceful energy", "Well done", "Calm achievement"]
        case (.calm, "level"):
            return ["Peaceful progress", "Nice work", "Calm success"]
        case (.calm, "goal"):
            return ["Peaceful completion", "Well done", "Calm achievement"]
        default:
            return ["Nice!", "Great job!", "Well done!"]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(commentOptions, id: \.self) { comment in
                Button(action: {
                    onSelect(comment)
                }) {
                    Text(comment)
                        .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius - 4)
                                .fill(reactionType.color.opacity(themeManager.currentTheme.iconBackgroundOpacity))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Feed Settings View
struct FeedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var shareWithCommunity = true
    @State private var showPersonalFeed = true
    @State private var showGlobalFeed = true
    @State private var showLevelUps = true
    @State private var showGoalCompletions = true
    @State private var showRoutineCompletions = true
    @State private var showMomentumStatus = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching home screen style
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Privacy Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Privacy")
                                .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Share with Community")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("Anonymously share your major achievements with the global community")
                                            .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                                            .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textSecondaryOpacity))
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $shareWithCommunity)
                                        .tint(.purple)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                        .fill(themeManager.currentTheme.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                                                .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                        )
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Feed Content Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feed Content")
                                .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ToggleRow(title: "Show Personal Feed", isOn: $showPersonalFeed)
                                ToggleRow(title: "Show Global Feed", isOn: $showGlobalFeed)
                                ToggleRow(title: "Level Ups", isOn: $showLevelUps)
                                ToggleRow(title: "Goal Completions", isOn: $showGoalCompletions)
                                ToggleRow(title: "Routine Completions", isOn: $showRoutineCompletions)
                                ToggleRow(title: "Momentum Status", isOn: $showMomentumStatus)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Feed Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func ToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(.purple)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                .fill(themeManager.currentTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                        .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
    }
}

#Preview {
    FeedView()
        .modelContainer(for: [User.self, FeedReaction.self, FeedComment.self], inMemory: true)
        .environment(ThemeManager())
}
