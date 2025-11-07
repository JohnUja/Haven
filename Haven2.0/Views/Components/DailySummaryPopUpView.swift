//
//  DailySummaryPopUpView.swift
//  TimeFlow
//
//  Created by AI on 2025-01-13.
//

import SwiftUI
import SwiftData

struct DailySummaryPopUpView: View {
    let summary: DailySummary
    let onDismiss: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // Large checkmark icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.mint.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .green.opacity(0.6), radius: 15)
                }
                
                Text("Day Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(dateFormatter.string(from: summary.date))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Summary Cards
            VStack(spacing: 14) {
                // Tasks Completed
                SummaryCard(
                    icon: "checklist",
                    title: "Tasks Completed",
                    value: "\(summary.tasksCompleted)",
                    color: .blue
                )
                
                // XP Gained
                SummaryCard(
                    icon: "star.fill",
                    title: "XP Gained",
                    value: "+\(summary.xpGained)",
                    color: .purple
                )
                
                // Crystals Gained
                SummaryCard(
                    icon: "diamond.fill",
                    title: "Time Crystals",
                    value: "+\(summary.crystalsGained)",
                    color: .yellow,
                    useCrystalIcon: true
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // Done Button
            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

 //SummaryCard is defined in DailySummaryView.swift - no need to redeclare

#Preview {
    ZStack {
        Color.black.opacity(0.6)
        
        DailySummaryPopUpView(
            summary: DailySummary(
                date: Date(),
                tasksCompleted: 8,
                xpGained: 245,
                crystalsGained: 120,
                bonuses: ["First Task Bonus", "5+ Tasks Bonus"],
                moodsRecorded: [.happy, .calm, .energetic]
            )
        ) {
            print("Dismissed")
        }
    }
}

