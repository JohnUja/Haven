//
//  TimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @State private var weatherData: WeatherData = WeatherData.sample
    
    private var selectedDateTasks: [Task] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Weather Background
                WeatherBackgroundView(
                    scrollOffset: scrollOffset,
                    weatherData: weatherData,
                    selectedDate: selectedDate
                )
                .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Timeline Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(hourRange, id: \.self) { hour in
                                TimelineHourView(
                                    hour: hour,
                                    tasks: tasksForHour(hour),
                                    selectedDate: selectedDate
                                )
                                .frame(height: 120)
                            }
                        }
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Day Selector
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    Button(action: { selectedDate = day }) {
                        Text(dayOfWeek(for: day))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? 
                                          Color.white.opacity(0.3) : Color.clear)
                            )
                    }
                }
            }
            
            // Weather Info
            HStack {
                Image(systemName: weatherData.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("\(weatherData.temperature)°F")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Title
            Text("Timeline View")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black.opacity(0.3), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var hourRange: [Int] {
        Array(0...23)
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func tasksForHour(_ hour: Int) -> [Task] {
        selectedDateTasks.filter { task in
            Calendar.current.component(.hour, from: task.startTime) == hour
        }
    }
}

struct TimelineHourView: View {
    let hour: Int
    let tasks: [Task]
    let selectedDate: Date
    
    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side (Work tasks)
            VStack(alignment: .leading, spacing: 4) {
                Text("Work")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 8)
                
                ForEach(tasks.filter { $0.category == .work }) { task in
                    TaskTimelineBlock(task: task, side: .left)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Central Timeline
            VStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                
                Text(hourText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 60)
            
            // Right side (Personal tasks)
            VStack(alignment: .trailing, spacing: 4) {
                Text("Personal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 8)
                
                ForEach(tasks.filter { $0.category == .personal }) { task in
                    TaskTimelineBlock(task: task, side: .right)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}

struct TaskTimelineBlock: View {
    let task: Task
    let side: TimelineSide
    
    enum TimelineSide {
        case left, right
    }
    
    var body: some View {
        VStack(alignment: side == .left ? .leading : .trailing, spacing: 2) {
            Text(task.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(task.startTime, format: .dateTime.hour().minute()) - \(task.endTime, format: .dateTime.hour().minute())")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(task.priority.color).opacity(0.8))
        )
        .frame(maxWidth: 120)
    }
}

struct WeatherBackgroundView: View {
    let scrollOffset: CGFloat
    let weatherData: WeatherData
    let selectedDate: Date
    
    var body: some View {
        ZStack {
            // Base gradient based on time of day
            LinearGradient(
                colors: timeBasedColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Weather effects
            if weatherData.condition == .rainy {
                RainEffectView()
            } else if weatherData.condition == .cloudy {
                CloudEffectView()
            }
        }
    }
    
    private var timeBasedColors: [Color] {
        let hour = Calendar.current.component(.hour, from: selectedDate)
        let adjustedHour = (hour + Int(scrollOffset / 100)) % 24
        
        switch adjustedHour {
        case 6...8:
            return [.orange.opacity(0.8), .yellow.opacity(0.6), .blue.opacity(0.4)]
        case 9...17:
            return [.blue.opacity(0.6), .cyan.opacity(0.4), .white.opacity(0.2)]
        case 18...20:
            return [.orange.opacity(0.6), .red.opacity(0.4), .purple.opacity(0.3)]
        default:
            return [.purple.opacity(0.8), .black.opacity(0.6), .blue.opacity(0.4)]
        }
    }
}

struct RainEffectView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: 20)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: animationOffset + CGFloat.random(in: -100...0)
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = 1000
            }
        }
    }
}

struct CloudEffectView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height * 0.5)
                    )
            }
        }
    }
}

struct WeatherData {
    let temperature: Int
    let condition: WeatherCondition
    let icon: String
    
    static let sample = WeatherData(
        temperature: 72,
        condition: .sunny,
        icon: "sun.max.fill"
    )
}

enum WeatherCondition {
    case sunny, cloudy, rainy, stormy
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Task.self], inMemory: true)
}
