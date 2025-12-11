//
//  IndividualMoodJar.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct IndividualMoodJar: View {
    let coreMood: CoreMood
    let count: Int
    let onCashIn: () -> Void
    @Environment(ThemeManager.self) private var themeManager
    
    private var isFull: Bool {
        count >= 15
    }
    
    private var fillPercentage: Double {
        Double(count) / 15.0
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(spacing: 12) {
            moodHeaderView(theme: theme)
            jarView(theme: theme)
            cashInButton(theme: theme)
        }
        .padding(12)
        .background(cardBackground(theme: theme))
    }
    
    // MARK: - Helper Views
    
    private func moodHeaderView(theme: any AppTheme) -> some View {
        HStack {
            Image(systemName: coreMood.icon)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(coreMood.color)
                .frame(width: 24, height: 24)
            Text(coreMood.displayName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            Spacer()
            Text("\(count)/15")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
    }
    
    private func jarView(theme: any AppTheme) -> some View {
        ZStack(alignment: .bottom) {
            jarBackground
            if count > 0 {
                marblesView
            } else {
                emptyJarView(theme: theme)
            }
        }
    }
    
    private var jarBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(jarGradient)
            .frame(height: 150)
            .overlay(jarStroke)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var jarGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.15),
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var jarStroke: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
    
    private var marblesView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(0..<min(count, 15), id: \.self) { index in
                    marbleView
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .frame(height: fillPercentage * 150)
            .transition(.move(edge: .bottom))
        }
    }
    
    private var marbleView: some View {
        Circle()
            .fill(marbleGradient)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    private var marbleGradient: RadialGradient {
        RadialGradient(
            colors: [
                coreMood.color.opacity(0.9),
                coreMood.color.opacity(0.7)
            ],
            center: .topLeading,
            startRadius: 5,
            endRadius: 12
        )
    }
    
    private func emptyJarView(theme: any AppTheme) -> some View {
        VStack {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundColor(theme.textSecondary.opacity(0.3))
            Text("Empty")
                .font(.caption)
                .foregroundColor(theme.textSecondary.opacity(0.5))
        }
    }
    
    private func cashInButton(theme: any AppTheme) -> some View {
        Button(action: onCashIn) {
            HStack {
                Image(systemName: isFull ? "sparkles" : "lock.fill")
                    .font(.caption)
                
                Text(isFull ? "Cash In (350)" : "\(15 - count) to go")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isFull ? theme.textPrimary : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(buttonBackground(theme: theme))
        }
        .disabled(!isFull)
    }
    
    @ViewBuilder
    private func buttonBackground(theme: any AppTheme) -> some View {
        if isFull {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: 1)
                )
        } else {
            Capsule()
                .fill(theme.glassBackground.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(theme.glassBorder, lineWidth: 1)
                )
        }
    }
    
    private func cardBackground(theme: any AppTheme) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(theme.glassBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
            )
    }
    
}

#Preview {
    VStack(spacing: 20) {
        IndividualMoodJar(coreMood: .happy, count: 15, onCashIn: {})
        IndividualMoodJar(coreMood: .calm, count: 8, onCashIn: {})
        IndividualMoodJar(coreMood: .sad, count: 0, onCashIn: {})
    }
    .padding()
    .background(Color.purple.opacity(0.2))
}

