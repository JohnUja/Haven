//
//  CalendarManager.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-21.
//

import Foundation
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var isAuthorized = false
    @Published var calendarEvents: [EKEvent] = []
    @Published var isLoading = false
    
    private let eventStore = EKEventStore()
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess:
            isAuthorized = true
            loadCalendarEvents()
        case .notDetermined:
            requestAccess()
        case .denied, .restricted, .writeOnly:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAccess(completion: ((Bool) -> Void)? = nil) {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.isAuthorized = true
                    self?.loadCalendarEvents()
                } else {
                    self?.isAuthorized = false
                    if let error = error {
                        print("Calendar access denied: \(error)")
                    }
                }
                completion?(granted)
            }
        }
    }
    
    func loadCalendarEvents(for date: Date = Date()) {
        guard isAuthorized else { return }
        
        isLoading = true
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let events = self?.eventStore.events(matching: predicate) ?? []
            
            DispatchQueue.main.async {
                self?.calendarEvents = events
                self?.isLoading = false
            }
        }
    }
    
    func getEventsForDate(_ date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return calendarEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date) ||
            calendar.isDate(event.endDate, inSameDayAs: date) ||
            (event.startDate <= date && event.endDate >= date)
        }
    }
    
    func hasEventsOnDate(_ date: Date) -> Bool {
        !getEventsForDate(date).isEmpty
    }
    
    func getEventCountForDate(_ date: Date) -> Int {
        getEventsForDate(date).count
    }
    
    // MARK: - Add Task to Calendar
    func addTaskToCalendar(task: Task) {
        guard isAuthorized else {
            requestAccess()
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = task.startTime
        event.endDate = task.endTime
        event.notes = task.taskDescription
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Task added to calendar: \(task.title)")
        } catch {
            print("Failed to add task to calendar: \(error)")
        }
    }
    
    // MARK: - Sync Task with Calendar
    func syncTaskWithCalendar(task: Task) {
        guard isAuthorized else {
            requestAccess()
            return
        }
        
        // Find existing event or create new one
        let predicate = eventStore.predicateForEvents(
            withStart: task.startTime.addingTimeInterval(-3600),
            end: task.endTime.addingTimeInterval(3600),
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
        
        if let existingEvent = events.first(where: { $0.title == task.title }) {
            // Update existing event
            existingEvent.startDate = task.startTime
            existingEvent.endDate = task.endTime
            existingEvent.notes = task.taskDescription
            
            do {
                try eventStore.save(existingEvent, span: .thisEvent)
                print("Task synced with calendar: \(task.title)")
            } catch {
                print("Failed to sync task with calendar: \(error)")
            }
        } else {
            // Create new event
            addTaskToCalendar(task: task)
        }
    }
}
