//
//  League.swift
//  Haven2.0
//
//  Created by John Uja on 2025-01-XX.
//

import Foundation
import SwiftUI

enum League: String, CaseIterable, Identifiable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case master = "Master"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .bronze: return "trophy.fill"
        case .silver: return "trophy.fill"
        case .gold: return "trophy.fill"
        case .platinum: return "trophy.fill"
        case .diamond: return "trophy.fill"
        case .master: return "trophy.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        case .diamond: return .blue
        case .master: return .purple
        }
    }
    
    var baseColor: Color {
        switch self {
        case .bronze: return .brown.opacity(0.8)
        case .silver: return .gray.opacity(0.8)
        case .gold: return .yellow.opacity(0.8)
        case .platinum: return .cyan.opacity(0.8)
        case .diamond: return .blue.opacity(0.8)
        case .master: return .purple.opacity(0.8)
        }
    }
    
    // Placeholder: Determine league based on score
    static func leagueForScore(_ score: Int) -> League {
        switch score {
        case 0..<100: return .bronze
        case 100..<500: return .silver
        case 500..<1000: return .gold
        case 1000..<2000: return .platinum
        case 2000..<5000: return .diamond
        default: return .master
        }
    }
    
    // Top 10 advance to next league
    static func canAdvance(rank: Int) -> Bool {
        return rank <= 10
    }
}


