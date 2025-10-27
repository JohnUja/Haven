//
//  DaySelectorButton.swift
//  TimeFlow
//
//  Created by AI Assistant on 2025-01-22.
//

import SwiftUI
import AudioToolbox

struct DaySelectorButton: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool
    let isInCenter: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(spacing: 6) {
                // Day of week label (no circle)
                Text(dayOfWeek)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isInCenter ? .white : .white.opacity(0.7))
                
                // Date number with rings
                ZStack {
                    // Yellow ring for today (always present when isToday)
                    if isToday {
                        Circle()
                            .stroke(
                                isInCenter ? Color.clear : Color.yellow.opacity(0.8),
                                lineWidth: 2
                            )
                            .frame(width: 36, height: 36)
                            .scaleEffect(isInCenter ? 0.9 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInCenter)
                    }
                    
                    // Green ring for center selection (replaces yellow when centered)
                    if isInCenter {
                        Circle()
                            .stroke(
                                Color.green.opacity(0.9),
                                lineWidth: 2.5
                            )
                            .frame(width: 36, height: 36)
                            .scaleEffect(1.1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isInCenter)
                    }
                    
                    // Date number
                    Text("\(calendar.component(.day, from: day))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isInCenter ? .white : .white.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .padding(.top, 2)
                
                // Calendar event indicator
                if hasEvents {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 50)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: day)
    }
}

#Preview {
    HStack {
        DaySelectorButton(
            day: Date(),
            isSelected: false,
            isToday: false,
            isInCenter: false,
            hasEvents: false,
            onTap: {}
        )
        
        DaySelectorButton(
            day: Date().addingTimeInterval(86400),
            isSelected: true,
            isToday: true,
            isInCenter: true,
            hasEvents: true,
            onTap: {}
        )
    }
    .padding()
    .background(Color.black)
}

