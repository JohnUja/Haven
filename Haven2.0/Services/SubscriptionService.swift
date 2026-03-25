//
//  SubscriptionService.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import Foundation
import SwiftData

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
    
    func getSubscriptionTier(for user: User?) -> SubscriptionTier {
        guard let user else { return .guest }
        return SubscriptionTier(rawValue: user.subscriptionTierRaw) ?? .free
    }

    func setSubscriptionTier(_ tier: SubscriptionTier, for user: User, in modelContext: ModelContext) async throws {
        user.subscriptionTierRaw = tier.rawValue
        try modelContext.save()

        if let uid = LocalUserProvisioningService.currentAuthenticatedUserID() {
            try? await FirestoreService.shared.updateSubscriptionStatus(uid: uid, status: tier.rawValue)
        }
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


