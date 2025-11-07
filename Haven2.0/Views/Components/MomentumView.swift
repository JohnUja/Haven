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
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Momentum")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(momentumDays) days")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(momentumGradient)
                        .frame(width: geometry.size.width * momentumProgress, height: 6)
                }
            }
            .frame(height: 6)
            
            // Bonus indicator
            if bonusPercentage > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text("+\(bonusPercentage)% Bonus")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
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

struct CompactMomentumView: View {
    let momentumDays: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text("\(momentumDays)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.3))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MomentumView(momentumDays: 7, bonusPercentage: 30)
        MomentumView(momentumDays: 15, bonusPercentage: 40)
        CompactMomentumView(momentumDays: 7)
    }
    .padding()
    .background(Color.purple.opacity(0.3))
}

