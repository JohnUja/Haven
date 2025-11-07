//
//  GuestModeService.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import Foundation
import SwiftUI

// MARK: - Guest Mode Service
@MainActor
class GuestModeService: ObservableObject {
    static let shared = GuestModeService()
    
    @Published var taskCount: Int = 0
    
    private let taskCountKey = "guest_task_count"
    
    private init() {
        loadTaskCount()
    }
    
    // MARK: - Load Task Count
    private func loadTaskCount() {
        taskCount = UserDefaults.standard.integer(forKey: taskCountKey)
    }
    
    // MARK: - Increment Task Count
    func incrementTaskCount() {
        taskCount += 1
        UserDefaults.standard.set(taskCount, forKey: taskCountKey)
    }
    
    // MARK: - Reset Task Count
    func resetTaskCount() {
        taskCount = 0
        UserDefaults.standard.removeObject(forKey: taskCountKey)
    }
    
    // MARK: - Check If Can Create Task
    func canCreateTask() -> Bool {
        return taskCount < 1
    }
    
    // MARK: - Check If Should Show Login Prompt
    func shouldShowLoginPrompt() -> Bool {
        return taskCount >= 1
    }
}

