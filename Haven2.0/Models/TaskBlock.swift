//
//  TaskBlock.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData

@Model
final class TaskBlock {
    var id: String
    var userID: String
    var title: String
    var blockDescription: String?
    var color: String
    var priority: PriorityType
    var isComplete: Bool
    var createdDate: Date
    var isLocked: Bool = false // New: For routine blocks that can't be moved
    var isRecurring: Bool = false
    var recurrenceSeriesID: String? // Link occurrences of a recurring block series
    
    // Relationship: Tasks inside this block (cascade delete = if Block deleted, Tasks deleted)
    @Relationship(deleteRule: .cascade, inverse: \Task.taskBlock)
    var tasks: [Task]? = []
    
    init(id: String = UUID().uuidString,
         userID: String,
         title: String,
         blockDescription: String? = nil,
         color: String = "blue",
         priority: PriorityType = .normal,
         isComplete: Bool = false) {
        self.id = id
        self.userID = userID
        self.title = title
        self.blockDescription = blockDescription
        self.color = color
        self.priority = priority
        self.isComplete = isComplete
        self.createdDate = Date()
    }
    
}
