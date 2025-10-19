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
            // Days of week header
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
            .padding(.bottom, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        Button(action: { selectedDate = date }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(textColor(for: date))
                                .frame(width: 32, height: 32)
                                .background(backgroundForDate(date))
                        }
                        .disabled(!calendar.isDate(date, equalTo: currentMonth, toGranularity: .month))
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
        }
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
