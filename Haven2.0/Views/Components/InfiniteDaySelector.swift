//
//  InfiniteDaySelector.swift
//  TimeFlow
//
//  UIPickerWheel-style day selector with 7 fixed slots (GitHub Version)
//

import SwiftUI
import AudioToolbox
import UIKit

struct InfiniteDaySelector: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    let hasEvents: (Date) -> Bool
    let showMonthHeader: Bool // Kept for API compatibility
    
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var days: [Date] = []
    @State private var lastHapticDay: Date?
    @State private var isInitializing = false
    @State private var scrollDebounceTask: _Concurrency.Task<Void, Never>?
    @State private var lastNotifiedDate: Date?
    
    private let calendar = Calendar.current
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(spacing: 12) {
            // Month/Year Header - Smaller, on same line as Work/Personal (removed per user request - now in timeline header)
            
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
                                        theme: theme,
                                        onTap: {
                                            selectedDate = day
                                            onDateChanged(day)
                                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                                proxy.scrollTo(index, anchor: .center)
                                            }
                                            // More vibrational haptic on tap
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
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
                    
                    DayCenterController(theme: theme)
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
        
        // Update selectedDate immediately for UI responsiveness
        if let lastDay = lastHapticDay, !calendar.isDate(centeredDay, inSameDayAs: lastDay) {
            // More vibrational haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            lastHapticDay = centeredDay
                selectedDate = centeredDay
            
            // Debounce onDateChanged to prevent excessive recomputations
            scrollDebounceTask?.cancel()
            scrollDebounceTask = _Concurrency.Task { @MainActor in
                // Only notify if date hasn't changed in 200ms (scroll has settled)
                try? await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                // Check if this is still the current date (not cancelled)
                if let lastNotified = lastNotifiedDate, calendar.isDate(lastNotified, inSameDayAs: centeredDay) {
                    return // Already notified for this date
                }
                
                if calendar.isDate(centeredDay, inSameDayAs: selectedDate) {
                    onDateChanged(centeredDay)
                    lastNotifiedDate = centeredDay
                }
            }
        } else if lastHapticDay == nil {
            lastHapticDay = centeredDay
            selectedDate = centeredDay
        }
    }
}

// MARK: - Scroll Offset Preference Key
// Note: ScrollOffsetPreferenceKey is defined in TimelineView.swift to avoid redeclaration

struct DayCell: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let width: CGFloat
    let theme: any AppTheme
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 5) {
            Text(dayLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(theme.textPrimary.opacity(0.7))
            
            ZStack {
                // Show yellow ring for today ONLY if NOT selected (green replaces it when selected)
                if isToday && !isSelected {
                    Circle()
                        .stroke(theme.warningColor.opacity(0.9), lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .shadow(color: theme.warningColor.opacity(0.3), radius: 3)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Show green ring when selected
                if isSelected {
                    Circle()
                        .stroke(theme.successColor.opacity(0.9), lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .shadow(color: theme.successColor.opacity(0.5), radius: 5)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.7)),
                            removal: .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                        ))
                }
                
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            .frame(width: 32, height: 32)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isToday)
            
            Circle()
                .fill(hasEvents ? theme.accentColor : Color.clear)
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
    let theme: any AppTheme
    
    var body: some View {
        VStack(spacing: 5) {
            Text(" ")
                .font(.system(size: 9))
            
            Circle()
                .stroke(theme.successColor.opacity(0.9), lineWidth: 3)
                .frame(width: 32, height: 32)
                .shadow(color: theme.successColor.opacity(0.5), radius: 5)
            
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
            hasEvents: { _ in false },
            showMonthHeader: true
        )
        .environment(ThemeManager())
    }
}
// MARK: - Preference Keys
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
