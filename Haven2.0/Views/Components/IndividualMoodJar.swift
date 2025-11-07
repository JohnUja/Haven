//
//  IndividualMoodJar.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct IndividualMoodJar: View {
    let moodType: MoodType
    let count: Int
    let onCashIn: () -> Void
    
    private var isFull: Bool {
        count >= 15
    }
    
    private var fillPercentage: Double {
        Double(count) / 15.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Mood type label with SF Symbol icon
            HStack {
                Image(systemName: moodType.icon)
                    .font(.title2)
                    .foregroundColor(moodType.iconColor)
                    .frame(width: 24, height: 24)
                Text(moodType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(count)/15")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Jar container with marbles
            ZStack(alignment: .bottom) {
                // Jar shape (glass-like effect)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
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
                    )
                    .frame(height: 150)
                    .overlay(
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
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Marbles filling from bottom
                if count > 0 {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                            ForEach(0..<min(count, 15), id: \.self) { index in
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                moodColor.opacity(0.9),
                                                moodColor.opacity(0.7)
                                            ],
                                            center: .topLeading,
                                            startRadius: 5,
                                            endRadius: 12
                                        )
                                    )
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                        .frame(height: fillPercentage * 150)
                        .transition(.move(edge: .bottom))
                    }
                } else {
                    VStack {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.2))
                        Text("Empty")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            
            // Cash In button
            Button(action: onCashIn) {
                HStack {
                    Image(systemName: isFull ? "sparkles" : "lock.fill")
                        .font(.caption)
                    
                    Text(isFull ? "Cash In (350)" : "\(15 - count) to go")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(isFull ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isFull
                            ? LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(!isFull)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var moodColor: Color {
        switch moodType {
        case .happy, .excited, .energetic:
            return .yellow
        case .calm:
            return .blue
        case .sad, .tired:
            return .gray
        case .anxious, .frustrated:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        IndividualMoodJar(moodType: .happy, count: 15, onCashIn: {})
        IndividualMoodJar(moodType: .calm, count: 8, onCashIn: {})
        IndividualMoodJar(moodType: .sad, count: 0, onCashIn: {})
    }
    .padding()
    .background(Color.purple.opacity(0.2))
}

