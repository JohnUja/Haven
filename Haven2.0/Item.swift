//
//  Item.swift
//  Haven2.0
//
//  Created by John Uja on 2025-10-18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
