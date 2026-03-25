//
//  GoalProgressUpdater.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-30.
//

import Foundation
import SwiftData

// Freeze-investigation logging was intentionally disabled after the audit cleanup.
@inline(__always)
fileprivate func debugLog(location: String, message: String, data: [String: Any] = [:], hypothesisId: String = "") {}

enum GoalProgressUpdater {
    static func handleTaskToggle(_ task: Task, context: ModelContext, goals: [Goal]) {
        // #region agent log
        let updateStartTime = Date()
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "handleTaskToggle started", data: ["taskId": task.id, "taskIsComplete": task.isComplete, "hasGoal": task.goal != nil] as [String: Any], hypothesisId: "G")
        // #endregion
        
        guard let goal = task.goal else {
            // #region agent log
            debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Task has no goal, returning", data: ["taskId": task.id] as [String: Any], hypothesisId: "G")
            // #endregion
            return
        }

        // #region agent log
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Processing goal update", data: ["taskId": task.id, "goalId": goal.id, "goalTitle": goal.title, "currentValue": goal.currentValue, "targetValue": goal.targetValue, "status": goal.status.rawValue] as [String: Any], hypothesisId: "G")
        // #endregion

        // Get all tasks for this goal to calculate effective target
        let goalTasks = goal.tasks ?? []
        // #region agent log
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Goal tasks retrieved", data: ["goalId": goal.id, "goalTasksCount": goalTasks.count] as [String: Any], hypothesisId: "G")
        // #endregion
        
        // #region agent log
        let effectiveTargetStartTime = Date()
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Calculating effective target", data: ["goalId": goal.id] as [String: Any], hypothesisId: "G")
        // #endregion
        let effectiveTarget = goal.effectiveTargetValue()
        // #region agent log
        let effectiveTargetDuration = Date().timeIntervalSince(effectiveTargetStartTime)
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Effective target calculated", data: ["goalId": goal.id, "effectiveTarget": effectiveTarget, "duration": effectiveTargetDuration] as [String: Any], hypothesisId: "G")
        // #endregion
        
        // Use effective target if > 0, otherwise fall back to stored targetValue
        let target = effectiveTarget > 0 ? effectiveTarget : goal.targetValue
        
        let oldCurrentValue = goal.currentValue
        let oldStatus = goal.status
        
        if task.isComplete {
            goal.currentValue = min(goal.currentValue + 1, target)
        } else {
            goal.currentValue = max(goal.currentValue - 1, 0)
        }

        // Update status based on effective target
        if goal.currentValue >= target && target > 0 {
            goal.status = GoalStatus.completed
        } else if goal.status == GoalStatus.completed && target > 0 {
            goal.status = GoalStatus.active
        }

        // #region agent log
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Goal values updated", data: ["goalId": goal.id, "oldCurrentValue": oldCurrentValue, "newCurrentValue": goal.currentValue, "oldStatus": oldStatus.rawValue, "newStatus": goal.status.rawValue, "target": target] as [String: Any], hypothesisId: "G")
        // #endregion

        // #region agent log
        let saveStartTime = Date()
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "About to save goal context", data: ["goalId": goal.id] as [String: Any], hypothesisId: "A")
        // #endregion
        
        do {
            try context.save()
            // #region agent log
            let saveDuration = Date().timeIntervalSince(saveStartTime)
            debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Goal context save SUCCEEDED", data: ["goalId": goal.id, "duration": saveDuration] as [String: Any], hypothesisId: "A")
            // #endregion
        } catch {
            // #region agent log
            let saveDuration = Date().timeIntervalSince(saveStartTime)
            debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "Goal context save FAILED", data: ["goalId": goal.id, "error": error.localizedDescription, "errorType": String(describing: type(of: error)), "duration": saveDuration] as [String: Any], hypothesisId: "A")
            // #endregion
        }
        
        // #region agent log
        let totalDuration = Date().timeIntervalSince(updateStartTime)
        debugLog(location: "GoalProgressUpdater:handleTaskToggle", message: "handleTaskToggle completed", data: ["goalId": goal.id, "totalDuration": totalDuration] as [String: Any], hypothesisId: "G")
        // #endregion
    }
    
    // Sync targetValue from linked tasks (call when tasks are added/removed)
    static func syncTargetValue(for goal: Goal, context: ModelContext) {
        let effectiveTarget = goal.effectiveTargetValue()
        if effectiveTarget > 0 {
            goal.targetValue = effectiveTarget
        }
        try? context.save()
    }
}


