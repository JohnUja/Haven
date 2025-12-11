//
//  GoalStatusManager.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftUI

enum GoalRiskSeverity {
    case ahead
    case onTrack
    case atRisk
    case severe
}

struct GoalStatusInsight {
    let status: GoalStatus
    let risk: GoalRiskSeverity
    let progress: Double
}

enum GoalStatusManager {
    static func computeProgress(for goal: Goal, tasks: [Task] = []) -> Double {
        goal.progressPercentage()
    }
    
    static func evaluate(goal: Goal, tasks: [Task] = [], now: Date = Date()) -> GoalStatusInsight {
        let progress = computeProgress(for: goal, tasks: tasks)
        
        if goal.status == .completed || progress >= 1.0 {
            return GoalStatusInsight(status: .completed, risk: .onTrack, progress: 1.0)
        }
        
        if goal.status == .paused {
            let risk = riskSeverity(for: goal, progress: progress, tasks: tasks, now: now)
            return GoalStatusInsight(status: .paused, risk: risk, progress: progress)
        }
        
        let risk = riskSeverity(for: goal, progress: progress, tasks: tasks, now: now)
        let status: GoalStatus = (risk == .atRisk || risk == .severe) ? .atRisk : .active
        return GoalStatusInsight(status: status, risk: risk, progress: progress)
    }
    
    static func riskSeverity(for goal: Goal, progress: Double, tasks: [Task] = [], now: Date = Date()) -> GoalRiskSeverity {
        let hasOverdueMilestone = (goal.milestones ?? []).contains { milestone in
            guard let deadline = milestone.deadline else { return false }
            let milestoneTasks = tasks.filter { $0.milestone?.id == milestone.id }
            let completed = milestoneTasks.filter { $0.isComplete }.count
            let isComplete = !milestoneTasks.isEmpty && completed == milestoneTasks.count
            return now > deadline && !isComplete
        }
        
        let timelinePace = expectedPace(for: goal, now: now)
        
        if hasOverdueMilestone {
            return .severe
        }
        
        if progress >= timelinePace + 0.1 {
            return .ahead
        } else if progress >= timelinePace - 0.05 {
            return .onTrack
        } else if progress >= timelinePace - 0.2 {
            return .atRisk
        } else {
            return .severe
        }
    }
    
    static func expectedPace(for goal: Goal, now: Date = Date()) -> Double {
        guard let end = goal.deadline else { return 0.0 }
        let start = goal.startDate
        guard end > start else { return 1.0 }
        
        let total = end.timeIntervalSince(start)
        let elapsed = max(0, min(now.timeIntervalSince(start), total))
        let fraction = total == 0 ? 1.0 : (elapsed / total)
        return max(0.0, min(1.0, fraction))
    }
    
    static func borderColor(for risk: GoalRiskSeverity) -> Color {
        switch risk {
        case .onTrack: return .green
        case .atRisk: return .orange
        case .severe: return .red
        case .ahead: return .pink
        }
    }
}

