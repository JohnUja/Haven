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
        // Green dot that pulses (single element, not white dot + separate ring)
        ZStack {
            // Green pulsing circle (the dot itself pulses)
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .scaleEffect(pulseScale)
                .opacity(0.8 + (pulseScale - 1.0) * 0.2) // Slight opacity change with pulse
        }
        .position(x: position.x, y: position.y)
        .onAppear {
            // Pulse animation every second
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
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

