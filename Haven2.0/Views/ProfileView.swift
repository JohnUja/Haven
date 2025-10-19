//
//  ProfileView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var themes: [Theme]
    @State private var showingThemeShop = false
    
    private var currentUser: User? {
        users.first
    }
    
    private var ownedThemes: [Theme] {
        themes.filter { theme in
            currentUser?.ownedThemeIDs.contains(theme.id) ?? false
        }
    }
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Profile")
            .sheet(isPresented: $showingThemeShop) {
                ThemeShopView()
            }
        }
    }
    
    private func profileHeaderSection(user: User) -> some View {
        Section {
            VStack(spacing: 16) {
                // Avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                // User Info
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Level \(user.level)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // XP Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(user.currentXP)/\(user.nextLevelXP) XP")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(user.currentXP), total: Double(user.nextLevelXP))
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                }
                
                // Currency
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    
                    Text("\(user.gamificationCurrency) Time Crystals")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.yellow.opacity(0.2))
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
    
    private var settingsSections: some View {
        Group {
            Section("Notifications") {
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notification Settings", systemImage: "bell")
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(themes) { theme in
                        ThemeShopCard(theme: theme)
                    }
                }
                .padding()
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
                        if theme.unlockMethod == .currency {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                Text("\(theme.currencyPrice)")
                                    .fontWeight(.medium)
                            }
                        } else if theme.unlockMethod == .iap {
                            Text("$2.99")
                                .fontWeight(.medium)
                        } else {
                            Text(theme.unlockRequirement)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
    
    private var buttonText: String {
        switch theme.unlockMethod {
        case .currency:
            return "Buy with Crystals"
        case .iap:
            return "Purchase"
        case .progress:
            return "Unlock"
        }
    }
    
    private var buttonColor: Color {
        switch theme.unlockMethod {
        case .currency:
            return .yellow
        case .iap:
            return .blue
        case .progress:
            return .green
        }
    }
    
    private func purchaseTheme() {
        guard let user = currentUser else { return }
        
        switch theme.unlockMethod {
        case .currency:
            if user.gamificationCurrency >= theme.currencyPrice {
                user.gamificationCurrency -= theme.currencyPrice
                user.ownedThemeIDs.append(theme.id)
            }
        case .iap:
            // Handle in-app purchase
            break
        case .progress:
            // Handle progress-based unlock
            user.ownedThemeIDs.append(theme.id)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving theme purchase: \(error)")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self, Theme.self], inMemory: true)
}
