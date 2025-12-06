//
//  MomentumRingView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Circular momentum ring display
//

import SwiftUI
import SwiftData

struct MomentumRingView: View {
    let user: User
    
    private var momentumProgress: Double {
        // Calculate progress to next milestone (7 days)
        let currentStreak = user.momentumDays
        let progress = Double(currentStreak % 7) / 7.0
        return progress
    }
    
    private var daysToNextMilestone: Int {
        let currentStreak = user.momentumDays
        return 7 - (currentStreak % 7)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: momentumProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: momentumProgress)
                
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("\(user.momentumDays)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Days")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Text("Next: \(daysToNextMilestone) Days")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

