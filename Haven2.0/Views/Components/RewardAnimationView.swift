//
//  RewardAnimationView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import AudioToolbox

struct RewardAnimationView: View {
    let crystals: Int
    let xp: Int
    @State private var isAnimating = false
    @State private var sparkleOffset: CGFloat = 0
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Reward card
            VStack(spacing: 16) {
                // Crystal icon
                Crystal3DView()
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatCount(3, autoreverses: false), value: isAnimating)
                
                // Title
                Text("Task Completed!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Rewards
                VStack(spacing: 12) {
                    // Crystals
                    HStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 20))
                        Text("+\(crystals) Time Crystals")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.yellow.opacity(0.3))
                    )
                    
                    // XP
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("+\(xp) XP")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.purple.opacity(0.3))
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPresented = false
                }
            }
            
            // Haptic feedback
            AudioServicesPlaySystemSound(1520)
        }
    }
}

#Preview {
    RewardAnimationView(crystals: 23, xp: 15, isPresented: .constant(true))
}

