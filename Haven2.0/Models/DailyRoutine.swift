//
//  DailyRoutine.swift
//  Haven2.0
//
//  Created by John Uja on 2025-11-03.
//

import Foundation
import SwiftData

// MARK: - Routine Duration Type
enum RoutineDurationType: String, Codable {
    case tillMonthEnd = "tillMonthEnd"
    case days = "days"
}

// MARK: - Routine Task Template
struct RoutineTaskTemplate: Codable, Identifiable {
    var id: String
    var title: String
    var description: String?
    var timeOfDay: String // "HH:mm" format (e.g., "08:00", "12:30")
    var durationMinutes: Int
    var priority: PriorityType
    var category: TaskCategory
    var hasDefaultNotifications: Bool // For sleep/eat defaults
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String? = nil,
         timeOfDay: String,
         durationMinutes: Int,
         priority: PriorityType = .normal,
         category: TaskCategory = .personal,
         hasDefaultNotifications: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.timeOfDay = timeOfDay
        self.durationMinutes = durationMinutes
        self.priority = priority
        self.category = category
        self.hasDefaultNotifications = hasDefaultNotifications
    }
}

// MARK: - Daily Routine Model
@Model
final class DailyRoutine {
    var id: String
    var userID: String
    var title: String // e.g., "My Daily Essentials"
    var isActive: Bool
    var isDefault: Bool // true for sleep/eat defaults
    
    // Duration Type
    var durationTypeRaw: String // "tillMonthEnd" or "days"
    var durationDays: Int? // If "days", how many (30, 45, 60, etc.)
    var startDate: Date
    var endDate: Date? // Calculated: startDate + duration
    
    // Task Templates (LIGHTWEIGHT - JSON-encoded array)
    var taskTemplatesJSON: Data? // JSON-encoded [RoutineTaskTemplate]
    
    // Notifications
    var notificationEnabled: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date? // After routine expires + 30 day grace period
    
    // Computed property for easy access (non-persisted)
    var taskTemplates: [RoutineTaskTemplate] {
        get {
            guard let data = taskTemplatesJSON,
                  let templates = try? JSONDecoder().decode([RoutineTaskTemplate].self, from: data) else {
                return []
            }
            return templates
        }
        set {
            taskTemplatesJSON = try? JSONEncoder().encode(newValue)
        }
    }
    
    var durationType: RoutineDurationType {
        get {
            RoutineDurationType(rawValue: durationTypeRaw) ?? .days
        }
        set {
            durationTypeRaw = newValue.rawValue
        }
    }
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         isActive: Bool = true,
         isDefault: Bool = false,
         durationType: RoutineDurationType,
         durationDays: Int? = nil,
         startDate: Date = Date(),
         taskTemplates: [RoutineTaskTemplate] = [],
         notificationEnabled: Bool = true) {
        self.id = id
        self.userID = userID
        self.title = title
        self.isActive = isActive
        self.isDefault = isDefault
        self.durationTypeRaw = durationType.rawValue
        self.durationDays = durationDays
        self.startDate = startDate
        
        // Calculate endDate
        let calendar = Calendar.current
        if durationType == .tillMonthEnd {
            if let monthEnd = calendar.dateInterval(of: .month, for: startDate)?.end {
                self.endDate = calendar.date(byAdding: .day, value: -1, to: monthEnd)
            }
        } else if let days = durationDays {
            self.endDate = calendar.date(byAdding: .day, value: days, to: startDate)
        }
        
        // Encode templates as JSON
        self.taskTemplatesJSON = try? JSONEncoder().encode(taskTemplates)
        self.notificationEnabled = notificationEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

