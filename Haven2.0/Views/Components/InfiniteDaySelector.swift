//
//  InfiniteDaySelector.swift
//  TimeFlow
//
//  UIPickerWheel-style day selector with 7 fixed slots
//

import SwiftUI
import AudioToolbox

struct InfiniteDaySelector: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    let hasEvents: (Date) -> Bool
    
    @State private var days: [Date] = []
    @State private var lastHapticDay: Date?
    @State private var isInitializing = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year Header - Smaller, on same line as Work/Personal
            HStack {
                Button(action: {
                    // Quick jump to today
                    selectedDate = Date()
                }) {
                    Text(monthYearString(from: selectedDate))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Day Selector
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let slotWidth = screenWidth / 7
                
                ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(days.indices, id: \.self) { index in
                                let day = days[index]
                                DayCell(
                                    day: day,
                                    isToday: calendar.isDateInToday(day),
                                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                                    hasEvents: hasEvents(day),
                                    width: slotWidth,
                                    onTap: {
                                        selectedDate = day
                                        onDateChanged(day)
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                            proxy.scrollTo(index, anchor: .center)
                                        }
                                        // Haptic on tap
                                        AudioServicesPlaySystemSound(1057)
                                    }
                                )
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("scroll")).minX
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.hidden)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        handleScrollOffset(value: value, slotWidth: slotWidth)
                    }
                    .onAppear {
                        initializePosition(proxy: proxy)
                    }
                    .onChange(of: selectedDate) { _, newDate in
                        // Reset to current date on external change
                        if calendar.isDateInToday(newDate) {
                            resetToToday(proxy: proxy)
                        }
                    }
                }
                
                DayCenterController()
                    .frame(width: slotWidth)
                    .position(x: screenWidth / 2, y: geometry.size.height / 2)
                    .allowsHitTesting(false)
                    .zIndex(10)
                }
            }
            .frame(height: 70)
        }
        .onAppear {
            initializeDays()
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func initializeDays() {
        let today = Date()
        days = (-200...200).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
        // Always set selectedDate to today on initial load
        selectedDate = today
    }
    
    private func initializePosition(proxy: ScrollViewProxy) {
        let todayIndex = 200
        guard todayIndex < days.count else { return }
        
        isInitializing = true
        selectedDate = days[todayIndex]
        lastHapticDay = days[todayIndex]
        onDateChanged(days[todayIndex]) // Load the timeline for today
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            proxy.scrollTo(todayIndex, anchor: .center)
            // Give a moment for scroll to settle before allowing haptics
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInitializing = false
            }
        }
    }
    
    private func resetToToday(proxy: ScrollViewProxy) {
        let todayIndex = 200
        guard todayIndex < days.count else { return }
        
        isInitializing = true
        selectedDate = days[todayIndex]
        lastHapticDay = days[todayIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo(todayIndex, anchor: .center)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInitializing = false
            }
        }
    }
    
    private func handleScrollOffset(value: CGFloat, slotWidth: CGFloat) {
        // Don't trigger haptics during initialization
        guard !isInitializing else { return }
        
        let offset = -value
        let index = Int(round(offset / slotWidth))
        
        guard index >= 0 && index < days.count else { return }
        let centeredDay = days[index]
        
        // Haptic feedback whenever day position changes during scroll
        if let lastDay = lastHapticDay, !calendar.isDate(centeredDay, inSameDayAs: lastDay) {
            AudioServicesPlaySystemSound(1057)
            lastHapticDay = centeredDay
            selectedDate = centeredDay
            onDateChanged(centeredDay)
        } else if lastHapticDay == nil {
            lastHapticDay = centeredDay
        }
    }
}

struct DayCell: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let width: CGFloat
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 5) {
            Text(dayLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            ZStack {
                // Show yellow ring for today ONLY if NOT selected (green replaces it when selected)
                if isToday && !isSelected {
                    Circle()
                        .stroke(Color.yellow.opacity(0.9), lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .shadow(color: .yellow.opacity(0.3), radius: 3)
                }
                
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            
            Circle()
                .fill(hasEvents ? Color.blue : Color.clear)
                .frame(width: 3, height: 3)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: day)
    }
}

struct DayCenterController: View {
    var body: some View {
        VStack(spacing: 5) {
            Text(" ")
                .font(.system(size: 9))
            
            Circle()
                .stroke(Color.green.opacity(0.9), lineWidth: 3)
                .frame(width: 32, height: 32)
                .shadow(color: .green.opacity(0.5), radius: 5)
            
            Circle()
                .fill(Color.clear)
                .frame(width: 4, height: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        InfiniteDaySelector(
            selectedDate: .constant(Date()),
            onDateChanged: { _ in },
            hasEvents: { _ in false }
        )
    }
}
