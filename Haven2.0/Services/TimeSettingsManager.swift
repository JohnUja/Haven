//
//  TimeSettingsManager.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-21.
//

import Foundation
import SwiftUI

class TimeSettingsManager: ObservableObject {
    @Published var use24HourFormat: Bool = true
    @Published var timezone: TimeZone = TimeZone.current
    
    init() {
        // Load from UserDefaults
        loadSettings()
    }
    
    private func loadSettings() {
        use24HourFormat = UserDefaults.standard.bool(forKey: "use24HourFormat")
        if let timezoneIdentifier = UserDefaults.standard.string(forKey: "timezone") {
            timezone = TimeZone(identifier: timezoneIdentifier) ?? TimeZone.current
        }
    }
    
    func toggleTimeFormat() {
        // Don't toggle here - value is already set by the binding
        // Just save to UserDefaults
        UserDefaults.standard.set(use24HourFormat, forKey: "use24HourFormat")
        // Force UI update
        objectWillChange.send()
    }
    
    func setTimezone(_ newTimezone: TimeZone) {
        timezone = newTimezone
        UserDefaults.standard.set(newTimezone.identifier, forKey: "timezone")
    }

    // Popup appearance uses default system styling (white) with no setting
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        
        if use24HourFormat {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    func formatTimeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        
        if use24HourFormat {
            formatter.dateFormat = "HH:mm:ss"
        } else {
            formatter.dateFormat = "h:mm:ss a"
        }
        
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        
        if use24HourFormat {
            formatter.dateFormat = "MMM d, HH:mm"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    func formatHour(_ hour: Int) -> String {
        if use24HourFormat {
            return String(format: "%02d:00", hour)
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let ampm = hour < 12 ? "AM" : "PM"
            return String(format: "%d:00 %@", displayHour, ampm)
        }
    }
}

