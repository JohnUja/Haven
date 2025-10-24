//
//  TimelineTypes.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import Foundation

// MARK: - Timeline Types
enum TimelineSide: String, Codable, CaseIterable, Identifiable {
    case left, right
    
    var id: String { self.rawValue }
}
