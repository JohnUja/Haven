//
//  SubscriptionService.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import Foundation

enum SubscriptionTier: String, Codable {
    case guest = "guest"
    case free = "free"
    case plus = "plus"
    case pro = "pro"
    case lifetime = "lifetime"
}

class SubscriptionService {
    static let shared = SubscriptionService()
    
    private init() {}
    
    // For now, assume all users are on free tier unless we add subscription tracking
    // TODO: Integrate with User model subscription status when available
    func getSubscriptionTier(for userID: String) -> SubscriptionTier {
        // Check UserDefaults or User model for subscription status
        // For now, default to free
        return .free
    }
    
    func canCreateMultipleRoutines(tier: SubscriptionTier) -> Bool {
        switch tier {
        case .guest:
            return false
        case .free:
            return false // Free tier: only 1 routine
        case .plus, .pro, .lifetime:
            return true // Premium: up to 5 routines
        }
    }
    
    func maxActiveRoutines(tier: SubscriptionTier) -> Int {
        switch tier {
        case .guest:
            return 0
        case .free:
            return 1
        case .plus, .pro, .lifetime:
            return 5
        }
    }
}


