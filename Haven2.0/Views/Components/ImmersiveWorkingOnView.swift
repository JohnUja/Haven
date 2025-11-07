//
//  ImmersiveWorkingOnView.swift
//  TimeFlow
//
//  Created by AI on 2025-01-13.
//

import SwiftUI
import SwiftData
import AVKit

struct ImmersiveWorkingOnView: View {
    let task: Task
    let onDismiss: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var mascotState: MascotState = .active
    @State private var startTime: Date = Date()
    
    enum MascotState {
        case sleeping
        case active
        case exploring
        case neutral
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on mascot state
            mascotBackgroundView
            
            VStack(spacing: 30) {
                // Top bar with dismiss button
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Task info and timer
                VStack(spacing: 20) {
                    Text(task.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Running timer
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.3), radius: 10)
                }
                .padding(.bottom, 100)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTimer()
            updateMascotState()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    @ViewBuilder
    private var mascotBackgroundView: some View {
        // For now, use gradient backgrounds that match mascot states
        // Later, replace with video assets
        ZStack {
            switch mascotState {
            case .sleeping:
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.4),
                        Color.indigo.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .active:
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.6),
                        Color.pink.opacity(0.4),
                        Color.red.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .exploring:
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.6),
                        Color.mint.opacity(0.4),
                        Color.teal.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .neutral:
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.6),
                        Color.pink.opacity(0.4),
                        Color.blue.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Placeholder for mascot video/image
            // TODO: Replace with actual mascot video player
            VStack {
                Spacer()
                
                Image(systemName: mascotIcon)
                    .font(.system(size: 120))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 200)
            }
        }
    }
    
    private var mascotIcon: String {
        switch mascotState {
        case .sleeping: return "moon.zzz.fill"
        case .active: return "flame.fill"
        case .exploring: return "sparkles"
        case .neutral: return "star.fill"
        }
    }
    
    private func startTimer() {
        // Calculate elapsed time from task start
        elapsedTime = Date().timeIntervalSince(task.startTime)
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1.0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMascotState() {
        // Determine mascot state based on context
        // For now, default to active when working on a task
        mascotState = .active
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ImmersiveWorkingOnView(
        task: Task(
            userID: "preview-user",
            title: "Sample Task",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            category: .work
        )
    ) {
        print("Dismissed")
    }
}

