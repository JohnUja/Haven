//
//  AIInsightsView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct AIInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var insights: [AIInsight] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    headerView
                    
                    // Insights List
                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("AI Insights")
            .onAppear {
                generateInsights()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    Text("AI Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("You have \(insights.count) new suggestions today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func generateInsights() {
        // Generate sample insights based on task patterns
        var newInsights: [AIInsight] = []
        
        // Well-being suggestion
        if hasLongFocusSession() {
            newInsights.append(AIInsight(
                type: .wellbeing,
                title: "Well-being Suggestion",
                message: "You've been focused for 2 hours. A 15-minute break could boost your creativity.",
                icon: "heart.fill",
                color: .green,
                actions: [
                    InsightAction(title: "Accept Break", color: .green, action: {}),
                    InsightAction(title: "Postpone", color: .orange, action: {}),
                    InsightAction(title: "Decline", color: .gray, action: {})
                ]
            ))
        }
        
        // Schedule optimization
        if hasOverlappingTasks() {
            newInsights.append(AIInsight(
                type: .scheduleOptimization,
                title: "Schedule Optimization",
                message: "Your afternoon is packed. Consider rescheduling 'Review App Analytics' to tomorrow morning.",
                icon: "clock.fill",
                color: .blue,
                impact: "High Impact",
                actions: [
                    InsightAction(title: "Reschedule", color: .blue, action: {}),
                    InsightAction(title: "Ignore", color: .gray, action: {})
                ]
            ))
        }
        
        // Pattern recognition
        if let peakTime = findProductivityPeak() {
            newInsights.append(AIInsight(
                type: .patternRecognition,
                title: "Pattern Recognized",
                message: "Your productivity peaks between \(peakTime) AM and \(peakTime + 1) AM. Schedule your most demanding tasks then.",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple,
                actions: [
                    InsightAction(title: "Apply", color: .purple, action: {}),
                    InsightAction(title: "Learn More", color: .blue, action: {})
                ]
            ))
        }
        
        insights = newInsights
    }
    
    private func hasLongFocusSession() -> Bool {
        // Check if user has been working for more than 2 hours without a break
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-7200)
        
        let recentTasks = tasks.filter { task in
            task.startTime >= twoHoursAgo && task.startTime <= now && task.category == .work
        }
        
        return !recentTasks.isEmpty
    }
    
    private func hasOverlappingTasks() -> Bool {
        // Check for overlapping tasks
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        
        // Need at least 2 tasks to check for overlaps
        guard sortedTasks.count >= 2 else { return false }
        
        for i in 0..<sortedTasks.count - 1 {
            let current = sortedTasks[i]
            let next = sortedTasks[i + 1]
            
            if current.endTime > next.startTime {
                return true
            }
        }
        
        return false
    }
    
    private func findProductivityPeak() -> Int? {
        // Analyze task completion patterns to find peak productivity hours
        let completedTasks = tasks.filter { $0.isComplete }
        
        var hourCounts: [Int: Int] = [:]
        for task in completedTasks {
            let hour = Calendar.current.component(.hour, from: task.startTime)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }
}

struct InsightCardView: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(insight.color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(insight.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let impact = insight.impact {
                            Text(impact)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.pink)
                                )
                        }
                    }
                }
                
                Spacer()
            }
            
            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Pattern visualization for pattern recognition
            if insight.type == .patternRecognition {
                PatternChartView()
                    .frame(height: 60)
            }
            
            // Actions
            HStack(spacing: 12) {
                ForEach(insight.actions, id: \.title) { action in
                    Button(action: action.action) {
                        Text(action.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(action.color)
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PatternChartView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 20,
                        height: CGFloat.random(in: 20...60)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String
    let color: Color
    let impact: String?
    let actions: [InsightAction]
    
    init(type: InsightType, title: String, message: String, icon: String, color: Color, impact: String? = nil, actions: [InsightAction]) {
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.impact = impact
        self.actions = actions
    }
}

struct InsightAction {
    let title: String
    let color: Color
    let action: () -> Void
}

enum InsightType {
    case wellbeing
    case scheduleOptimization
    case patternRecognition
}

#Preview {
    AIInsightsView()
        .modelContainer(for: [Task.self], inMemory: true)
}
