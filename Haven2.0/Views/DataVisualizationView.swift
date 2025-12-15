//
//  DataVisualizationView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataVisualizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @Query private var goals: [Goal]
    @Query private var moodEntries: [MoodEntry]
    @Query private var routines: [DailyRoutine]
    
    @State private var selectedView: VisualizationType = .consistency
    @State private var showingExportSheet = false
    @State private var csvData: String = ""
    
    private var currentUser: User? {
        users.first
    }
    
    enum VisualizationType: String, CaseIterable {
        case consistency = "Consistency"
        case activityMood = "Activity & Mood"
        case weeklySummary = "Weekly Summary"
        
        var displayName: String {
            rawValue
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background using theme gradient
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // View Type Picker
                    Picker("Visualization", selection: $selectedView) {
                        ForEach(VisualizationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedView {
                            case .consistency:
                                consistencyHeatmapView
                            case .activityMood:
                                activityMoodCorrelationView
                            case .weeklySummary:
                                weeklySummaryView
                            }
                            
                            // Export Button
                            Button(action: {
                                exportToCSV()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export to CSV")
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
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
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [csvData])
            }
        }
    }
    
    // MARK: - Consistency Heatmap
    private var consistencyHeatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Consistency Heatmap")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)
            
            Text("Your activity over the last 6 months")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
            
            if let user = currentUser {
                let calendar = Calendar.current
                let endDate = Date()
                let startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
                let heatmapData = DataVisualizationService.shared.getConsistencyHeatmapData(
                    user: user,
                    tasks: tasks,
                    startDate: startDate,
                    endDate: endDate
                )
                
                ConsistencyHeatmapView(heatmapData: heatmapData, startDate: startDate, endDate: endDate)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Activity & Mood Correlation
    private var activityMoodCorrelationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity & Mood Correlation")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)
            
            Text("See how your activity affects your mood")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
            
            if let user = currentUser {
                let correlationData = DataVisualizationService.shared.getActivityMoodCorrelation(
                    user: user,
                    tasks: tasks,
                    moodEntries: moodEntries
                )
                
                ActivityMoodCorrelationView(correlationData: correlationData)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Weekly Summary
    private var weeklySummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Summary")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)
            
            if let user = currentUser {
                let summary = DataVisualizationService.shared.getWeeklySummary(
                    user: user,
                    tasks: tasks,
                    goals: goals,
                    moodEntries: moodEntries
                )
                
                VStack(spacing: 12) {
                    SummaryCard(icon: "checkmark.circle.fill", title: "Tasks Completed", value: "\(summary.tasksCompleted)", color: .blue)
                    SummaryCard(icon: "flag.fill", title: "Goals Completed", value: "\(summary.goalsCompleted)", color: .green)
                    SummaryCard(icon: "heart.fill", title: "Mood Entries", value: "\(summary.moodEntries)", color: .purple)
                    if let avgMood = summary.averageMood {
                        SummaryCard(icon: "chart.line.uptrend.xyaxis", title: "Average Mood", value: String(format: "%.1f", avgMood), color: .orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Export
    private func exportToCSV() {
        guard let user = currentUser else { return }
        
        csvData = DataVisualizationService.shared.exportToCSV(
            user: user,
            tasks: tasks,
            goals: goals,
            moodEntries: moodEntries,
            routines: routines
        )
        
        showingExportSheet = true
    }
}

// MARK: - Consistency Heatmap View
struct ConsistencyHeatmapView: View {
    let heatmapData: [Date: Int]
    let startDate: Date
    let endDate: Date
    @Environment(ThemeManager.self) private var themeManager
    
    private var maxValue: Int {
        heatmapData.values.max() ?? 1
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: 8) {
            // Legend
            HStack {
                Text("Less")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(intensityColor(for: Double(index) / 4.0))
                            .frame(width: 20, height: 20)
                    }
                }
                
                Text("More")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            
            // Calendar grid (simplified - showing last 30 days)
            let calendar = Calendar.current
            let daysToShow = 30
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            
            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(0..<daysToShow, id: \.self) { dayOffset in
                    if let date = calendar.date(byAdding: .day, value: -daysToShow + dayOffset, to: Date()) {
                        let dayStart = calendar.startOfDay(for: date)
                        let value = heatmapData[dayStart] ?? 0
                        let intensity = maxValue > 0 ? Double(value) / Double(maxValue) : 0.0
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(intensityColor(for: intensity))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(intensity > 0.5 ? .white : theme.textPrimary)
                            )
                    }
                }
            }
        }
    }
    
    private func intensityColor(for intensity: Double) -> Color {
        if intensity == 0 {
            return Color.gray.opacity(0.2)
        }
        return Color.green.opacity(0.3 + (intensity * 0.7))
    }
}

// MARK: - Activity & Mood Correlation View
struct ActivityMoodCorrelationView: View {
    let correlationData: [(activity: Int, mood: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if correlationData.isEmpty {
                Text("Not enough data yet. Complete tasks and log moods to see correlations.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Simple scatter plot representation
                GeometryReader { geometry in
                    ZStack {
                        // Axes
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: geometry.size.height - 20))
                            path.addLine(to: CGPoint(x: geometry.size.width - 20, y: geometry.size.height - 20))
                            path.move(to: CGPoint(x: 20, y: 20))
                            path.addLine(to: CGPoint(x: 20, y: geometry.size.height - 20))
                        }
                        .stroke(Color.secondary, lineWidth: 1)
                        
                        // Data points
                        ForEach(Array(correlationData.enumerated()), id: \.offset) { index, data in
                            let maxActivity = correlationData.map { $0.activity }.max() ?? 1
                            let maxMood = correlationData.map { abs($0.mood) }.max() ?? 1.0
                            
                            let x = 20 + (CGFloat(data.activity) / CGFloat(maxActivity)) * (geometry.size.width - 40)
                            let y = geometry.size.height - 20 - (CGFloat(abs(data.mood)) / CGFloat(maxMood)) * (geometry.size.height - 40)
                            
                            Circle()
                                .fill(Color.purple.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)
                
                // Labels
                HStack {
                    Text("Activity Level")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Mood Score")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Summary Card
struct DataSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, design: .rounded))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataVisualizationView()
        .modelContainer(for: [User.self, Task.self, Goal.self, MoodEntry.self], inMemory: true)
}

