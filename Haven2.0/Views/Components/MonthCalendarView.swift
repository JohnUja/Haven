//
//  MonthCalendarView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(ThemeManager.self) private var themeManager
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        let theme = themeManager.currentTheme
        VStack(spacing: 0) {
            // Month/Year Navigation Header - Fixed height
            HStack {
                // Previous month button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(theme.textPrimary)
                        .padding(8)
                }
                
                Spacer()
                
                // Month/Year Display with navigation
                VStack(spacing: 4) {
                    // Year picker (tap to change year)
                    Menu {
                        let currentYear = calendar.component(.year, from: currentMonth)
                        ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { year in
                            Button("\(year)") {
                                if let newDate = calendar.date(bySetting: .year, value: year, of: currentMonth) {
                                    withAnimation {
                                        currentMonth = newDate
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(calendar.component(.year, from: currentMonth).description)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    // Month picker (tap to change month)
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button(monthName(for: month)) {
                                if let newDate = calendar.date(bySetting: .month, value: month, of: currentMonth) {
                                    withAnimation {
                                        currentMonth = newDate
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(monthName(for: calendar.component(.month, from: currentMonth)))
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }
                }
                
                Spacer()
                
                // Next month button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(theme.textPrimary)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(height: 60) // Fixed height to prevent shifting
            // Background removed - will use parent's cohesive background
            
            // Days of week header - Fixed height
            HStack {
                ForEach(dayOfWeekHeaders, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(height: 30) // Fixed height
            
            // Calendar grid - Fixed height
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        Button(action: { 
                            selectedDate = date
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(textColor(for: date))
                                .frame(width: 32, height: 32)
                                .background(backgroundForDate(date))
                        }
                        .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1.0 : 0.3)
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .frame(height: 240) // Fixed height for grid (6 rows * 40px)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .background(themeManager.currentTheme.primaryGradient.ignoresSafeArea())
        .onAppear {
            // Sync calendar month with selected date only once on appear
            if !calendar.isDate(currentMonth, equalTo: selectedDate, toGranularity: .month) {
            currentMonth = selectedDate
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Update calendar month when selectedDate changes externally
            let newMonth = calendar.date(bySetting: .day, value: 1, of: newValue) ?? newValue
            if !calendar.isDate(newMonth, equalTo: currentMonth, toGranularity: .month) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentMonth = newMonth
                }
            }
        }
    }
    
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        if let date = calendar.date(bySetting: .month, value: month, of: Date()) {
            return formatter.string(from: date)
        }
        return "Month"
    }
    
    private var dayOfWeekHeaders: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private var calendarDays: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        let endOfCalendar = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth
        
        var days: [Date?] = []
        var currentDate = startOfCalendar
        
        while currentDate < endOfCalendar {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func textColor(for date: Date) -> Color {
        let theme = themeManager.currentTheme
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return theme.textPrimary
        } else if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            return theme.textPrimary
        } else {
            return theme.textSecondary
        }
    }
    
    @ViewBuilder
    private func backgroundForDate(_ date: Date) -> some View {
        let theme = themeManager.currentTheme
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            Circle()
                .stroke(theme.accentColor, lineWidth: 2)
                .background(Circle().fill(Color.clear))
        } else if calendar.isDate(date, inSameDayAs: Date()) {
            Circle()
                .stroke(theme.glassBorder.opacity(0.8), lineWidth: 1)
                .background(Circle().fill(Color.clear))
        } else {
            Circle()
                .fill(Color.clear)
        }
    }
}

#Preview {
    MonthCalendarView(selectedDate: .constant(Date()))
}
