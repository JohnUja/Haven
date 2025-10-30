//
//  RecurrenceUtilities.swift
//  Haven2.0
//
//  Helpers for bulk operations on recurring series
//

import Foundation
import SwiftData

func lockSeriesTasks(seriesID: String, lock: Bool, modelContext: ModelContext) {
    do {
        let descriptor = FetchDescriptor<Task>()
        let tasks = try modelContext.fetch(descriptor)
        tasks.filter { $0.recurrenceSeriesID == seriesID }.forEach { $0.isLocked = lock }
        try modelContext.save()
    } catch {
        print("Failed to lock series tasks: \(error)")
    }
}

func lockSeriesBlocks(seriesID: String, lock: Bool, modelContext: ModelContext) {
    do {
        let descriptor = FetchDescriptor<TaskBlock>()
        let blocks = try modelContext.fetch(descriptor)
        blocks.filter { $0.recurrenceSeriesID == seriesID }.forEach { $0.isLocked = lock }
        try modelContext.save()
    } catch {
        print("Failed to lock series blocks: \(error)")
    }
}


