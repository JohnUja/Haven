//
//  SettingsView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Separated from ProfileView - Settings page with glass-style cards
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var themes: [Theme]
    @State private var showingThemeShop = false
    @State private var showingEditProfile = false
    @State private var showingSignOutConfirmation = false
    
    private var currentUser: User? {
        LocalUserProvisioningService.resolveCurrentUser(from: users)
    }
    
    // Cached owned themes to avoid recomputation on every render
    @State private var cachedOwnedThemes: [Theme] = []
    
    private var ownedThemes: [Theme] {
        // Use cached version if available, otherwise compute
        if !cachedOwnedThemes.isEmpty {
            return cachedOwnedThemes
        }
        let computed = themes.filter { theme in
            currentUser?.ownedThemeIDs.contains(theme.id) ?? false
        }
        cachedOwnedThemes = computed
        return computed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching home screen style
                themeManager.currentTheme.primaryGradient
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: themeManager.currentTheme.sectionSpacing) {
                        // Appearance Section
                        appearanceSection
                            .id("appearance")
                        
                        // Mood Jars Section
                        moodJarsSection
                            .id("moodJars")
                        
                        // Routines Section
                        routinesSection
                            .id("routines")
                        
                        // Time & Date Section
                        timeDateSection
                            .id("timeDate")
                        
                        // Notifications Section
                        notificationsSection
                            .id("notifications")
                        
                        // Account Section (Detailed Settings)
                        accountSection
                            .id("account")
                        
                        // Developer Mode Section
                        if DeveloperModeService.shared.isDeveloperMode {
                            developerModeSection
                                .id("developerMode")
                        }
                        
                        // Data & Privacy Section
                        dataPrivacySection
                            .id("dataPrivacy")
                        
                        // About Section
                        aboutSection
                            .id("about")
                        
                        // Sign Out Section
                        signOutSection
                            .padding(.horizontal, themeManager.currentTheme.cardPadding)
                            .padding(.top, themeManager.currentTheme.itemSpacing / 2)
                            .id("signOut")
                    }
                    .drawingGroup() // Performance optimization
                    .padding(.vertical, themeManager.currentTheme.cardPadding)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Cache owned themes on appear
                cachedOwnedThemes = themes.filter { theme in
                    currentUser?.ownedThemeIDs.contains(theme.id) ?? false
                }
            }
            .onChange(of: themes.count) { _, _ in
                // Update cache when themes change
                cachedOwnedThemes = themes.filter { theme in
                    currentUser?.ownedThemeIDs.contains(theme.id) ?? false
                }
            }
            .onChange(of: currentUser?.ownedThemeIDs) { _, _ in
                // Update cache when user's owned themes change
                cachedOwnedThemes = themes.filter { theme in
                    currentUser?.ownedThemeIDs.contains(theme.id) ?? false
                }
            }
            .sheet(isPresented: $showingThemeShop) {
                ThemeShopView()
                    .environment(themeManager)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showingEditProfile) {
                NavigationStack {
                    ProfileEditView()
                }
                .environment(themeManager)
                .environment(authService)
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
        }
    }
    
    // MARK: - Theme Option Button
    private func themeOptionButton(themeId: String, themeName: String, isSelected: Bool) -> some View {
        Button(action: {
            themeManager.setTheme(to: themeId)
        }) {
            VStack(spacing: 8) {
                // Theme Preview - match ThemePreviewCard style
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeGradient(for: themeId))
                    .frame(width: 80, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
                    )
                
                Text(themeName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 80)
            // No background fill - just the page background like other theme containers
        }
    }
    
    // Cache theme gradients to avoid expensive lookups
    @State private var themeGradientCache: [String: LinearGradient] = [:]
    
    // Get theme gradient from ThemeManager - each theme has its own primaryGradient
    private func themeGradient(for themeId: String) -> LinearGradient {
        // Check cache first
        if let cached = themeGradientCache[themeId] {
            return cached
        }
        
        // Get the theme from ThemeManager's available themes
        let gradient: LinearGradient
        if let theme = themeManager.getAllThemes().first(where: { $0.id == themeId }) {
            gradient = theme.primaryGradient
        } else {
            // Fallback
            gradient = LinearGradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        // Cache it
        themeGradientCache[themeId] = gradient
        return gradient
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
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        let theme = themeManager.currentTheme
        return VStack(alignment: .leading, spacing: theme.itemSpacing) {
            sectionTitle("Appearance")
            
            VStack(alignment: .leading, spacing: 16) {
                // Default Themes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Themes")
                        .appTextStyle(.body, theme: themeManager.currentTheme)
                    
                    HStack(spacing: 12) {
                        // Black Theme
                        themeOptionButton(
                            themeId: "dark",
                            themeName: "Black",
                            isSelected: themeManager.currentTheme.id == "dark"
                        )
                        
                        // White Theme
                        themeOptionButton(
                            themeId: "light",
                            themeName: "White",
                            isSelected: themeManager.currentTheme.id == "light"
                        )
                        
                        // Purple Theme
                        themeOptionButton(
                            themeId: "purple",
                            themeName: "Purple",
                            isSelected: themeManager.currentTheme.id == "purple"
                        )
                    }
                }
                
                // Theme Shop Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme Shop")
                        .appTextStyle(.body, theme: themeManager.currentTheme)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(ownedThemes, id: \.id) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: theme.id == currentUser?.activeThemeID
                            )
                            .id(theme.id)
                        }
                    }
                    .padding(.horizontal, 0)
                }
                
                Button(action: { showingThemeShop = true }) {
                    HStack {
                        Image(systemName: "storefront")
                        Text("Browse Theme Shop")
                    }
                    .appTextStyle(.settingsText, theme: themeManager.currentTheme)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        themeManager.currentTheme.primaryGradient
                    )
                    .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                    }
                }
            }
            .padding(.horizontal, themeManager.currentTheme.cardPadding)
            .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
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
    
    // MARK: - Mood Jars Section
    private var moodJarsSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Mood Tracker")
            
            if currentUser != nil {
            settingsCard(
                    title: "Mood Jars",
                    icon: "heart.fill",
                    color: .pink,
                    destination: AnyView(MoodJarView())
                )
                .padding(.horizontal, 20)
            } else {
                settingsCardDisabled(
                    title: "Mood Jars",
                    icon: "heart.fill",
                    subtitle: "Sign in required"
            )
            .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Routines Section
    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Routines")
            
            if let user = currentUser {
                settingsCard(
                    title: "Manage Routines",
                    icon: "repeat",
                    color: .blue,
                    destination: AnyView(RoutineManagerView(userID: user.id))
                )
                .padding(.horizontal, 20)
            } else {
                settingsCardDisabled(
                    title: "Manage Routines",
                    icon: "repeat",
                    subtitle: "Sign in required"
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Time & Date Section
    private var timeDateSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Time & Date")
            
            settingsCard(
                title: "Time Settings",
                icon: "clock",
                color: .cyan,
                destination: AnyView(TimeSettingsView())
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Notifications")
            
            settingsCard(
                title: "Notification Settings",
                icon: "bell",
                color: .pink,
                destination: AnyView(
                    VStack(spacing: 20) {
                        Text("Notification Settings")
                            .appTextStyle(.settingsText, theme: themeManager.currentTheme)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        themeManager.currentTheme.primaryGradient.opacity(0.3) // Theme-aware gradient
                    )
                )
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Account Section (Detailed Settings)
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Account")
            
            // Edit Profile
            settingsCard(
                title: "Edit Profile",
                icon: "person.circle",
                color: .indigo,
                destination: AnyView(ProfileEditView().environment(authService))
            )
            .padding(.horizontal, 20)
            
            // Account Security (Email & Password)
            if authService.currentUser?.email != nil {
                NavigationLink(destination: AccountSecurityView().environment(authService)) {
                    settingsCardButton(
                        title: "Account Security",
                        icon: "lock.shield",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
            }
            
            // Delete Account (navigate to ProfileEditView)
            NavigationLink(destination: ProfileEditView().environment(authService)) {
                settingsCardButton(
                    title: "Delete Account",
                    icon: "trash",
                    color: .red
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Settings Card Button Helper (Theme-Aware)
    private func settingsCardButton(title: String, icon: String, color: Color) -> some View {
        let theme = themeManager.currentTheme
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: theme.iconCircleSize, height: theme.iconCircleSize)
                
                Image(systemName: icon)
                    .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .appTextStyle(.settingsText, theme: theme)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
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
    
    // MARK: - Developer Mode Section
    private var developerModeSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Developer Mode")
            
            settingsCard(
                title: "Developer Tools",
                icon: "wrench.and.screwdriver",
                color: .gray,
                destination: AnyView(DeveloperModeView())
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Data & Privacy Section
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("Data & Privacy")
            
            settingsCard(
                title: "Privacy Settings",
                icon: "hand.raised.fill",
                color: .red,
                destination: AnyView(Text("Privacy Settings"))
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: themeManager.currentTheme.itemSpacing) {
            sectionTitle("About")
            
                    VStack(spacing: themeManager.currentTheme.itemSpacing) {
                settingsCard(
                    title: "App Version",
                    icon: "info.circle",
                    color: .blue,
                    destination: AnyView(Text("Version 1.0.0"))
                )
                
                // Onboarding Reset Button
                Button(action: {
                    OnboardingService.shared.resetOnboarding()
                }) {
                    settingsCardButton(
                        title: "Re-run Onboarding",
                        icon: "arrow.counterclockwise",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                settingsCard(
                    title: "Terms of Service",
                    icon: "doc.text",
                    color: .gray,
                    destination: AnyView(Text("Terms of Service"))
                )
                
                settingsCard(
                    title: "Privacy Policy",
                    icon: "lock.doc",
                    color: .gray,
                    destination: AnyView(Text("Privacy Policy"))
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Views
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .padding(.horizontal, 20)
    }

    private func settingsCard(title: String, icon: String, color: Color, destination: AnyView) -> some View {
        let theme = themeManager.currentTheme
        return NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.16))
                        .frame(width: theme.iconCircleSize, height: theme.iconCircleSize)
                    
                    Image(systemName: icon)
                        .font(themeManager.currentTheme.headerFont) // Use theme headerFont (11pt, semibold)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .appTextStyle(.settingsText, theme: theme)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(themeManager.currentTheme.titleFont) // Use theme titleFont (10pt, regular)
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsCardDisabled(title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.glassBackground)
                    .frame(width: themeManager.currentTheme.iconCircleSize, height: themeManager.currentTheme.iconCircleSize)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appTextStyle(.settingsText, theme: themeManager.currentTheme)
                
                Text(subtitle)
                        .font(AppStyleSheet.font(for: .caption))
                        .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                .fill(themeManager.currentTheme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                        .stroke(themeManager.currentTheme.glassBorder.opacity(0.5), lineWidth: themeManager.currentTheme.cardBorderWidth)
                )
        )
        .opacity(0.6)
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Button(action: {
            showingSignOutConfirmation = true
        }) {
            HStack {
                Spacer()
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .appTextStyle(.body, theme: themeManager.currentTheme)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                    .fill(themeManager.currentTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                            .stroke(Color.red.opacity(0.35), lineWidth: themeManager.currentTheme.cardBorderWidth)
                    )
            )
        }
    }
}

#Preview {
    SettingsView()
        .environment(FirebaseAuthService.shared)
        .modelContainer(for: [User.self, Theme.self], inMemory: true)
}

