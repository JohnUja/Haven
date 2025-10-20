//
//  TimelineView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
// import WeatherKit
// import CoreLocation

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0
    @StateObject private var weatherManager = WeatherManager()
    @State private var timer: Timer?
    
    private var selectedDateTasks: [Task] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
    }
    
    private var currentTime: Date {
        Date()
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }
    
    private var currentMinute: Int {
        Calendar.current.component(.minute, from: currentTime)
    }
    
    private var scrollBasedTime: String {
        // Calculate time based on scroll position
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let targetDate = Calendar.current.date(bySettingHour: targetHour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return formatter.string(from: targetDate)
    }
    
    private var totalTimelineHeight: CGFloat {
        // Total height for 24 hours
        return 24 * 120 // 2880 points
    }
    
    private var knotSpacing: CGFloat {
        // Distance between each knot (hour marker)
        return totalTimelineHeight / 24 // 120 points
    }
    
    private func knotPosition(for hour: Int) -> CGFloat {
        // Calculate position of knot for a specific hour
        return CGFloat(hour) * knotSpacing
    }
    
    private func isKnotActive(for hour: Int) -> Bool {
        // Check if a knot should be "lit up" based on current time
        if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
            return hour <= currentHour
        } else {
            return false // For other days, no knots are active
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Weather Background
                WeatherBackgroundView(
                    scrollOffset: scrollOffset,
                    weatherManager: weatherManager,
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
                                    selectedDate: selectedDate,
                                    currentTime: currentTime,
                                    scrollBasedTime: scrollBasedTime,
                                    scrollOffset: scrollOffset
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
                        print("Scroll offset changed to: \(value)")
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startTimer()
            }
                .onDisappear {
                    stopTimer()
                }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Day Selector
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    Button(action: { selectedDate = day }) {
                        VStack(spacing: 2) {
                            Text(dayOfWeek(for: day))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                            
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .white.opacity(0.7))
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? 
                                      Color.white.opacity(0.3) : Color.clear)
                        )
                    }
                }
            }
            
            // Weather Info - Shows weather for selected date
            HStack {
                let selectedDateWeather = weatherManager.getWeatherForTime(selectedDate)
                
                Image(systemName: selectedDateWeather.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(weatherManager.getTemperatureString(selectedDateWeather.temperature))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(selectedDateWeather.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Current time indicator
                Text("\(currentHour):\(String(format: "%02d", currentMinute))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
                
                // Temperature Unit Toggle
                Button(action: {
                    weatherManager.toggleTemperatureUnit()
                }) {
                    Text(weatherManager.isCelsius ? "°C" : "°F")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
                
                // Weather Toggle Button
                Button(action: {
                    weatherManager.toggleWeather()
                }) {
                    Image(systemName: weatherManager.isWeatherEnabled ? "cloud.sun.fill" : "cloud.slash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
                // Dynamic time based on scroll position (smaller)
                Text(scrollBasedTime)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                    )
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
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // Update every minute to refresh current time
            DispatchQueue.main.async {
                // Force view update
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct TimelineHourView: View {
    let hour: Int
    let tasks: [Task]
    let selectedDate: Date
    let currentTime: Date
    let scrollBasedTime: String
    let scrollOffset: CGFloat
    
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
            
            // Central Timeline with Rope and Knots
            VStack {
                // Top circle (start of rope)
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                
                Text(hourText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                
                ZStack(alignment: .top) {
                    // Background timeline
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                    
                    // Current time indicator (only for today, positioned at hour intervals)
                    if Calendar.current.isDate(selectedDate, inSameDayAs: currentTime) {
                        let currentHour = Calendar.current.component(.hour, from: currentTime)
                        let currentMinute = Calendar.current.component(.minute, from: currentTime)
                        let isCurrentHour = hour == currentHour
                        
                        if isCurrentHour {
                            // Calculate if we're scrolled to the center of the screen
                            let isAtCenter = abs(scrollOffset) < 60 // Within 60 points of center
                            
                            VStack(spacing: 4) {
                                // Time indicator dot with fill animation
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isCurrentHour ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: isCurrentHour)
                                
                                // Time text in rectangular box - transparent background with white border
                                Text("\(currentHour):\(String(format: "%02d", currentMinute))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isAtCenter ? .black : .white) // Black text when filled, white when transparent
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isAtCenter ? Color.white : Color.clear) // Fill when at center
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.white, lineWidth: 1) // Always show border
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: isAtCenter)
                            }
                            .offset(y: 20) // Position it below the hour text
                        }
                    }
                }
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
                .fill(Color.clear)
        )
        .frame(maxWidth: 120)
    }
}

struct WeatherBackgroundView: View {
    let scrollOffset: CGFloat
    let weatherManager: WeatherManager
    let selectedDate: Date
    
    private var timeAndWeatherBasedColors: [Color] {
        guard weatherManager.isWeatherEnabled else {
            // Return theme-based colors when weather is disabled
            return [.purple.opacity(0.8), .blue.opacity(0.6), .pink.opacity(0.4)]
        }
        
        // Calculate which hour is in the middle of the screen based on scroll position
        let middleOfScreenHour = getMiddleOfScreenHour()
        let currentWeather = weatherManager.getWeatherForHour(middleOfScreenHour)
        
        print("Middle of screen hour: \(middleOfScreenHour), Weather: \(currentWeather.condition), Temp: \(currentWeather.temperature)")
        
        // Base colors for time of day
        var baseColors: [Color]
        switch middleOfScreenHour {
        case 6...8:
            baseColors = [.orange.opacity(0.8), .yellow.opacity(0.6), .blue.opacity(0.4)]
        case 9...17:
            baseColors = [.blue.opacity(0.6), .cyan.opacity(0.4), .white.opacity(0.2)]
        case 18...20:
            baseColors = [.orange.opacity(0.6), .red.opacity(0.4), .purple.opacity(0.3)]
        default:
            baseColors = [.purple.opacity(0.8), .black.opacity(0.6), .blue.opacity(0.4)]
        }
        
        // Modify colors based on weather condition
        switch currentWeather.condition {
        case .sunny:
            return [.yellow.opacity(0.9), .orange.opacity(0.7), .white.opacity(0.5)]
        case .cloudy:
            return [.gray.opacity(0.8), .blue.opacity(0.6), .white.opacity(0.3)]
        case .rainy:
            return [.blue.opacity(0.8), .gray.opacity(0.6), .white.opacity(0.3)]
        case .stormy:
            return [.purple.opacity(0.9), .black.opacity(0.8), .blue.opacity(0.5)]
        }
    }
    
    private func getMiddleOfScreenHour() -> Int {
        // Calculate which hour is in the middle of the screen
        // Each hour is 120 points high
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        return (baseHour + hourOffset) % 24
    }
    
    var body: some View {
        ZStack {
            // Base gradient based on time of day and weather
            LinearGradient(
                colors: timeAndWeatherBasedColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Weather effects based on current scroll position
            if weatherManager.isWeatherEnabled {
                let currentWeather = weatherManager.getWeatherForScrollPosition(scrollOffset, selectedDate: selectedDate)
                
                if currentWeather.condition == .rainy {
                    RainEffectView()
                } else if currentWeather.condition == .cloudy {
                    CloudEffectView()
                } else if currentWeather.condition == .stormy {
                    StormEffectView()
                }
            }
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

struct StormEffectView: View {
    @State private var lightningFlash: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Lightning flash
                if lightningFlash {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .ignoresSafeArea()
                }
                
                // Rain drops
                ForEach(0..<30, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3, height: 25)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: -100...geometry.size.height)
                        )
                }
            }
        }
        .onAppear {
            // Random lightning flashes
            Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    lightningFlash = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        lightningFlash = false
                    }
                }
            }
        }
    }
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
