//
//  CrystalCounterView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import AudioToolbox

struct CrystalCounterView: View {
    let currentCrystals: Int
    let earnedCrystals: Int
    @State private var displayedCrystals: Int
    @State private var isAnimating = false
    
    init(currentCrystals: Int, earnedCrystals: Int = 0) {
        self.currentCrystals = currentCrystals
        self.earnedCrystals = earnedCrystals
        self._displayedCrystals = State(initialValue: currentCrystals - earnedCrystals)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Custom 3D crystal icon
            Crystal3DView()
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(3, autoreverses: true), value: isAnimating)
            
            // Crystal count with more space
            Text("\(displayedCrystals)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .frame(minWidth: 30) // Ensure enough space for numbers
        }
        .padding(.horizontal, 14) // Increased horizontal padding
        .padding(.vertical, 7) // Slightly increased vertical padding
        .background(
            ZStack {
                // Distinct background with gradient for better contrast
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle border for definition
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.4),
                                Color.orange.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .shadow(color: .yellow.opacity(0.3), radius: 4, x: 0, y: 2)
        .onChange(of: currentCrystals) { oldValue, newValue in
            // Animate counter increment
            if newValue > oldValue {
                animateCounter(from: oldValue, to: newValue)
            } else {
                displayedCrystals = newValue
            }
        }
        .onAppear {
            displayedCrystals = currentCrystals
        }
    }
    
    private func animateCounter(from start: Int, to end: Int) {
        let difference = end - start
        let duration = 0.8
        let steps = abs(difference)
        let stepDuration = duration / Double(steps)
        
        isAnimating = true
        
        // Haptic feedback for significant increments
        if difference >= 10 {
            AudioServicesPlaySystemSound(1520)
        }
        
        for i in 0...steps {
            let delay = stepDuration * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let intermediate = start + Int((Double(difference) * Double(i) / Double(steps)).rounded())
                withAnimation(.easeInOut(duration: stepDuration)) {
                    displayedCrystals = intermediate
                }
                
                if i == steps {
                    displayedCrystals = end
                    isAnimating = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3)
        CrystalCounterView(currentCrystals: 247, earnedCrystals: 23)
    }
}

