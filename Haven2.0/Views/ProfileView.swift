//
//  ProfileView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var themes: [Theme]
    @State private var showingMomentumPopup = false
    @State private var showingSignOutConfirmation = false
    @State private var showingSettings = false
    @State private var showingEditProfile: Bool = false
    @State private var showingMomentumPopupForJourney = false
    @State private var showingXPInfoPopup = false
    @State private var showingTimeCrystalsInfoPopup = false
    @State private var showingWeeklyScoreInfoPopup = false
    @State private var showingMomentum = false
    @State private var showingThemeShop = false
    @State private var showingPaywall = false
    @State private var showingDataVisualization = false
    @State private var showingDocuments = false
    
    private var currentUser: User? {
        LocalUserProvisioningService.resolveCurrentUser(from: users)
    }
    
    private var ownedThemes: [Theme] {
        themes.filter { theme in
            currentUser?.ownedThemeIDs.contains(theme.id) ?? false
        }
    }
    
    // Firebase Auth user details
    private var firebaseUserDisplayName: String? {
        authService.currentUser?.displayName
    }
    
    private var firebaseUserEmail: String? {
        authService.currentUser?.email
    }
    
    private var firebaseUserProvider: String? {
        guard let providerData = authService.currentUser?.providerData.first else { return nil }
        return providerData.providerID
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching homescreen style
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        if let user = currentUser {
                            profileHeaderSection(user: user)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                        
                        // YOUR JOURNEY Section
                        yourJourneySection
                            .padding(.horizontal, 20)
                        
                        // SETTINGS Section
                        settingsSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline) // Remove large heading
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView().environment(authService)) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                    }
                }
                .sheet(isPresented: $showingMomentum) {
                    MomentumPageView()
                        .environment(themeManager)
                        .environment(\.modelContext, modelContext)
                }
                .sheet(isPresented: $showingThemeShop) {
                    ThemeShopView()
                        .environment(themeManager)
                        .environment(\.modelContext, modelContext)
                }
                .sheet(isPresented: $showingDocuments) {
                    NavigationStack {
                        Text("Documents")
                            .navigationTitle("Documents")
                    }
                    .environment(\.modelContext, modelContext)
                }
                .sheet(isPresented: $showingDataVisualization) {
                    DataVisualizationView()
                        .environment(themeManager)
                        .environment(\.modelContext, modelContext)
                }
                .sheet(isPresented: $showingPaywall) {
                    PaywallView(triggerReason: .taskLimit)
                        .environment(themeManager)
                        .environment(\.modelContext, modelContext)
                }
                .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        handleSignOut()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
                .overlay(
                    popupOverlayContent
                )
                .sheet(isPresented: $showingEditProfile) {
                    NavigationStack {
                        ProfileEditView()
                    }
                    .environment(themeManager)
                    .environment(authService)
                    .environment(\.modelContext, modelContext)
                }
                }
            }
        }
        
        // MARK: - Sign Out Handler
    func handleSignOut() {
            do {
                try authService.signOut()
                // Clear guest task count
                GuestModeService.shared.resetTaskCount()
                // Clear persisted dates
                DatePersistenceService.shared.clearAllDates()
            } catch {
                print("Error signing out: \(error)")
            }
        }
        
    // MARK: - Profile Header Helper Views
    
    @ViewBuilder
    private func avatarView(user: User) -> some View {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.3), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // User's photo from Firebase Auth (if available)
                        if let photoURL = authService.currentUser?.photoURL,
                           let url = URL(string: photoURL.absoluteString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            // Fallback to system icon
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
                
    // ⭐️ FIX: Extracted user info into its own view
    @ViewBuilder
    private func userInfoView(user: User) -> some View {
                // User Info - Show Firebase Auth details if available
                VStack(spacing: 6) {
                    Text(firebaseUserDisplayName ?? user.name)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    if let email = firebaseUserEmail {
                        Text(email)
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                    }
                    
                    Text("Level \(user.level)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
        }
                }
                
    // ⭐️ FIX: Extracted time crystals into its own view
    @ViewBuilder
    private func timeCrystalsView(user: User) -> some View {
        HStack(spacing: 12) {
            Text("✨")
                .font(.system(size: 20))
            
            Text("\(user.gamificationCurrency)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)
            
            Text("Time Crystals")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                .fill(themeManager.currentTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                        .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
    }
    
    // ⭐️ FIX: Main function is now much simpler
    func profileHeaderSection(user: User) -> some View {
        VStack(spacing: 20) {
            // Avatar with user's photo from auth provider or custom avatar - Clickable to edit profile
            Button(action: {
                showingEditProfile = true
            }) {
                avatarView(user: user)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button("Edit Profile") {
                showingEditProfile = true
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(themeManager.currentTheme.accentColor)
            
            // User Info
            userInfoView(user: user)
            
            // Time Crystals
            timeCrystalsView(user: user)
            }
            .padding(themeManager.currentTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                    .fill(themeManager.currentTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                            .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                    )
            )
        }
        
        // MARK: - YOUR JOURNEY Section
    var yourJourneySection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Journey")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.horizontal, 4)
                
            // Talkative box at top of journey section
            if let user = currentUser {
                journeyTalkativeBox(user: user)
            }
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    if let user = currentUser {
                        // XP Block
                        journeyBlock(
                            title: "XP",
                            value: "\(user.currentXP)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        // Time Crystals Block
                        journeyBlock(
                            title: "Time Crystals",
                            value: "✨ \(user.gamificationCurrency)",
                            icon: "sparkles",
                            color: .orange
                        )
                        
                    // Momentum Block - Viewable in tab, not navigable
                    momentumJourneyBlock(
                            title: "Momentum",
                            value: "\(user.momentumDays) days",
                            icon: "flame.fill",
                            color: .orange,
                        momentumDays: user.momentumDays,
                        bonusPercentage: Int((GamificationService.getMomentumBonus(user: user) - 1.0) * 100)
                        )
                        
                        
                    journeyBlock(
                            title: "Weekly Score",
                            value: "\(user.weeklyProductivityScore)",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )
                    }
                }
            }
        }
    
    // MARK: - Journey Talkative Box
    func journeyTalkativeBox(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                
                Text("Your Progress")
                    .font(AppStyleSheet.font(for: .body))
                    .foregroundColor(.white)
            }
            
            Text("Track your journey! Complete tasks to earn XP, build momentum, and raise your weekly score. Your weekly score resets every Monday and helps you spot consistency over time.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
        }
        
        // MARK: - Journey Block
    func journeyBlock(title: String, value: String, icon: String, color: Color) -> some View {
        Button(action: {
            if title == "XP" {
                showingXPInfoPopup = true
            } else if title == "Time Crystals" {
                showingTimeCrystalsInfoPopup = true
            } else if title == "Weekly Score" {
                showingWeeklyScoreInfoPopup = true
            }
        }) {
            journeyBlockContent(title: title, value: value, icon: icon, color: color)
        }
    }
    
    @ViewBuilder
    private func journeyBlockContent(title: String, value: String, icon: String, color: Color) -> some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.glassBackground.opacity(0.95))
                    .frame(width: 60, height: 60)
                    .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.35), lineWidth: 1.5)
                    )
                
                if icon == "sparkles" {
                    Text("✨")
                        .font(.system(size: 24))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(theme.textPrimary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Momentum Journey Block (Viewable in tab, not navigable)
    func momentumJourneyBlock(title: String, value: String, icon: String, color: Color, momentumDays: Int, bonusPercentage: Int) -> some View {
        let theme = themeManager.currentTheme
        
        return Button(action: {
            // Show momentum view in a sheet or popover instead of navigating
            showingMomentumPopupForJourney = true
        }) {
            VStack(spacing: 12) {
                ZStack {
                    // 3D effect: Color-filled box with shadow outline
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.glassBackground.opacity(0.95))
                        .frame(width: 60, height: 60)
                        .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.35), lineWidth: 1.5)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(title)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(theme.textPrimary.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            showingMomentumPopupForJourney = true
        }
    }
    
    func xpProgressView(user: User) -> some View {
            let currentLevelXP = LevelService.xpForLevel(user.level)
            let nextLevelXP = LevelService.xpForLevel(user.level + 1)
            let xpInCurrentLevel = user.currentXP - currentLevelXP
            let xpNeeded = nextLevelXP - currentLevelXP
            let progress = LevelService.calculateProgress(user: user)
            
            return VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.system(size: 14))
                        
                        Text("Experience")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(xpInCurrentLevel)/\(xpNeeded) XP")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress fill with gradient and subtle glow
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 12)
            }
        }
        
    func weeklyScoreView(user: User) -> some View {
            let calendar = Calendar.current
            let now = Date()
            let weekday = calendar.component(.weekday, from: now)
            let daysToSubtract = (weekday + 5) % 7
            let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
            let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            let daysRemaining = calendar.dateComponents([.day], from: now, to: nextWeekStart).day ?? 0
            
            // Calculate progress percentage for this week
            let progressPercentage = min(Double(user.weeklyProductivityScore) / 1000.0, 1.0) // Assuming 1000 is max weekly score
            
            return VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.2), .pink.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text("Weekly Score")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(user.weeklyProductivityScore)")
                    .font(AppStyleSheet.font(for: .settingsText))
                    .foregroundColor(.white)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    
                    Text("Resets in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
        }
        
    // MARK: - Settings Section (Theme-Aware)
    var settingsSection: some View {
        let theme = themeManager.currentTheme
        return VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // Momentum & Progression
                if currentUser != nil {
                    profileSettingsButton(
                        title: "Momentum & Progression",
                        subtitle: "Streaks, bonuses, and milestone rewards",
                        icon: "flame.fill",
                        color: .orange,
                        action: { showingMomentum = true }
                    )
                }
                
                // Theme Shop
                profileSettingsButton(
                    title: "Theme Shop",
                    subtitle: "Switch themes and browse unlockables",
                    icon: "storefront",
                    color: .purple,
                    action: { showingThemeShop = true }
                )
                
                // Data Visualization & Export
                profileSettingsButton(
                    title: "Data & Export",
                    subtitle: "Review patterns and export your data",
                    icon: "chart.bar.fill",
                    color: .blue,
                    action: { showingDataVisualization = true }
                )
                
                // Documents
                profileSettingsButton(
                    title: "Documents",
                    subtitle: "Reference docs and saved resources",
                    icon: "doc.text.fill",
                    color: .indigo,
                    action: { showingDocuments = true }
                )
                
                // Account
                NavigationLink(destination: ProfileEditView().environment(authService)) {
                    profileSettingsButtonView(
                        title: "Account",
                        subtitle: "Profile details, password, and account actions",
                        icon: "person.circle",
                        color: .teal
                    )
                }
                
                // Upgrade Plan (Paywall)
                Button(action: {
                    showingPaywall = true
                }) {
                    profileSettingsButtonView(
                        title: "Upgrade Plan",
                        subtitle: "Manage Haven+ and premium limits",
                        icon: "crown.fill",
                        color: .yellow
                    )
                }
                
                // Help & Feedback
                Button(action: {
                    // Navigate to help/feedback
                }) {
                    profileSettingsButtonView(
                        title: "Help & Feedback",
                        subtitle: "Support, questions, and future bug reports",
                        icon: "questionmark.circle",
                        color: .pink
                    )
                }
            }
        }
    }
    
    // MARK: - Profile Settings Helper Functions
    private func profileSettingsButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            profileSettingsButtonView(title: title, subtitle: subtitle, icon: icon, color: color)
        }
    }
    
    private func profileSettingsButtonView(title: String, subtitle: String, icon: String, color: Color) -> some View {
        let theme = themeManager.currentTheme
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: theme.iconCircleSize, height: theme.iconCircleSize)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appTextStyle(.settingsText, theme: theme)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(theme.textPrimary.opacity(theme.textSecondaryOpacity))
        }
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    // MARK: - Popup Overlay Content
    @ViewBuilder
    var popupOverlayContent: some View {
        if showingXPInfoPopup {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingXPInfoPopup = false
                    }
                }
            
            xpInfoPopupView
                .transition(.scale.combined(with: .opacity))
        }
        
        if showingTimeCrystalsInfoPopup {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingTimeCrystalsInfoPopup = false
                    }
                }
            
            timeCrystalsInfoPopupView
                .transition(.scale.combined(with: .opacity))
        }
        
        if showingWeeklyScoreInfoPopup {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingWeeklyScoreInfoPopup = false
                    }
                }
            
            weeklyScoreInfoPopupView
                .transition(.scale.combined(with: .opacity))
        }
        
        if showingMomentumPopupForJourney {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingMomentumPopupForJourney = false
                    }
                }
            
            momentumInfoPopupView
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Info Popups
    private var xpInfoPopupView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Experience Points (XP)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    if let user = currentUser {
                        Text("\(user.currentXP) XP")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What builds your level?")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Text("Complete tasks to earn XP. Higher priority tasks and goal-linked tasks give more XP. Your momentum streak multiplies all XP earned!")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let user = currentUser {
                let currentLevelXP = LevelService.xpForLevel(user.level)
                let nextLevelXP = LevelService.xpForLevel(user.level + 1)
                let xpInCurrentLevel = user.currentXP - currentLevelXP
                let xpNeeded = nextLevelXP - currentLevelXP
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress to Level \(user.level + 1)")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                        Spacer()
                        Text("\(xpInCurrentLevel)/\(xpNeeded) XP")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * LevelService.calculateProgress(user: user), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
        .frame(width: 320)
        .padding(.horizontal, 40)
    }
    
    private var timeCrystalsInfoPopupView: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 16) {
            HStack {
                Text("✨")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Crystals")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    if let user = currentUser {
                        // Time Crystals with Clash Royale style font
                        ZStack {
                            // Outline layer
                            ForEach([-1, 0, 1], id: \.self) { x in
                                ForEach([-1, 0, 1], id: \.self) { y in
                                    if x != 0 || y != 0 {
                                        Text("\(user.gamificationCurrency)")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.black.opacity(0.9))
                                            .offset(x: CGFloat(x), y: CGFloat(y))
                                    }
                                }
                            }
                            // Main text
                            Text("\(user.gamificationCurrency)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textPrimary)
                        }
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What are Time Crystals?")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(theme.textPrimary)
                
                Text("Earn Time Crystals by completing tasks. Use them to unlock themes in the Theme Shop, unlock premium features, and more!")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(theme.textPrimary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        .frame(width: 320)
        .padding(.horizontal, 40)
    }
    
    private var momentumInfoPopupView: some View {
        let theme = themeManager.currentTheme
        guard let user = currentUser else {
            return AnyView(EmptyView())
        }
        
        let bonusPercentage = Int((GamificationService.getMomentumBonus(user: user) - 1.0) * 100)
        
        return AnyView(
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Momentum")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("\(user.momentumDays) days")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What is Momentum?")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Build your momentum streak by completing at least one task every day. Your streak multiplies your XP and Time Crystal rewards!")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(theme.textPrimary.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Bonus info
                if bonusPercentage > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Bonus: +\(bonusPercentage)%")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 8)
                }
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
            .frame(width: 320)
            .padding(.horizontal, 40)
        )
    }
    
    private var weeklyScoreInfoPopupView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Score")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    if let user = currentUser {
                        Text("\(user.weeklyProductivityScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What is Weekly Score?")
                    .font(AppStyleSheet.font(for: .body))
                    .foregroundColor(.white)
                
                Text("Your Weekly Score measures your productivity each week. It is based on completed tasks, goal progress, consistency, and quality. It resets every Monday so you can track each week as its own cycle.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if currentUser != nil {
                let calendar = Calendar.current
                let now = Date()
                let weekday = calendar.component(.weekday, from: now)
                let daysToSubtract = (weekday + 5) % 7
                let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
                let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
                let daysRemaining = calendar.dateComponents([.day], from: now, to: nextWeekStart).day ?? 0
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Resets in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                }
            }
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
        .frame(width: 320)
        .padding(.horizontal, 40)
    }

} // <-- Main closing brace for struct ProfileView

