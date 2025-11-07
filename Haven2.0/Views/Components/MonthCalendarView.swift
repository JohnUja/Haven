//
//  MonthCalendarView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
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
                        .foregroundColor(.primary)
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
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
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
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
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
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(height: 60) // Fixed height to prevent shifting
            .background(Color(.systemGray6))
            .onAppear {
                // Sync calendar month with selected date when view appears
                currentMonth = selectedDate
            }
            .onChange(of: selectedDate) { _, newDate in
                // Sync calendar month when selectedDate changes from day scroller
                let calendar = Calendar.current
                if !calendar.isDate(newDate, equalTo: currentMonth, toGranularity: .month) {
                    currentMonth = newDate
                }
            }
            
            // Days of week header - Fixed height
            HStack {
                ForEach(dayOfWeekHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
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
                                .font(.subheadline)
                                .fontWeight(.medium)
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
        .onAppear {
            // Sync calendar month with selected date
            currentMonth = selectedDate
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update calendar month when selectedDate changes externally
            let newMonth = calendar.date(bySetting: .day, value: 1, of: newDate) ?? newDate
            if !calendar.isDate(newMonth, equalTo: currentMonth, toGranularity: .month) {
                withAnimation {
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
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return .white
        } else if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            return .primary
        } else {
            return .secondary
        }
    }
    
    @ViewBuilder
    private func backgroundForDate(_ date: Date) -> some View {
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else if calendar.isDate(date, inSameDayAs: Date()) {
            Circle()
                .stroke(Color.purple, lineWidth: 2)
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
