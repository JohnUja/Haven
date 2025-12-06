//
//  FocusPeriod.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Focus period categorization for dynamic home screen
//

import Foundation

enum FocusPeriod: String, CaseIterable {
    case morning = "Morning Focus"
    case afternoon = "Afternoon Focus"
    case evening = "Evening Focus"
    case lateNight = "Late Night Focus"
    
    var timeRange: (start: Int, end: Int) {
        switch self {
        case .morning: return (6, 12)
        case .afternoon: return (12, 17)
        case .evening: return (17, 22)
        case .lateNight: return (22, 6)
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .lateNight: return "moon.fill"
        }
    }
    
    static func currentPeriod() -> FocusPeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .lateNight
        }
    }
    
    static func period(for hour: Int) -> FocusPeriod {
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .lateNight
        }
    }
}

