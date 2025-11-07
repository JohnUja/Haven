//
//  GoalProgressUpdater.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

enum GoalProgressUpdater {
    static func handleTaskToggle(_ task: Task, context: ModelContext, goals: [Goal]) {
        guard let goalID = task.goalID,
              let goal = goals.first(where: { $0.id == goalID }) else { return }

        // Get all tasks for this goal to calculate effective target
        let allTasks = try? context.fetch(FetchDescriptor<Task>())
        let goalTasks = allTasks?.filter { $0.goalID == goalID } ?? []
        let effectiveTarget = goal.effectiveTargetValue(tasks: goalTasks)
        
        // Use effective target if > 0, otherwise fall back to stored targetValue
        let target = effectiveTarget > 0 ? effectiveTarget : goal.targetValue
        
        if task.isComplete {
            goal.currentValue = min(goal.currentValue + 1, target)
        } else {
            goal.currentValue = max(goal.currentValue - 1, 0)
        }

        // Update status based on effective target
        if goal.currentValue >= target && target > 0 {
            goal.status = .completed
        } else if goal.status == .completed && target > 0 {
            goal.status = .active
        }

        try? context.save()
    }
    
    // Sync targetValue from linked tasks (call when tasks are added/removed)
    static func syncTargetValue(for goal: Goal, context: ModelContext) {
        let allTasks = try? context.fetch(FetchDescriptor<Task>())
        let effectiveTarget = goal.effectiveTargetValue(tasks: allTasks ?? [])
        if effectiveTarget > 0 {
            goal.targetValue = effectiveTarget
        }
        try? context.save()
    }
}


