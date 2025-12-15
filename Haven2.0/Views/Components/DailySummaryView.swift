//
//  DailySummaryView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData

struct DailySummary: Identifiable, Equatable {
    var id: String { UUID().uuidString }
    let date: Date
    let tasksCompleted: Int
    let xpGained: Int
    let crystalsGained: Int
    let bonuses: [String]
    let moodsRecorded: [MoodType]
    
    static func == (lhs: DailySummary, rhs: DailySummary) -> Bool {
        lhs.id == rhs.id
    }
}

struct DailySummaryView: View {
    let summary: DailySummary
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .green.opacity(0.5), radius: 10)
                        
                        Text("Day Complete!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text(dateFormatter.string(from: summary.date))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Summary Cards
                    VStack(spacing: 16) {
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
                            icon: "sparkles",
                            title: "Time Crystals",
                            value: "+\(summary.crystalsGained)",
                            color: .yellow
                        )
                        
                        // Bonuses Applied
                        if !summary.bonuses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "gift.fill")
                                        .foregroundColor(.orange)
                                    Text("Bonuses Applied")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(summary.bonuses.enumerated()), id: \.offset) { index, bonus in
                                        HStack {
                                            Text("✨")
                                                .font(.system(size: 14))
                                            Text(bonus)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Moods Recorded
                        if !summary.moodsRecorded.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "face.smiling.fill")
                                        .foregroundColor(.pink)
                                    Text("Moods Recorded")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack(spacing: 12) {
                                    ForEach(Array(summary.moodsRecorded.enumerated()), id: \.offset) { index, mood in
                                        VStack(spacing: 4) {
                                            Text(mood.emoji)
                                                .font(.title2)
                                            Text(mood.displayName)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(Color.pink.opacity(0.1))
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pink.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var useCrystalIcon: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            if useCrystalIcon {
                Text("✨")
                    .font(.system(size: 20))
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DailySummaryView(
        summary: DailySummary(
            date: Date(),
            tasksCompleted: 8,
            xpGained: 245,
            crystalsGained: 120,
            bonuses: ["First Task Bonus", "5+ Tasks Bonus"],
            moodsRecorded: [.happy, .calm, .energetic]
        ),
        isPresented: .constant(true)
    )
}

