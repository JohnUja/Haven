//
//  MomentumView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct MomentumView: View {
    let momentumDays: Int
    let bonusPercentage: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Momentum")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(momentumDays) days")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("What is Momentum?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Complete tasks daily to build your momentum streak. The longer your streak, the bigger your XP and Time Crystal bonuses! Keep it going to unlock maximum rewards.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to Next Milestone")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if let nextMilestone = getNextMilestone() {
                        Text("\(nextMilestone) days")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(momentumGradient)
                            .frame(width: geometry.size.width * momentumProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Bonus section
            if bonusPercentage > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Bonus")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("+\(bonusPercentage)% XP & Crystals")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Milestones info
            VStack(alignment: .leading, spacing: 6) {
                Text("Milestones")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                let milestones: [Int] = [2, 4, 7, 14, 30]
                ForEach(milestones, id: \.self) { milestone in
                    HStack {
                        Image(systemName: momentumDays >= milestone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(momentumDays >= milestone ? .green : .white.opacity(0.5))
                            .font(.system(size: 12))
                        
                        Text("\(milestone) days")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(momentumDays >= milestone ? .white : .white.opacity(0.7))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getNextMilestone() -> Int? {
        let milestones: [Int] = [2, 4, 7, 14, 30]
        return milestones.first(where: { $0 > momentumDays })
    }
    
    private var momentumProgress: CGFloat {
        let milestones: [Int] = [2, 4, 7, 14, 30]
        guard let nextMilestone = milestones.first(where: { $0 > momentumDays }) else {
            return 1.0 // At or beyond max milestone
        }
        
        let previousMilestone = milestones.last(where: { $0 <= momentumDays }) ?? 0
        let progressInRange = Double(momentumDays - previousMilestone) / Double(nextMilestone - previousMilestone)
        return CGFloat(min(progressInRange, 1.0))
    }
    
    private var momentumGradient: LinearGradient {
        let colors: [Color]
        
        switch momentumDays {
        case 0..<2:
            colors = [.gray, .gray.opacity(0.6)]
        case 2..<4:
            colors = [.orange, .orange.opacity(0.6)]
        case 4..<7:
            colors = [.orange, .red]
        case 7..<14:
            colors = [.red, .pink]
        case 14..<30:
            colors = [.pink, .purple]
        default:
            colors = [.purple, .blue]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Compact Momentum View
// Moved to Views/Components/CompactMomentumView.swift

#Preview {
    VStack(spacing: 20) {
        MomentumView(momentumDays: 7, bonusPercentage: 30)
        MomentumView(momentumDays: 15, bonusPercentage: 40)
        CompactMomentumView(momentumDays: 7)
    }
    .padding()
    .background(Color.purple.opacity(0.3) as Color)
}

