//
//  MomentumPopupView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData

struct MomentumPopupView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    private var bonusPercentage: Int {
        Int((GamificationService.getMomentumBonus(user: user) - 1.0) * 100)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background matching home/timeline theme
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.pink.opacity(0.1),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Hero Section - Counter that POPS with better organization
                        VStack(spacing: 24) {
                            // Animated flame icon with stronger glow
                            ZStack {
                                // Multiple glow layers
                                ForEach(0..<2) { index in
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    Color.orange.opacity(0.5 - Double(index) * 0.2),
                                                    Color.red.opacity(0.3 - Double(index) * 0.15),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: CGFloat(20 + index * 15),
                                                endRadius: CGFloat(60 + index * 30)
                                            )
                                        )
                                        .frame(width: CGFloat(120 + index * 40), height: CGFloat(120 + index * 40))
                                        .blur(radius: CGFloat(10 + index * 5))
                                }
                                
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red, .yellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .frame(height: 120)
                            
                            // Counter that POPS - Large, bold, exclusive with distinct background
                            VStack(spacing: 12) {
                                ZStack {
                                    // Distinct background for counter to pop
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.black.opacity(0.4),
                                                    Color.black.opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.orange.opacity(0.6),
                                                            Color.red.opacity(0.5),
                                                            Color.yellow.opacity(0.4)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2.5
                                                )
                                        )
                                    
                                    VStack(spacing: 8) {
                                        Text("\(user.momentumDays)")
                                            .font(.system(size: 72, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.yellow, .orange, .red],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .orange.opacity(0.8), radius: 8)
                                            .shadow(color: .red.opacity(0.6), radius: 4)
                                        
                                        Text(user.momentumDays == 1 ? "Day Streak" : "Day Streak")
                                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 32)
                                }
                                
                                // Bonus badge - more prominent
                                if bonusPercentage > 0 {
                                    HStack(spacing: 10) {
                                        Crystal3DView()
                                            .frame(width: 20, height: 20)
                                        
                                        Text("+\(bonusPercentage)% Bonus Active")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            )
                                    )
                                    .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 20)
                        
                        // Enhanced Momentum Bar - Better visual
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Progress to Next Milestone")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            // Enhanced progress bar with glow
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 14)
                                    
                                    // Progress fill with gradient and glow
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(momentumBarGradient)
                                        .frame(width: geometry.size.width * momentumProgress, height: 14)
                                        .shadow(color: .orange.opacity(0.6), radius: 4, x: 0, y: 2)
                                        .shadow(color: .red.opacity(0.4), radius: 2, x: 0, y: 1)
                                }
                            }
                            .frame(height: 14)
                            
                            // Next milestone indicator
                            if let nextMilestone = nextMilestone {
                                HStack {
                                    Spacer()
                                    Text("Next: \(nextMilestone) days")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
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
                        .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        // How Momentum Works - Consistent font
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("How Momentum Works")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 14) {
                                InfoRow(icon: "checkmark.circle.fill", text: "Complete at least 1 task daily to maintain momentum", color: .green)
                                InfoRow(icon: "arrow.up.circle.fill", text: "Each day adds +1 to your streak", color: .blue)
                                InfoRow(icon: "xmark.circle.fill", text: "Missing a day reduces streak by 2-3 days (graceful)", color: .red)
                                InfoRow(icon: "sparkles", text: "Higher streaks = bigger rewards on all tasks", color: .purple)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .purple.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        // Bonus Rewards - Removed large circles, cleaner design
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "gift.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Bonus Rewards")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(momentumMilestones, id: \.days) { milestone in
                                    HStack(spacing: 12) {
                                        // Smaller, simpler checkmark
                                        Image(systemName: milestone.days <= user.momentumDays ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(milestone.days <= user.momentumDays ? .green : .gray.opacity(0.4))
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Text("\(milestone.days) days: +\(milestone.bonus)% bonus")
                                            .font(.system(size: 16, weight: milestone.days <= user.momentumDays ? .bold : .medium, design: .rounded))
                                            .foregroundColor(milestone.days <= user.momentumDays ? .primary : .secondary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .yellow.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Momentum")
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
    
    private var momentumProgress: CGFloat {
        let milestones: [Int] = [2, 4, 7, 14, 30]
        guard let nextMilestone = milestones.first(where: { $0 > user.momentumDays }) else {
            return 1.0
        }
        let previousMilestone = milestones.last(where: { $0 <= user.momentumDays }) ?? 0
        let progressInRange = Double(user.momentumDays - previousMilestone) / Double(nextMilestone - previousMilestone)
        return CGFloat(min(progressInRange, 1.0))
    }
    
    private var nextMilestone: Int? {
        let milestones: [Int] = [2, 4, 7, 14, 30]
        return milestones.first(where: { $0 > user.momentumDays })
    }
    
    private var momentumBarGradient: LinearGradient {
        let colors: [Color]
        switch user.momentumDays {
        case 0..<2:
            colors = [.gray, .gray.opacity(0.6)]
        case 2..<4:
            colors = [.orange, .orange.opacity(0.7)]
        case 4..<7:
            colors = [.orange, .red]
        case 7..<14:
            colors = [.red, .pink]
        case 14..<30:
            colors = [.pink, .purple]
        default:
            colors = [.purple, .blue]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    private var momentumMilestones: [(days: Int, bonus: Int)] {
        [
            (2, 10),
            (4, 20),
            (7, 30),
            (14, 40),
            (30, 50)
        ]
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    MomentumPopupView(user: User(
        email: "test@test.com",
        name: "Test User",
        momentumDays: 15
    ))
}

