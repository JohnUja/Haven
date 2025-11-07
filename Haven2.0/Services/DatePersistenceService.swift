//
//  DatePersistenceService.swift
//  Haven2.0
//
//  Created by AI on 2025-01-13.
//

import Foundation

/// Service to persist and restore the selected date across app launches
@MainActor
class DatePersistenceService {
    static let shared = DatePersistenceService()
    
    private let selectedDateKey = "lastSelectedDate"
    private let lastWorkedDateKey = "lastWorkedDate" // Date where user last created a task
    
    private init() {}
    
    // MARK: - Save Selected Date
    func saveSelectedDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: selectedDateKey)
    }
    
    // MARK: - Restore Selected Date
    func restoreSelectedDate() -> Date? {
        guard let date = UserDefaults.standard.object(forKey: selectedDateKey) as? Date else {
            return nil
        }
        
        // Only restore if it's within a reasonable range (not too far in past/future)
        let calendar = Calendar.current
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        
        // Restore if within 365 days (1 year) range
        if abs(daysDifference) <= 365 {
            return date
        }
        
        return nil
    }
    
    // MARK: - Save Last Worked Date (when task is created on future date)
    func saveLastWorkedDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastWorkedDateKey)
    }
    
    // MARK: - Restore Last Worked Date
    func restoreLastWorkedDate() -> Date? {
        guard let date = UserDefaults.standard.object(forKey: lastWorkedDateKey) as? Date else {
            return nil
        }
        
        // Only restore if it's within a reasonable range
        let calendar = Calendar.current
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        
        // Restore if within 365 days range
        if abs(daysDifference) <= 365 {
            return date
        }
        
        return nil
    }
    
    // MARK: - Clear All Dates (for testing)
    func clearAllDates() {
        UserDefaults.standard.removeObject(forKey: selectedDateKey)
        UserDefaults.standard.removeObject(forKey: lastWorkedDateKey)
    }
}

