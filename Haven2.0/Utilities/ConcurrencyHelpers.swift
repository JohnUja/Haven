//
//  ConcurrencyHelpers.swift
//  Haven2.0
//
//  Created by John Uja on 2025-11-03.
//  Helper to avoid SwiftData Task model conflict with Swift's concurrency Task
//

import Foundation

// Explicitly use _Concurrency.Task to avoid SwiftData Task conflict
typealias ConcurrencyTask = _Concurrency.Task

// Helper to create Swift's concurrency Task (avoiding SwiftData Task conflict)
// Now supports throwing functions - uses _Concurrency.Task explicitly
func _createConcurrencyTask(_ body: @escaping @MainActor () async throws -> Void) {
    // Explicitly use _Concurrency.Task to avoid SwiftData Task model conflict
    ConcurrencyTask { @MainActor in
        do {
            try await body()
        } catch {
            // Silently handle errors in fire-and-forget tasks
            print("ConcurrencyHelpers: Background task error: \(error)")
        }
    }
}

// Helper for non-MainActor async tasks that can throw
func _createConcurrencyTaskAsync(_ body: @escaping () async throws -> Void) {
    // Explicitly use _Concurrency.Task to avoid SwiftData Task model conflict
    ConcurrencyTask {
        do {
            try await body()
        } catch {
            // Silently handle errors in fire-and-forget tasks
            print("ConcurrencyHelpers: Background task error: \(error)")
        }
    }
}

