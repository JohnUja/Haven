//
//  TimeSettingsView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-21.
//

import SwiftUI

struct TimeSettingsView: View {
    @StateObject private var timeSettings = TimeSettingsManager()
    @State private var showingTimezonePicker = false
    
    private let commonTimezones = [
        TimeZone(identifier: "America/New_York")!,      // EST/EDT
        TimeZone(identifier: "America/Chicago")!,        // CST/CDT
        TimeZone(identifier: "America/Denver")!,         // MST/MDT
        TimeZone(identifier: "America/Los_Angeles")!,   // PST/PDT
        TimeZone(identifier: "Europe/London")!,          // GMT/BST
        TimeZone(identifier: "Europe/Paris")!,           // CET/CEST
        TimeZone(identifier: "Asia/Tokyo")!,             // JST
        TimeZone(identifier: "Asia/Shanghai")!,          // CST
        TimeZone(identifier: "Australia/Sydney")!,       // AEST/AEDT
        TimeZone.current                                 // Device timezone
    ]
    
    var body: some View {
        List {
            Section("Time Format") {
                HStack {
                    Text("24-Hour Format")
                    Spacer()
                    Toggle("", isOn: $timeSettings.use24HourFormat)
                        .onChange(of: timeSettings.use24HourFormat) { _, _ in
                            timeSettings.toggleTimeFormat()
                        }
                }
                
                Text("Currently showing: \(timeSettings.use24HourFormat ? "24:00" : "12:00 AM")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Timezone") {
                HStack {
                    Text("Current Timezone")
                    Spacer()
                    Text(timeSettings.timezone.localizedName(for: .standard, locale: Locale.current) ?? timeSettings.timezone.identifier)
                        .foregroundColor(.secondary)
                }
                
                Button("Change Timezone") {
                    showingTimezonePicker = true
                }
                
                Text("Current time: \(timeSettings.formatTime(Date()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Device Settings") {
                HStack {
                    Text("Use Device Timezone")
                    Spacer()
                    Button("Reset") {
                        timeSettings.setTimezone(TimeZone.current)
                    }
                    .foregroundColor(.blue)
                }
                
                Text("Device timezone: \(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? TimeZone.current.identifier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Time Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimezonePicker) {
            TimezonePickerView(selectedTimezone: $timeSettings.timezone)
        }
    }
}

struct TimezonePickerView: View {
    @Binding var selectedTimezone: TimeZone
    @Environment(\.dismiss) private var dismiss
    
    private let commonTimezones = [
        TimeZone(identifier: "America/New_York")!,      // EST/EDT
        TimeZone(identifier: "America/Chicago")!,        // CST/CDT
        TimeZone(identifier: "America/Denver")!,         // MST/MDT
        TimeZone(identifier: "America/Los_Angeles")!,   // PST/PDT
        TimeZone(identifier: "Europe/London")!,          // GMT/BST
        TimeZone(identifier: "Europe/Paris")!,           // CET/CEST
        TimeZone(identifier: "Asia/Tokyo")!,             // JST
        TimeZone(identifier: "Asia/Shanghai")!,          // CST
        TimeZone(identifier: "Australia/Sydney")!,       // AEST/AEDT
        TimeZone.current                                 // Device timezone
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(commonTimezones, id: \.identifier) { timezone in
                    Button(action: {
                        selectedTimezone = timezone
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(timezone.localizedName(for: .standard, locale: Locale.current) ?? timezone.identifier)
                                    .foregroundColor(.primary)
                                
                                Text(timezone.identifier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if timezone.identifier == selectedTimezone.identifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimeSettingsView()
}

