//
//  NumericTimeInput.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI

struct NumericTimeInput: View {
    @Binding var time: Date
    let title: String
    let isEnabled: Bool
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var selectedHour = 1
    @State private var selectedMinute = 0
    @State private var isAM = true
    @State private var availableHours: [Int] = Array(1...12)
    @State private var availableMinutes: [Int] = Array(0...59)
    
    init(time: Binding<Date>, title: String, isEnabled: Bool = true) {
        self._time = time
        self.title = title
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: 8) {
            // Title with lighter font weight to match section labels
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: 12) {
                // Wheel picker for hours and minutes
                HStack(spacing: 4) {
                    Picker("", selection: $selectedHour) {
                        ForEach(availableHours, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(theme.textPrimary)
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60, height: 100)
                    .clipped()
                    .disabled(!isEnabled)
                    .onChange(of: selectedHour) { _, _ in
                        updateTimeFromSelection()
                        updateAvailableMinutes()
                    }
                    
                    Text(":")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.textPrimary)
                    
                    Picker("", selection: $selectedMinute) {
                        ForEach(availableMinutes, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(theme.textPrimary)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60, height: 100)
                    .clipped()
                    .disabled(!isEnabled)
                    .onChange(of: selectedMinute) { _, _ in
                        updateTimeFromSelection()
                    }
                }
                
                // AM/PM toggle
                Picker("AM/PM", selection: $isAM) {
                    Text("AM")
                        .foregroundColor(theme.id == "dark" ? .white : theme.textPrimary)
                        .tag(true)
                    Text("PM")
                        .foregroundColor(theme.id == "dark" ? .white : theme.textPrimary)
                        .tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .tint(theme.accentColor)
                .disabled(!isEnabled)
                .onChange(of: isAM) { _, _ in
                    updateTimeFromSelection()
                    updateAvailableMinutes()
                }
            }
        }
        .onAppear {
            updateDisplayFromTime()
            updateAvailableMinutes()
        }
        .onChange(of: time) { _, _ in
            updateDisplayFromTime()
            updateAvailableMinutes()
        }
    }
    
    private func updateTimeFromSelection() {
        // Convert to 24-hour format
        var hour24 = selectedHour
        if !isAM && selectedHour != 12 {
            hour24 = selectedHour + 12
        } else if isAM && selectedHour == 12 {
            hour24 = 0
        }
        
        // Create new date with the time
        let calendar = Calendar.current
        if let newDate = calendar.date(bySettingHour: hour24, minute: selectedMinute, second: 0, of: time) {
            // Smart time validation
            if let validatedDate = validateTime(newDate) {
                time = validatedDate
            }
        }
    }
    
    private func updateDisplayFromTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Convert to 12-hour format
        var hour12 = hour
        if hour == 0 {
            hour12 = 12
        } else if hour > 12 {
            hour12 = hour - 12
        }
        
        selectedHour = hour12
        selectedMinute = minute
        isAM = hour < 12
    }
    
    private func validateTime(_ date: Date) -> Date? {
        let now = Date()
        let calendar = Calendar.current
        
        // Only validate if it's today
        guard calendar.isDate(date, inSameDayAs: now) else {
            return date
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentHour = components.hour ?? 0
        let currentMinute = components.minute ?? 0
        
        let dateComponents = calendar.dateComponents([.hour, .minute], from: date)
        let dateHour = dateComponents.hour ?? 0
        let dateMinute = dateComponents.minute ?? 0
        
        // Check if the selected time is in the past
        if dateHour < currentHour || (dateHour == currentHour && dateMinute < currentMinute) {
            // Round to nearest hour
            let nextHour = currentHour + 1
            return calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: date)
        }
        
        return date
    }
    
    private func updateAvailableMinutes() {
        let now = Date()
        let calendar = Calendar.current
        
        // Only restrict if it's today
        guard calendar.isDate(time, inSameDayAs: now) else {
            availableMinutes = Array(0...59)
            return
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentHour = components.hour ?? 0
        let currentMinute = components.minute ?? 0
        
        // Convert selected hour to 24-hour format
        var hour24 = selectedHour
        if !isAM && selectedHour != 12 {
            hour24 = selectedHour + 12
        } else if isAM && selectedHour == 12 {
            hour24 = 0
        }
        
        // If selected hour matches current hour, restrict minutes
        if hour24 == currentHour {
            availableMinutes = Array(currentMinute...59)
        } else {
            availableMinutes = Array(0...59)
        }
    }
}

#Preview {
    VStack {
        NumericTimeInput(time: .constant(Date()), title: "Start Time")
        NumericTimeInput(time: .constant(Date().addingTimeInterval(3600)), title: "End Time")
    }
    .padding()
}
