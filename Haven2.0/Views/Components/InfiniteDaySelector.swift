//
//  InfiniteDaySelector.swift
//  TimeFlow
//  Created by John Uja
//  Optimized O(1) virtualized day selector with fixed-size sliding window
//

import SwiftUI
import AudioToolbox
import UIKit
import AVFoundation

struct InfiniteDaySelector: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    let hasEvents: (Date) -> Bool
    let showMonthHeader: Bool
    @Environment(ThemeManager.self) private var themeManager
    
    init(selectedDate: Binding<Date>, 
         onDateChanged: @escaping (Date) -> Void, 
         hasEvents: @escaping (Date) -> Bool,
         showMonthHeader: Bool = true) {
        self._selectedDate = selectedDate
        self.onDateChanged = onDateChanged
        self.hasEvents = hasEvents
        self.showMonthHeader = showMonthHeader
    }
    
    // O(1) Fixed-size sliding window (never grows beyond bufferSize * 2 + 1)
    @State private var visibleDays: [Date] = []
    @State private var lastHapticIndex: Int?
    @State private var lastHapticDay: Date? // Track last day that triggered haptic (more reliable than index)
    @State private var isInitializing = false
    @State private var isViewReady = false
    @State private var impactGenerator: UIImpactFeedbackGenerator? = UIImpactFeedbackGenerator(style: .light)
    @State private var selectionGenerator: UISelectionFeedbackGenerator? = UISelectionFeedbackGenerator()
    @State private var pendingDate: Date? // Date pending load (user scrolled but hasn't tapped center yet)
    @State private var scrollEndTask: _Concurrency.Task<Void, Never>? // Task to commit pending date after scroll ends
    
    // Virtualization constants - fixed size window
    private let bufferSize = 10 // Days on each side of center (total: 21 days)
    private var centerIndex: Int { bufferSize } // Index of center day
    
    // Static DateFormatters (created once, reused forever)
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year Header removed - moved to top nav
            
            // Day Selector
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let slotWidth = screenWidth / 7
                
                ZStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(visibleDays, id: \.self) { day in
                                    DayCellWithHaptic(
                                        day: day,
                                        isToday: calendar.isDateInToday(day),
                                        isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                                        hasEvents: hasEvents(day),
                                        width: slotWidth,
                                        screenWidth: screenWidth,
                                        onTap: {
                                            handleDayTap(day: day, proxy: proxy)
                                        },
                                        onCenterCrossed: {
                                            // When day crosses center during scroll - visual feedback only, no data load
                                            if let dayIndex = visibleDays.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }),
                                               dayIndex != lastHapticIndex {
                                                // Light haptic for visual feedback
                                                selectionGenerator?.selectionChanged()
                                                impactGenerator?.prepare()
                                                selectionGenerator?.prepare()
                                                
                                                // Store pending date for visual feedback (DON'T update selectedDate during scroll)
                                                    pendingDate = day
                                                
                                                lastHapticIndex = dayIndex
                                                lastHapticDay = day
                                                
                                                // Check if we need to recenter window
                                                recenterWindowIfNeeded(currentIndex: dayIndex, proxy: proxy)
                                            }
                                        }
                                    )
                                    .id(day)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .coordinateSpace(name: "scroll")
                        .scrollTargetBehavior(.viewAligned) // Smooth scrolling with view alignment (normal input feedback)
                        .scrollBounceBehavior(.basedOnSize) // Add bounce behavior
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named("scroll")).minX
                                    )
                                }
                            )
                        .scrollIndicators(.hidden)
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // CRITICAL: Call handler on EVERY preference change (every frame during scroll)
                            handleScrollOffset(value: value, slotWidth: slotWidth, proxy: proxy)
                            
                            // Cancel previous scroll end task
                            scrollEndTask?.cancel()
                            
                            // Schedule commit of pending date after scroll ends (0.3 seconds of no movement)
                            scrollEndTask = _Concurrency.Task {
                                try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                if !_Concurrency.Task.isCancelled, let pending = pendingDate {
                                    // Commit the pending date when scroll ends
                                    selectedDate = pending
                                    onDateChanged(pending)
                                    pendingDate = nil
                                }
                            }
                        }
                        .onPreferenceChange(DayPositionPreferenceKey.self) { positions in
                            // CRITICAL: Track each day cell's position and detect center crossings
                            // This fires on EVERY frame during scroll, giving us precise haptic feedback
                            guard !isInitializing && isViewReady else { return }
                            
                            let screenCenter = screenWidth / 2
                            
                            // Find the day closest to center (most accurate method)
                            var closestDay: (day: Date, index: Int, distance: CGFloat)? = nil
                            
                            for position in positions {
                                let distanceFromCenter = abs(position.midX - screenCenter)
                                
                                // Find the day index
                                guard let dayIndex = visibleDays.firstIndex(where: { calendar.isDate($0, inSameDayAs: position.day) }) else { continue }
                                
                                // Track the closest day to center
                                if closestDay == nil || distanceFromCenter < closestDay!.distance {
                                    closestDay = (position.day, dayIndex, distanceFromCenter)
                                }
                            }
                            
                            // If we found a day and it's close enough to center, trigger haptic
                            if let closest = closestDay, closest.distance < 25.0 { // Increased threshold to 25 points
                                // CRITICAL: Check if this is a different day than last haptic (using date comparison for reliability)
                                let isNewDay = lastHapticDay == nil || !calendar.isDate(closest.day, inSameDayAs: lastHapticDay!)
                                
                                if isNewDay {
                                    // Day crossed center - trigger light haptic for visual feedback only
                                    // Don't load data yet - user can scroll freely
                                    selectionGenerator?.selectionChanged() // Light haptic only
                                    impactGenerator?.prepare()
                                    selectionGenerator?.prepare()
                                    
                                    // Store pending date for visual feedback (DON'T update selectedDate during scroll)
                                    pendingDate = closest.day
                                    
                                    lastHapticIndex = closest.index
                                    lastHapticDay = closest.day
                                    
                                    // Check if we need to recenter window
                                    recenterWindowIfNeeded(currentIndex: closest.index, proxy: proxy)
                                }
                            }
                        }
                        .task {
                            // SwiftUI-native initialization (replaces fragile asyncAfter)
                            initializeWindow()
                            impactGenerator?.prepare()
                            selectionGenerator?.prepare()
                            
                            // Wait for view to be ready, then scroll to center
                            try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            isViewReady = true
                            
                            // Scroll to center day with smooth animation
                            if let centerDay = visibleDays[safe: centerIndex] {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    proxy.scrollTo(centerDay, anchor: .center)
                                }
                            }
                        }
                        .onChange(of: selectedDate) { oldDate, newDate in
                            // Only handle external date changes (not from internal scroll)
                            // If the date changed but we have a pending date, it's from scroll - ignore
                            if pendingDate != nil && calendar.isDate(newDate, inSameDayAs: pendingDate!) {
                                return // Ignore - this is from our scroll handler
                            }
                            
                            // External date change - recenter window if needed
                            if !isDateInWindow(newDate) {
                                recenterWindow(around: newDate)
                            }
                            
                            // Scroll to the new date with smooth animation
                            if isViewReady && !calendar.isDate(oldDate, inSameDayAs: newDate) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    proxy.scrollTo(newDate, anchor: .center)
                                }
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
    }
    
    // MARK: - Window Management (O(1) Operations)
    
    /// Creates a fixed-size window of days around a center date
    private func createDayWindow(around date: Date) -> [Date] {
        let range = (-bufferSize...bufferSize)
        return range.compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date)
        }
    }
    
    /// Initializes the window centered on today
    private func initializeWindow() {
        let today = calendar.startOfDay(for: Date())
        visibleDays = createDayWindow(around: today)
        selectedDate = today
        lastHapticIndex = centerIndex
        lastHapticDay = today
    }
    
    /// Recenters the window around a new date (used when jumping to today or external changes)
    private func recenterWindow(around date: Date) {
        let centeredDate = calendar.startOfDay(for: date)
        visibleDays = createDayWindow(around: centeredDate)
        selectedDate = centeredDate
        lastHapticIndex = centerIndex
        lastHapticDay = centeredDate
    }
    
    /// Checks if a date is within the current visible window
    private func isDateInWindow(_ date: Date) -> Bool {
        let dateStart = calendar.startOfDay(for: date)
        return visibleDays.contains { calendar.isDate($0, inSameDayAs: dateStart) }
    }
    
    /// Rebuilds the window when user scrolls near an edge (the "virtualization" trick)
    private func recenterWindowIfNeeded(currentIndex: Int, proxy: ScrollViewProxy) {
        let distanceFromStart = currentIndex
        let distanceFromEnd = visibleDays.count - currentIndex - 1
        let threshold = 5 // Rebuild when within 5 days of edge
        
        if distanceFromStart < threshold || distanceFromEnd < threshold {
            // Get the currently centered date
            guard let centeredDate = visibleDays[safe: currentIndex] else { return }
            
            // Rebuild window around this date
            let newWindow = createDayWindow(around: centeredDate)
            
            // Update state
            visibleDays = newWindow
            
            // Instantly jump back to center (user won't notice if done correctly)
            DispatchQueue.main.async {
                if let centerDay = visibleDays[safe: centerIndex] {
                    proxy.scrollTo(centerDay, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleDayTap(day: Date, proxy: ScrollViewProxy) {
        // Find index of tapped day
        guard let tappedIndex = visibleDays.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) else {
            return
        }
        
        // Update haptic tracking
        lastHapticIndex = tappedIndex
        lastHapticDay = day
        
        // User tapped center - NOW load the data
        selectedDate = day
        pendingDate = nil // Clear pending since we're loading now
        onDateChanged(day) // Actually load data for this day
        
        // Animate scroll to tapped day with smooth spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            proxy.scrollTo(day, anchor: .center)
        }
        
        // Light haptic feedback for tap
        selectionGenerator?.selectionChanged()
        
        // Check if we need to recenter window
        recenterWindowIfNeeded(currentIndex: tappedIndex, proxy: proxy)
    }
    
    /// Combined scroll handler (replaces handleScrollOffset + triggerHapticOnDayChange)
    /// IMPROVED: More precise tracking using exact position calculations
    private func handleScrollOffset(value: CGFloat, slotWidth: CGFloat, proxy: ScrollViewProxy) {
        guard !isInitializing && isViewReady else { return }
        
        // Calculate which day is currently centered
        // The offset is negative when scrolling right, positive when scrolling left
        let offset = -value
        // Calculate the exact index (using floor for more reliable detection)
        let exactIndex = offset / slotWidth
        let currentIndex = Int(round(exactIndex))
        
        guard currentIndex >= 0 && currentIndex < visibleDays.count,
              let centeredDay = visibleDays[safe: currentIndex] else {
            return
        }
        
        // CRITICAL FIX: Check if we've crossed into a new day position
        // Use a more sensitive threshold to catch every day crossing
        if let lastIndex = lastHapticIndex {
            // Only trigger if we've actually moved to a different day
            if lastIndex != currentIndex {
                // Day changed - store pending date (DON'T update selectedDate during scroll to prevent jumping)
                pendingDate = centeredDay
                
                // Light haptic feedback for visual scrolling
                selectionGenerator?.selectionChanged() // Light haptic only
                
                // Re-prepare generators for next use (critical for rapid scrolling)
                impactGenerator?.prepare()
                selectionGenerator?.prepare()
                
                lastHapticIndex = currentIndex
                
                // Check if we need to recenter window (virtualization)
                recenterWindowIfNeeded(currentIndex: currentIndex, proxy: proxy)
            }
        } else {
            // First time - set initial values without haptic
            lastHapticIndex = currentIndex
            // Don't update selectedDate here - let it be set by initialization
        }
    }
    
    // MARK: - Helper Functions
    
    private func monthYearString(from date: Date) -> String {
        return Self.monthYearFormatter.string(from: date).uppercased()
    }
}

// MARK: - DayCell (Optimized with Static Formatter)

// MARK: - Preference Keys for Position Tracking
struct DayPosition: Equatable {
    let day: Date
    let midX: CGFloat
}

struct DayPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [DayPosition] = []
    
    static func reduce(value: inout [DayPosition], nextValue: () -> [DayPosition]) {
        value.append(contentsOf: nextValue())
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - DayCell with Haptic Detection
struct DayCellWithHaptic: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let width: CGFloat
    let screenWidth: CGFloat
    let onTap: () -> Void
    let onCenterCrossed: () -> Void
    
    var body: some View {
        DayCell(
            day: day,
            isToday: isToday,
            isSelected: isSelected,
            hasEvents: hasEvents,
            width: width,
            onTap: onTap
        )
        .background(
            // CRITICAL: Track this cell's position using GeometryReader
            // Use .global coordinate space to get absolute screen position
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: DayPositionPreferenceKey.self,
                        value: [DayPosition(
                            day: day,
                            midX: geo.frame(in: .global).midX
                        )]
                    )
            }
        )
    }
}

