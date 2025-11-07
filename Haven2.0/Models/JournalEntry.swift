//
//  JournalEntry.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: String
    var taskID: String
    var goalID: String
    var timestamp: Date
    var note: String
    var imageData: Data? // Optional image stored as compressed JPEG
    
    init(id: String = UUID().uuidString,
         taskID: String,
         goalID: String,
         timestamp: Date = Date(),
         note: String,
         imageData: Data? = nil) {
        self.id = id
        self.taskID = taskID
        self.goalID = goalID
        self.timestamp = timestamp
        self.note = note
        self.imageData = imageData
    }
}

