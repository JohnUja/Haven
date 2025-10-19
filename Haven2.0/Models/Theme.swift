//
//  Theme.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData

@Model
final class Theme {
    var id: String
    var name: String
    var themeDescription: String
    var unlockMethod: UnlockType
    var unlockRequirement: String
    var currencyPrice: Int
    var iapProductID: String?
    var isDefault: Bool
    
    init(id: String = UUID().uuidString,
         name: String,
         themeDescription: String,
         unlockMethod: UnlockType,
         unlockRequirement: String,
         currencyPrice: Int = 0,
         iapProductID: String? = nil,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.themeDescription = themeDescription
        self.unlockMethod = unlockMethod
        self.unlockRequirement = unlockRequirement
        self.currencyPrice = currencyPrice
        self.iapProductID = iapProductID
        self.isDefault = isDefault
    }
}

enum UnlockType: String, CaseIterable, Codable {
    case progress = "progress"
    case currency = "currency"
    case iap = "iap"
    
    var displayName: String {
        switch self {
        case .progress: return "Progress Unlock"
        case .currency: return "Currency Purchase"
        case .iap: return "In-App Purchase"
        }
    }
}
