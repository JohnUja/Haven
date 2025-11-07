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
    @EnvironmentObject private var authService: FirebaseAuthService
    @Query private var users: [User]
    @Query private var themes: [Theme]
    @State private var showingThemeShop = false
    @State private var showingMomentumPopup = false
    @State private var showingSignOutConfirmation = false
    @State private var showingEditProfile = false
    
    private var currentUser: User? {
        users.first
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
        NavigationView {
            ZStack {
                // Gradient background matching app theme
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
                
            List {
                // Profile Header
                if let user = currentUser {
                    profileHeaderSection(user: user)
                }
                
                // Appearance Section
                appearanceSection
                
                // Settings Sections
                settingsSections
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingThemeShop) {
                ThemeShopView()
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingEditProfile) {
                NavigationView {
                    ProfileEditView()
                        .environmentObject(authService)
                }
            }
        }
    }
    
    // MARK: - Sign Out Handler
    private func handleSignOut() {
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
    
    private func profileHeaderSection(user: User) -> some View {
        Section {
            VStack(spacing: 20) {
                // Avatar with user's photo from auth provider or custom avatar - Clickable to edit profile
                Button(action: {
                    showingEditProfile = true
                }) {
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
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PlainButtonStyle())
                
                // User Info - Show Firebase Auth details if available
                VStack(spacing: 6) {
                    Text(firebaseUserDisplayName ?? user.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let email = firebaseUserEmail {
                        Text(email)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Level \(user.level)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // XP Progress with better styling
                xpProgressView(user: user)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                
                // Currency with golden crystal icon
                HStack(spacing: 10) {
                    Crystal3DView()
                        .frame(width: 24, height: 24)
                    
                    Text("\(user.gamificationCurrency) Time Crystals")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.25),
                                    Color.orange.opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: .yellow.opacity(0.2), radius: 5, x: 0, y: 2)
                
                // Momentum - Compact container view (not full page)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "flame.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 20))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(user.momentumDays) days")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("+\(Int((GamificationService.getMomentumBonus(user: user) - 1.0) * 100))% Bonus")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: .orange.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                
                // Weekly Productivity Score
                weeklyScoreView(user: user)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                )
            }
            .padding()
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Theme")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ownedThemes) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: theme.id == currentUser?.activeThemeID
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: { showingThemeShop = true }) {
                    HStack {
                        Image(systemName: "storefront")
                        Text("Browse Theme Shop")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func xpProgressView(user: User) -> some View {
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
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(xpInCurrentLevel)/\(xpNeeded) XP")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
                        .shadow(color: .purple.opacity(0.5), radius: 4, x: 0, y: 2)
                        .shadow(color: .pink.opacity(0.3), radius: 2, x: 0, y: 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 12)
        }
    }
    
    private func weeklyScoreView(user: User) -> some View {
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(user.weeklyProductivityScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
                        .shadow(color: .purple.opacity(0.4), radius: 3, x: 0, y: 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
                }
            }
            .frame(height: 8)
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("Resets in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var settingsSections: some View {
        Group {
                Section("Gamification") {
                    // Momentum/Progression Screen
                    if let user = currentUser {
                        NavigationLink(destination: MomentumPopupView(user: user)) {
                            Label("Momentum & Progression", systemImage: "flame.fill")
                        }
                    }
                    
                    NavigationLink(destination: MoodJarView()) {
                        Label("Mood Jar", systemImage: "face.smiling")
                    }
                    
                    NavigationLink(destination: LeaderboardView()) {
                        Label("Leaderboard", systemImage: "trophy.fill")
                    }
                }
                
            Section("Time & Date") {
                NavigationLink(destination: TimeSettingsView()) {
                    Label("Time Settings", systemImage: "clock")
                }
            }
            
            Section("Notifications") {
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notification Settings", systemImage: "bell")
                }
            }
            
            Section("Account") {
                NavigationLink(destination: ProfileEditView().environmentObject(authService)) {
                    Label("Edit Profile", systemImage: "person.circle")
                }
            }
            
            // Developer Mode Section (only visible for developer/test accounts)
            if DeveloperModeService.shared.isDeveloperMode {
                Section("Developer Mode") {
                    NavigationLink(destination: DeveloperModeView().environmentObject(DeveloperModeService.shared)) {
                        Label("Developer Settings", systemImage: "wrench.and.screwdriver")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Section("Data & Privacy") {
                NavigationLink(destination: Text("Data & Privacy")) {
                    Label("Data & Privacy", systemImage: "hand.raised")
                }
                
                NavigationLink(destination: Text("Export Data")) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
            
            Section("About") {
                NavigationLink(destination: Text("About TimeFlow")) {
                    Label("About TimeFlow", systemImage: "info.circle")
                }
                
                NavigationLink(destination: Text("Help & Support")) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
            }
            
            // Sign Out at bottom
            Section {
                Button(action: {
                    showingSignOutConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                }
            }
        }
    }
}

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

struct ThemeShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var themes: [Theme]
    @Query private var users: [User]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var currentUser: User? {
        users.first
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
        NavigationView {
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
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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

struct ThemeShopCard: View {
    let theme: Theme
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
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
            
            if !isOwned {
                Button(action: purchaseTheme) {
                    Text(buttonText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(buttonColor)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
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
        switch theme.unlockMethod {
        case .currency:
            return "Buy with Crystals"
        case .iap:
            return "Purchase"
        case .level:
            return canUnlockLevel ? "Claim" : "Locked"
        case .mood:
            return canUnlockMood ? "Claim" : "Locked"
        case .achievement:
            return canUnlockAchievement ? "Claim" : "Locked"
        case .defaultTheme:
            return "Active"
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
        guard let user = currentUser, !isOwned else { return }
        
        var shouldUnlock = false
        
        switch theme.unlockMethod {
        case .currency:
            if user.gamificationCurrency >= theme.currencyPrice {
                user.gamificationCurrency -= theme.currencyPrice
                shouldUnlock = true
            } else {
                // Show insufficient crystals message
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
        
        if shouldUnlock {
            if !user.ownedThemeIDs.contains(theme.id) {
            user.ownedThemeIDs.append(theme.id)
        }
        
        do {
            try modelContext.save()
        } catch {
                print("Error saving theme unlock: \(error)")
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self, Theme.self], inMemory: true)
}
