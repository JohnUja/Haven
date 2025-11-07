//
//  InfiniteDaySelector.swift
//  TimeFlow
//
//  UIPickerWheel-style day selector with 7 fixed slots
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
    
    init(selectedDate: Binding<Date>, 
         onDateChanged: @escaping (Date) -> Void, 
         hasEvents: @escaping (Date) -> Bool,
         showMonthHeader: Bool = true) {
        self._selectedDate = selectedDate
        self.onDateChanged = onDateChanged
        self.hasEvents = hasEvents
        self.showMonthHeader = showMonthHeader
    }
    
    @State private var days: [Date] = []
    @State private var lastHapticDay: Date?
    @State private var lastHapticIndex: Int?
    @State private var isInitializing = false
    @State private var impactGenerator: UIImpactFeedbackGenerator? = UIImpactFeedbackGenerator(style: .rigid)
    @State private var selectionGenerator: UISelectionFeedbackGenerator? = UISelectionFeedbackGenerator()
    
    // Lazy loading constants
    private let initialLoadCount = 15 // Load 15 days on each side initially
    private let loadMoreThreshold = 5 // Load more when within 5 days of edge
    private let maxDaysToLoad = 30 // Maximum days to load on each side at once
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year Header - Conditionally shown
            if showMonthHeader {
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
            }
            
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
                                        // Update haptic tracking
                                        lastHapticIndex = index
                                        lastHapticDay = day
                                        
                                        selectedDate = day
                                        onDateChanged(day)
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                            proxy.scrollTo(index, anchor: .center)
                                        }
                                        // Haptic on tap - use time picker sound
                                        HapticSoundPlayer.shared.playTimePickerSound()
                                        
                                        // Check if we need to load more days
                                        checkAndLoadMoreDays(currentIndex: index)
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
            // Prepare haptic generator for immediate response
            impactGenerator?.prepare()
            selectionGenerator?.prepare()
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func initializeDays() {
        // Lazy loading: Start with only 15 days on each side of today
        let today = Date()
        loadDaysAround(date: today, range: initialLoadCount)
        selectedDate = today
    }
    
    // Lazy loading: Load days around a specific date
    private func loadDaysAround(date: Date, range: Int) {
        let newDays = (-range...range).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date)
        }
        
        // Merge with existing days, avoiding duplicates
        var daySet = Set(days.map { calendar.startOfDay(for: $0) })
        var mergedDays = days
        
        for newDay in newDays {
            let dayStart = calendar.startOfDay(for: newDay)
            if !daySet.contains(dayStart) {
                mergedDays.append(newDay)
                daySet.insert(dayStart)
            }
        }
        
        // Sort days
        days = mergedDays.sorted()
    }
    
    // Check if we need to load more days
    private func checkAndLoadMoreDays(currentIndex: Int) {
        let totalDays = days.count
        let distanceFromStart = currentIndex
        let distanceFromEnd = totalDays - currentIndex - 1
        
        // Load more if we're within threshold of the edge
        if distanceFromStart < loadMoreThreshold {
            if let firstDay = days.first {
                // Always load 15 more days before the first day
                loadDaysAround(date: firstDay, range: 15)
            }
        } else if distanceFromEnd < loadMoreThreshold {
            if let lastDay = days.last {
                // Always load 15 more days after the last day
                loadDaysAround(date: lastDay, range: 15)
            }
        }
    }
    
    private func initializePosition(proxy: ScrollViewProxy) {
        // Ensure days array is initialized
        guard !days.isEmpty else {
            // If days is empty, initialize it first
            initializeDays()
            // Wait a moment for days to be populated, then retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                initializePosition(proxy: proxy)
            }
            return
        }
        
        // Find today's index in the loaded days
        let today = calendar.startOfDay(for: Date())
        guard let todayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) else {
            // If today not found, find the closest day
            guard let closestDay = days.enumerated().min(by: { abs($0.element.timeIntervalSince(today)) < abs($1.element.timeIntervalSince(today)) }) else {
                // If no closest day found (shouldn't happen if days is not empty), use first day
                guard let firstDay = days.first else {
                    // Last resort: reinitialize
                    initializeDays()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        initializePosition(proxy: proxy)
                    }
                    return
                }
                isInitializing = true
                selectedDate = firstDay
                lastHapticDay = firstDay
                lastHapticIndex = 0
                onDateChanged(firstDay)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    proxy.scrollTo(0, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isInitializing = false
                    }
                }
                return
            }
            
            let closestIndex = closestDay.offset
            isInitializing = true
            selectedDate = days[closestIndex]
            lastHapticDay = days[closestIndex]
            lastHapticIndex = closestIndex
            onDateChanged(days[closestIndex])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                proxy.scrollTo(closestIndex, anchor: .center)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInitializing = false
                }
            }
            return
        }
        
        isInitializing = true
        selectedDate = days[todayIndex]
        lastHapticDay = days[todayIndex]
        lastHapticIndex = todayIndex
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
        // Find today's index in the loaded days
        let today = calendar.startOfDay(for: Date())
        guard let todayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) else {
            // If today not in loaded days, load it and reset
            loadDaysAround(date: today, range: initialLoadCount)
            if let newTodayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) {
                isInitializing = true
                selectedDate = days[newTodayIndex]
                lastHapticDay = days[newTodayIndex]
                lastHapticIndex = newTodayIndex
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(newTodayIndex, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isInitializing = false
                    }
                }
            }
            return
        }
        
        isInitializing = true
        selectedDate = days[todayIndex]
        lastHapticDay = days[todayIndex]
        lastHapticIndex = todayIndex
        
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
        
        // CRITICAL FIX: Play haptic feedback on EVERY index change
        // This ensures if user swipes 20 days, they hear feedback 20 times
        if let lastIndex = lastHapticIndex, lastIndex != index {
            // Position changed - play feedback IMMEDIATELY (no delay)
            HapticSoundPlayer.shared.playTimePickerSound()
            
            lastHapticIndex = index
            lastHapticDay = centeredDay
            selectedDate = centeredDay
            onDateChanged(centeredDay)
            
            // Check if we need to load more days (lazy loading)
            checkAndLoadMoreDays(currentIndex: index)
        } else if lastHapticIndex == nil {
            // First time - set initial values
            lastHapticIndex = index
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
                // Gradual transition: Show yellow ring for today ONLY if NOT selected
                // When selected, smoothly transition from yellow to green
                if isToday {
                    if isSelected {
                        // Today is selected - show green ring with smooth transition
                        Circle()
                            .stroke(Color.green.opacity(0.9), lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .shadow(color: .green.opacity(0.5), radius: 5)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        // Today is not selected - show yellow ring
                        Circle()
                            .stroke(Color.yellow.opacity(0.9), lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .shadow(color: .yellow.opacity(0.3), radius: 3)
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
                        .shadow(color: .green.opacity(0.5), radius: 5)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
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
