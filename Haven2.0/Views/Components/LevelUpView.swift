//
//  LevelUpView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import AudioToolbox

struct LevelUpView: View {
    let levelUpResult: LevelUpResult
    @Binding var isPresented: Bool
    @State private var isAnimating = false
    @State private var showUnlocks = false
    @State private var confettiScale: CGFloat = 0.0
    @State private var hasAppeared = false // Prevent multiple triggers
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Mascot/Character celebrating (placeholder - ready for asset integration)
                VStack(spacing: 16) {
                    // Placeholder for mascot asset - replace with actual asset when available
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.3), .orange.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                        
                        // Placeholder icon - replace with mascot asset
                        Image(systemName: "sparkles")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.3)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    }
                    .padding(.bottom, 20)
                    
                    // Level Number Display
                    VStack(spacing: 8) {
                        Text("LEVEL UP!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.0)
                        
                        Text("\(levelUpResult.newLevel)")
                            .font(.system(size: 100, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.8), radius: 20)
                            .scaleEffect(isAnimating ? 1.0 : 0.3)
                            .rotationEffect(.degrees(isAnimating ? 0 : -180))
                    }
                }
                
                // Feedback Section - Short, relevant information
                VStack(spacing: 12) {
                    // Level Progression Feedback
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                        Text("Level \(levelUpResult.newLevel) reached!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.green.opacity(0.2))
                    )
                    .opacity(showUnlocks ? 1.0 : 0.0)
                    .offset(x: showUnlocks ? 0 : -50)
                    
                    // Unlocks Section
                    if !levelUpResult.unlockedThemes.isEmpty || !levelUpResult.unlockedFeatures.isEmpty {
                        VStack(spacing: 8) {
                            Text("Unlocked:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(showUnlocks ? 1.0 : 0.0)
                            
                            if !levelUpResult.unlockedThemes.isEmpty {
                                ForEach(levelUpResult.unlockedThemes, id: \.self) { themeID in
                                    HStack(spacing: 8) {
                                        Image(systemName: "paintbrush.fill")
                                            .foregroundColor(.purple)
                                        Text("\(themeID.capitalized) Theme")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.purple.opacity(0.3))
                                    )
                                    .opacity(showUnlocks ? 1.0 : 0.0)
                                    .offset(x: showUnlocks ? 0 : -50)
                                }
                            }
                            
                            if !levelUpResult.unlockedFeatures.isEmpty {
                                ForEach(levelUpResult.unlockedFeatures, id: \.self) { feature in
                                    HStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("\(feature) Feature")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.yellow.opacity(0.3))
                                    )
                                    .opacity(showUnlocks ? 1.0 : 0.0)
                                    .offset(x: showUnlocks ? 0 : -50)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .padding(.bottom, 50)
            }
            .padding()
            
            // Confetti effect
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(confettiColors[i % confettiColors.count])
                    .frame(width: 8, height: 8)
                    .offset(
                        x: confettiOffset(for: i).x,
                        y: confettiOffset(for: i).y
                    )
                    .opacity(confettiScale > 0 ? 1.0 : 0.0)
                    .scaleEffect(confettiScale)
            }
        }
        .onAppear {
            // Only trigger animations once
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Sequence animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            // Confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    confettiScale = 1.0
                }
            }
            
            // Show unlocks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showUnlocks = true
                }
            }
            
            // Haptic feedback
            AudioServicesPlaySystemSound(1520) // Haptic vibration
            AudioServicesPlaySystemSound(1057) // Success sound
        }
    }
    
    private var confettiColors: [Color] {
        [.yellow, .orange, .pink, .purple, .blue, .green]
    }
    
    private func confettiOffset(for index: Int) -> (x: CGFloat, y: CGFloat) {
        let angle = Double(index) * (2 * .pi / 20)
        let radius: CGFloat = 200
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        return (x, y)
    }
}

#Preview {
    LevelUpView(
        levelUpResult: LevelUpResult(
            newLevel: 5,
            unlockedThemes: ["energetic"],
            unlockedFeatures: ["Goals"]
        ),
        isPresented: .constant(true)
    )
}

