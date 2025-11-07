//
//  RoutineService.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import Foundation
import SwiftData

// MARK: - Routine Service
class RoutineService {
    static let shared = RoutineService()
    
    private init() {}
    
    // MARK: - Generate Tasks from Routine (Pre-Generation Strategy)
    func generateTasksFromRoutine(_ routine: DailyRoutine, in context: ModelContext) {
        let calendar = Calendar.current
        var currentDate = routine.startDate
        let endDate = routine.endDate ?? calendar.date(byAdding: .day, value: 30, to: routine.startDate) ?? routine.startDate
        
        // Generate all tasks upfront (in background)
        var tasksToInsert: [Task] = []
        
        while currentDate <= endDate {
            for template in routine.taskTemplates {
                // Combine date with time
                let timeComponents = template.timeOfDay.split(separator: ":")
                guard let hour = Int(timeComponents[0]),
                      let minute = Int(timeComponents[1]) else { continue }
                
                let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: currentDate) ?? currentDate
                let endTime = calendar.date(byAdding: .minute, value: template.durationMinutes, to: startTime) ?? startTime
                
                let task = Task(
                    userID: routine.userID,
                    title: template.title,
                    taskDescription: template.description,
                    startTime: startTime,
                    endTime: endTime,
                    priority: template.priority,
                    category: template.category,
                    isRoutineTask: true,
                    routineID: routine.id
                )
                
                tasksToInsert.append(task)
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Batch insert (efficient)
        for task in tasksToInsert {
            context.insert(task)
        }
        
        // Save once
        try? context.save()
    }
    
    // MARK: - Create Default Routines (Sleep, Eat)
    func createDefaultRoutines(userID: String, in context: ModelContext) -> [DailyRoutine] {
        var routines: [DailyRoutine] = []
        
        // Sleep routine (10 PM - 7 AM)
        let sleepTemplate = RoutineTaskTemplate(
            title: "Sleep",
            description: "Good night's rest",
            timeOfDay: "22:00",
            durationMinutes: 540, // 9 hours
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        )
        
        let sleepRoutine = DailyRoutine(
            userID: userID,
            title: "Sleep",
            isActive: true,
            isDefault: true,
            durationType: .tillMonthEnd,
            startDate: Date(),
            taskTemplates: [sleepTemplate],
            notificationEnabled: true
        )
        context.insert(sleepRoutine)
        routines.append(sleepRoutine)
        
        // Breakfast routine (8 AM)
        let breakfastTemplate = RoutineTaskTemplate(
            title: "Eat Breakfast",
            description: "Morning meal",
            timeOfDay: "08:00",
            durationMinutes: 30,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        )
        
        let breakfastRoutine = DailyRoutine(
            userID: userID,
            title: "Breakfast",
            isActive: true,
            isDefault: true,
            durationType: .tillMonthEnd,
            startDate: Date(),
            taskTemplates: [breakfastTemplate],
            notificationEnabled: true
        )
        context.insert(breakfastRoutine)
        routines.append(breakfastRoutine)
        
        // Lunch routine (12 PM)
        let lunchTemplate = RoutineTaskTemplate(
            title: "Eat Lunch",
            description: "Midday meal",
            timeOfDay: "12:00",
            durationMinutes: 30,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        )
        
        let lunchRoutine = DailyRoutine(
            userID: userID,
            title: "Lunch",
            isActive: true,
            isDefault: true,
            durationType: .tillMonthEnd,
            startDate: Date(),
            taskTemplates: [lunchTemplate],
            notificationEnabled: true
        )
        context.insert(lunchRoutine)
        routines.append(lunchRoutine)
        
        // Dinner routine (6 PM)
        let dinnerTemplate = RoutineTaskTemplate(
            title: "Eat Dinner",
            description: "Evening meal",
            timeOfDay: "18:00",
            durationMinutes: 45,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        )
        
        let dinnerRoutine = DailyRoutine(
            userID: userID,
            title: "Dinner",
            isActive: true,
            isDefault: true,
            durationType: .tillMonthEnd,
            startDate: Date(),
            taskTemplates: [dinnerTemplate],
            notificationEnabled: true
        )
        context.insert(dinnerRoutine)
        routines.append(dinnerRoutine)
        
        // Save all routines
        try? context.save()
        
        // Generate tasks for all routines
        for routine in routines {
            generateTasksFromRoutine(routine, in: context)
        }
        
        return routines
    }
    
    // MARK: - Archive Expired Routines
    func archiveExpiredRoutines(in context: ModelContext) {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.isActive == true &&
                routine.endDate != nil &&
                routine.endDate! < thirtyDaysAgo &&
                routine.archivedAt == nil
            }
        )
        
        guard let expiredRoutines = try? context.fetch(descriptor) else { return }
        
        for routine in expiredRoutines {
            // Mark routine as archived
            routine.archivedAt = Date()
            routine.isActive = false
            
            // Archive all tasks from this routine
            // Extract routine.id to a constant to use in predicate
            let routineID = routine.id
            let taskDescriptor = FetchDescriptor<Task>(
                predicate: #Predicate<Task> { task in
                    task.routineID == routineID
                }
            )
            
            // Fetch tasks (even if not used, this validates the predicate)
            _ = try? context.fetch(taskDescriptor)
            // Note: Task model doesn't have archived flag yet, but can add later
            // For now, just mark routine as inactive
        }
        
        try? context.save()
    }
    
    // MARK: - Get Active Routines for User
    func getActiveRoutines(userID: String, in context: ModelContext) -> [DailyRoutine] {
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.userID == userID && routine.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Get All Routines for User (Including Archived)
    func getAllRoutines(userID: String, in context: ModelContext) -> [DailyRoutine] {
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.userID == userID
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
}

