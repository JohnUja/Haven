//
//  CosmicPortalView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-19.
//

import SwiftUI

struct CosmicPortalView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.pink, .cyan, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(animationOffset))
                .opacity(0.8)
            
            // Inner ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-animationOffset * 0.7))
                .opacity(0.6)
            
            // Central energy core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), .pink.opacity(0.7), .cyan.opacity(0.5), .clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 2)
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                animationOffset = 360
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CosmicPortalView()
        .background(Color.black)
}