// MARK: - Theme Preview Card
// These structs are correctly outside of the main ProfileView
    struct ThemePreviewCard: View {
        let theme: Theme
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 8) {
                // Theme Preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeGradient)
                    .frame(width: 80, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        
        private var themeGradient: LinearGradient {
            switch theme.name.lowercased() {
            case "calm":
                return LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "mystical sci-fi":
                return LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "sunset":
                return LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            default:
                return LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    
// MARK: - Theme Shop View
    struct ThemeShopView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.dismiss) private var dismiss
        @Environment(ThemeManager.self) private var themeManager
        @Query private var themes: [Theme]
        @Query private var users: [User]
        
        private let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        private var currentUser: User? {
            LocalUserProvisioningService.resolveCurrentUser(from: users)
        }
        
        // Group themes by unlock method for proper ordering
        private var groupedThemes: [(title: String, themes: [Theme])] {
            var groups: [(String, [Theme])] = []
            
            // Default themes first
            let defaultThemes = themes.filter { $0.unlockMethod == .defaultTheme }
            if !defaultThemes.isEmpty {
                groups.append(("Default Themes", defaultThemes))
            }
            
            // Level-based themes (sorted by unlock level)
            let levelThemes = themes
                .filter { $0.unlockMethod == .level }
                .sorted { ($0.unlockLevel ?? 0) < ($1.unlockLevel ?? 0) }
            if !levelThemes.isEmpty {
                groups.append(("Level Unlocks", levelThemes))
            }
            
            // Crystal-purchased themes (sorted by price)
            let crystalThemes = themes
                .filter { $0.unlockMethod == .currency }
                .sorted { $0.currencyPrice < $1.currencyPrice }
            if !crystalThemes.isEmpty {
                groups.append(("Crystal Purchase", crystalThemes))
            }
            
            // Mood-based themes
            let moodThemes = themes.filter { $0.unlockMethod == .mood }
            if !moodThemes.isEmpty {
                groups.append(("Mood Unlocks", moodThemes))
            }
            
            // Achievement-based themes
            let achievementThemes = themes.filter { $0.unlockMethod == .achievement }
            if !achievementThemes.isEmpty {
                groups.append(("Achievement Unlocks", achievementThemes))
            }
            
            // IAP themes
            let iapThemes = themes.filter { $0.unlockMethod == .iap }
            if !iapThemes.isEmpty {
                groups.append(("In-App Purchase", iapThemes))
            }
            
            return groups
        }
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(groupedThemes, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(group.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(group.themes) { theme in
                                        ThemeShopCard(theme: theme)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical)
                }
                .background(
                    themeManager.currentTheme.primaryGradient
                        .ignoresSafeArea()
                )
                .navigationTitle("Theme Shop")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
// MARK: - Theme Shop Card
    struct ThemeShopCard: View {
        let theme: Theme
        @Environment(\.modelContext) private var modelContext
        @Environment(ThemeManager.self) private var themeManager
        @Query private var users: [User]
        
        private var currentUser: User? {
            LocalUserProvisioningService.resolveCurrentUser(from: users)
        }
        
        private var isOwned: Bool {
            currentUser?.ownedThemeIDs.contains(theme.id) ?? false
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Theme Preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeGradient)
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            if isOwned {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(theme.themeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !isOwned {
                        HStack {
                            unlockRequirementView(theme: theme)
                            Spacer()
                        }
                    }
                }
                
                // Always show button for testing
                Button(action: {
                    if isOwned {
                        selectTheme()
                    } else {
                        purchaseTheme()
                    }
                }) {
                        Text(buttonText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                .fill(isOwned ? .green : buttonColor)
                            )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        
        private var themeGradient: LinearGradient {
            switch theme.name.lowercased() {
            case "purple":
                return LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.6), .pink.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "light":
                return LinearGradient(colors: [.white, Color(red: 0.98, green: 0.98, blue: 0.98), Color(red: 0.95, green: 0.95, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "dark":
                return LinearGradient(colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.15, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "calm":
                return LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "energetic":
                return LinearGradient(colors: [.orange.opacity(0.8), .yellow.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "sunset":
                return LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "vintage":
                return LinearGradient(colors: [Color.brown.opacity(0.8), Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "neon":
                return LinearGradient(colors: [.cyan.opacity(0.8), .pink.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            default:
                return LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        
        @ViewBuilder
        private func unlockRequirementView(theme: Theme) -> some View {
            switch theme.unlockMethod {
            case .currency:
                HStack(spacing: 4) {
                    Crystal3DView()
                        .frame(width: 16, height: 16)
                    Text("\(theme.currencyPrice) crystals")
                        .fontWeight(.medium)
                }
            case .iap:
                Text("$2.99")
                    .fontWeight(.medium)
            case .level:
                if let unlockLevel = theme.unlockLevel {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                        Text("Level \(unlockLevel)")
                            .fontWeight(.medium)
                    }
                } else {
                    Text(theme.unlockRequirement)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .mood:
                HStack(spacing: 4) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.purple)
                    Text("Mood Unlock")
                        .fontWeight(.medium)
                }
            case .achievement:
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text("Achievement")
                        .fontWeight(.medium)
                }
            case .defaultTheme:
                Text("Default")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        private var buttonText: String {
            // FOR TESTING: All themes are selectable
            if isOwned {
                return "Select"
            }
            switch theme.unlockMethod {
            case .currency:
                return "Unlock (Test)"
            case .iap:
                return "Unlock (Test)"
            case .level:
                return "Unlock (Test)"
            case .mood:
                return "Unlock (Test)"
            case .achievement:
                return "Unlock (Test)"
            case .defaultTheme:
                return "Select"
            }
        }
        
        private var canUnlockLevel: Bool {
            guard let user = currentUser,
                  let unlockLevel = theme.unlockLevel else {
                return false
            }
            return user.level >= unlockLevel && !isOwned
        }
        
        private var canUnlockMood: Bool {
            guard let user = currentUser,
                  let moodReq = theme.moodRequirement else {
                return false
            }
            return MoodJarService.checkMoodRequirement(moodReq, user: user) && !isOwned
        }
        
        private var canUnlockAchievement: Bool {
            // TODO: Implement achievement checking
            return false
        }
        
        private var buttonColor: Color {
            switch theme.unlockMethod {
            case .currency:
                return .yellow
            case .iap:
                return .blue
            case .level:
                return .green
            case .mood:
                return .purple
            case .achievement:
                return .orange
            case .defaultTheme:
                return .gray
            }
        }
        
        private func purchaseTheme() {
            guard let user = currentUser else { return }
            
            // FOR TESTING: Always unlock themes regardless of requirements
            var shouldUnlock = true
            
            // Still deduct currency if it's a currency unlock (for testing purposes)
            if theme.unlockMethod == .currency && user.gamificationCurrency >= theme.currencyPrice {
                user.gamificationCurrency -= theme.currencyPrice
            }
            
            // Original logic commented out for testing:
            /*
            switch theme.unlockMethod {
            case .currency:
                if user.gamificationCurrency >= theme.currencyPrice {
                    user.gamificationCurrency -= theme.currencyPrice
                    shouldUnlock = true
                } else {
                    // Show insufficient crystals message
                    let needed = theme.currencyPrice - user.gamificationCurrency
                    // TODO: Show alert/notification for insufficient crystals
                    print("Insufficient Time Crystals. Need \(needed) more.")
                    return
                }
            case .iap:
                // Handle in-app purchase
                // TODO: Integrate StoreKit
                break
            case .level:
                // Check if user level meets requirement
                if let unlockLevel = theme.unlockLevel {
                    if user.level >= unlockLevel {
                        shouldUnlock = true
                    } else {
                        // Show level requirement message
                        return
                    }
                } else {
                    // No unlock level specified - check unlock requirement text
                    shouldUnlock = true
                }
            case .mood:
                // Check mood requirements
                if let moodReq = theme.moodRequirement,
                   MoodJarService.checkMoodRequirement(moodReq, user: user) {
                    shouldUnlock = true
                } else {
                    // Show mood requirement message
                    return
                }
            case .achievement:
                // Handle achievement-based unlock
                // TODO: Implement achievement checking
                shouldUnlock = canUnlockAchievement
            case .defaultTheme:
                // Default themes are always available
                shouldUnlock = true
            }
            */
            
            if shouldUnlock {
                if !user.ownedThemeIDs.contains(theme.id) {
                    user.ownedThemeIDs.append(theme.id)
                }
                
                // Activate the theme immediately
                themeManager.setTheme(to: theme.id)
                user.activeThemeID = theme.id
                
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving theme unlock: \(error)")
                }
            }
    }
    
    private func selectTheme() {
        guard let user = currentUser, isOwned else { return }
        
        // Activate the theme
        themeManager.setTheme(to: theme.id)
        user.activeThemeID = theme.id
        
        do {
            try modelContext.save()
        } catch {
            print("Error selecting theme: \(error)")
            }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self, Theme.self], inMemory: true)
}
