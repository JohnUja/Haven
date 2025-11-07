//
//  Diamond.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.midX
        let centerY = rect.midY
        let width = rect.width
        let height = rect.height
        
        // Diamond shape (rotated square)
        path.move(to: CGPoint(x: centerX, y: centerY - height/2))        // Top
        path.addLine(to: CGPoint(x: centerX + width/2, y: centerY))      // Right
        path.addLine(to: CGPoint(x: centerX, y: centerY + height/2))     // Bottom
        path.addLine(to: CGPoint(x: centerX - width/2, y: centerY))     // Left
        path.closeSubpath()
        
        return path
    }
}

// Enhanced 3D Crystal View - Literal Glowing Yellow/Gold Diamond
struct Crystal3DView: View {
    @State private var rotation: Double = 0
    @State private var glowIntensity: Double = 0.8
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            glowLayers
            mainCrystalBody
            sparkleOverlay
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Glow Layers
    private var glowLayers: some View {
        ForEach(0..<3) { index in
            glowLayer(for: index)
        }
    }
    
    private func glowLayer(for index: Int) -> some View {
        let yellowOpacity = 0.9 - Double(index) * 0.2
        let orangeOpacity = 0.7 - Double(index) * 0.15
        let goldOpacity = 0.5 - Double(index) * 0.1
        let frameSize = CGFloat(18 + index * 4)
        let blurRadius = CGFloat(3.0 + Double(index) * 1.5)
        let startRadius = CGFloat(2 + index * 2)
        let endRadius = CGFloat(12 + index * 4)
        
        return Diamond()
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(yellowOpacity),
                        Color.orange.opacity(orangeOpacity),
                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(goldOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: startRadius,
                    endRadius: endRadius
                )
            )
            .frame(width: frameSize, height: frameSize)
            .blur(radius: blurRadius)
            .opacity(glowIntensity)
            .scaleEffect(pulseScale)
    }
    
    // MARK: - Main Crystal Body
    private var mainCrystalBody: some View {
        Diamond()
            .fill(mainGradient)
            .frame(width: 16, height: 16)
            .overlay(topFaceHighlight)
            .overlay(edgeOutline)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .yellow.opacity(0.9), radius: 6, x: 0, y: 3)
            .shadow(color: .orange.opacity(0.7), radius: 4, x: 0, y: 2)
            .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    private var mainGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.yellow.opacity(1.0),
                Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
                Color.orange.opacity(0.98),
                Color(red: 1.0, green: 0.65, blue: 0.0) // Darker orange
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var topFaceHighlight: some View {
        Diamond()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        Color.yellow.opacity(0.5),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            )
            .frame(width: 16, height: 16)
    }
    
    private var edgeOutline: some View {
        Diamond()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(1.0),
                        Color.yellow.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .frame(width: 16, height: 16)
    }
    
    // MARK: - Sparkle Overlay
    private var sparkleOverlay: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 7))
            .foregroundColor(.white.opacity(1.0))
            .offset(x: 3, y: -3)
            .scaleEffect(glowIntensity)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Animate glow with stronger pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
            pulseScale = 1.15
        }
        
        // Subtle rotation
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

#Preview {
    Diamond()
        .fill(
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 50, height: 50)
        .shadow(color: .yellow.opacity(0.5), radius: 5)
}