struct DayCell: View {
    @Environment(ThemeManager.self) private var themeManager
    
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let width: CGFloat
    let onTap: () -> Void
    
    // Static DateFormatter (created once, reused forever)
    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private let calendar = Calendar.current
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: 5) {
            Text(dayLabel)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(theme.textPrimary.opacity(0.7))
            
            ZStack {
                // Gradual transition: Show yellow ring for today ONLY if NOT selected
                // When selected, smoothly transition from yellow to green
                if isToday {
                    if isSelected {
                        // Today is selected - show green ring with smooth transition
                        Circle()
                            .stroke(Color.green.opacity(0.9), lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        // Today is not selected - show yellow ring
                        Circle()
                            .stroke(Color.yellow.opacity(0.9), lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                } else if isSelected {
                    // Selected day (not today) - show green ring with transition
                    Circle()
                        .stroke(Color.green.opacity(0.9), lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .shadow(color: theme.daySelectorCircleShadowColor, radius: theme.daySelectorCircleShadowRadius)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .shadow(color: theme.daySelectorTextShadowColor, radius: theme.daySelectorTextShadowRadius, x: theme.daySelectorTextShadowX, y: theme.daySelectorTextShadowY)
            }
            .frame(width: 32, height: 32)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
            .animation(.easeInOut(duration: 0.3), value: isToday)
            
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
        return Self.dayLabelFormatter.string(from: day)
    }
}

// MARK: - DayCenterController

struct DayCenterController: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(spacing: 5) {
            Text(" ")
                .font(.system(size: 9))
            
            Circle()
                .stroke(Color.green.opacity(0.9), lineWidth: 3)
                .frame(width: 32, height: 32)
                .shadow(color: themeManager.currentTheme.daySelectorCircleShadowColor, radius: themeManager.currentTheme.daySelectorCircleShadowRadius)
            
            Circle()
                .fill(Color.clear)
                .frame(width: 4, height: 4)
        }
    }
}

// MARK: - Array Safe Index Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
