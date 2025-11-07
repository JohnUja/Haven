//
//  TimelineTimeIndicatorView.swift
//  TimeFlow
//
//  Created by AI on 2025-01-13.
//

import SwiftUI

struct TimelineTimeIndicatorView: View {
    let position: CGPoint
    let currentTime: Date
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        // White circle indicator with integrated green pulsing ring
        ZStack {
            // Green pulsing ring as part of the white indicator (outer ring)
            Circle()
                .stroke(Color.green.opacity(0.8), lineWidth: 1.5)
                .frame(width: 16, height: 16)
                .scaleEffect(pulseScale)
            
            // White circle indicator (center)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
        }
        .position(x: position.x, y: position.y)
        .onAppear {
            // Pulse animation every second
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        TimelineTimeIndicatorView(
            position: CGPoint(x: 30, y: 200),
            currentTime: Date()
        )
        .environmentObject(TimeSettingsManager())
    }
}

