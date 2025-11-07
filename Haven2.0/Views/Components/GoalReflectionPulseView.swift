//
//  GoalReflectionPulseView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct GoalReflectionPulseView: View {
    @State private var waveOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showIgnoreButton = true
    
    var body: some View {
        ZStack {
            // Wave pulse animation from left to right
            GeometryReader { geometry in
                ZStack {
                    // Animated wave that moves left to right
                    WaveShape(offset: waveOffset)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(showIgnoreButton ? 1.0 : 0.0)
                    
                    // Pulse glow effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.2 * pulseScale),
                                    Color.white.opacity(0.0)
                                ],
                                center: .trailing,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(showIgnoreButton ? 1.0 : 0.0)
                }
            }
            .frame(width: 80, height: 100)
            .onAppear {
                // Animate wave continuously
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    waveOffset = 60
                }
                
                // Pulse glow
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            }
            
            // Ignore button - small X button
            if showIgnoreButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showIgnoreButton = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                )
                        }
                        .padding(4)
                    }
                    Spacer()
                }
            }
            
            // "Add Reflection" text overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Add Reflection")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.6))
                        )
                        .padding(.trailing, 8)
                        .padding(.bottom, 4)
                }
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create wave pattern moving left to right
        let waveWidth: CGFloat = 30
        let waveHeight: CGFloat = 8
        let centerY = rect.midY
        
        // Start from left edge
        path.move(to: CGPoint(x: 0, y: centerY))
        
        // Create continuous wave pattern
        let steps = Int(rect.width / waveWidth) + 2
        
        for i in 0..<steps {
            let x1 = CGFloat(i) * waveWidth + offset
            let x2 = CGFloat(i + 1) * waveWidth + offset
            
            if x1 < rect.width {
                let midX = (x1 + x2) / 2
                let clampedX2 = min(x2, rect.width)
                
                // Wave crest
                path.addQuadCurve(
                    to: CGPoint(x: midX, y: centerY - waveHeight),
                    control: CGPoint(x: x1 + waveWidth / 4, y: centerY)
                )
                // Wave trough
                if clampedX2 <= rect.width {
                    path.addQuadCurve(
                        to: CGPoint(x: clampedX2, y: centerY),
                        control: CGPoint(x: x1 + waveWidth * 3 / 4, y: centerY)
                    )
                }
            }
        }
        
        // Close path to create fillable shape
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
        GoalReflectionPulseView()
            .frame(width: 100, height: 100)
    }
}

