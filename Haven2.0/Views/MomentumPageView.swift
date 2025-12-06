//
//  MomentumPageView.swift
//  Haven2.0
//
//  Momentum info popup - matching XP/Time Crystals popup style
//

import SwiftUI
import SwiftData

struct MomentumPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    @Query private var goals: [Goal]
    
    private var currentUser: User? {
        users.first
    }
    
    private var momentumDays: Int {
        currentUser?.momentumDays ?? 0
    }
    
    private var bonusPercentage: Int {
        guard let user = currentUser else { return 0 }
        return Int((GamificationService.getMomentumBonus(user: user) - 1.0) * 100)
    }
    
    // Define milestones
    private var milestones: [(days: Int, xpReward: Int, crystalReward: Int)] {
        [
            (days: 2, xpReward: 50, crystalReward: 0),
            (days: 5, xpReward: 0, crystalReward: 100),
            (days: 7, xpReward: 50, crystalReward: 0),
            (days: 14, xpReward: 100, crystalReward: 200),
            (days: 30, xpReward: 200, crystalReward: 500)
        ]
    }
    
    var body: some View {
            ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                    .ignoresSafeArea()
                .onTapGesture {
                        dismiss()
                }
            
            // Popup card (same style as XP/Time Crystals)
            momentumInfoPopupView
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var momentumInfoPopupView: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Momentum")
                        .appTextStyle(.sectionHeader, theme: theme)
                    
                    if let user = currentUser {
                        Text("\(user.momentumDays) days")
                            .appTextStyle(.title, theme: theme)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What is Momentum?")
                    .appTextStyle(.body, theme: theme)
                
                Text("Build your momentum streak by completing at least one task every day. Your streak multiplies your XP and Time Crystal rewards!")
                    .font(AppStyleSheet.font(for: .caption))
                    .foregroundColor(theme.textPrimary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Bonus info
            if bonusPercentage > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Bonus: +\(bonusPercentage)%")
                        .appTextStyle(.body, theme: theme)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
            
            // Milestones preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Milestones:")
                    .appTextStyle(.body, theme: theme)
                    .padding(.top, 8)
                
                ForEach(milestones, id: \.days) { milestone in
                HStack {
                        Text("\(milestone.days) days")
                            .font(AppStyleSheet.font(for: .caption))
                            .foregroundColor(theme.textPrimary.opacity(0.7))
                        
                        Spacer()
                    
                    if momentumDays >= milestone.days {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(theme.textPrimary.opacity(0.3))
                                .font(.system(size: 16))
                        }
                    }
                }
            }
        }
        .padding(theme.cardPadding + 4)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
                .shadow(color: theme.cardShadow, radius: theme.shadowRadius, x: 0, y: 4)
        )
        .frame(width: 320)
    }
}
