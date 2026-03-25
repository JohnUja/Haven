//
//  FeedReaction.swift
//  Haven2.0
//
//  Created by John Uja on 2025-01-XX.
//

import Foundation
import SwiftData

@Model
final class FeedReaction {
    var id: String
    var feedItemID: String
    var userID: String
    var reactionType: ReactionType
    var timestamp: Date
    
    init(id: String = UUID().uuidString,
         feedItemID: String,
         userID: String,
         reactionType: ReactionType,
         timestamp: Date = Date()) {
        self.id = id
        self.feedItemID = feedItemID
        self.userID = userID
        self.reactionType = reactionType
        self.timestamp = timestamp
    }
}

@Model
final class FeedComment {
    var id: String
    var feedItemID: String
    var userID: String
    var commentText: String
    var reactionType: ReactionType // The reaction that triggered this comment
    var timestamp: Date
    
    init(id: String = UUID().uuidString,
         feedItemID: String,
         userID: String,
         commentText: String,
         reactionType: ReactionType,
         timestamp: Date = Date()) {
        self.id = id
        self.feedItemID = feedItemID
        self.userID = userID
        self.commentText = commentText
        self.reactionType = reactionType
        self.timestamp = timestamp
    }
}

enum ReactionType: String, Codable, CaseIterable {
    case joy = "joy"
    case inspired = "inspired"
    case calm = "calm"
    
    var iconName: String {
        switch self {
        case .joy: return "heart"
        case .inspired: return "sparkles"
        case .calm: return "moon.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .joy: return Color(red: 1.0, green: 0.4, blue: 0.6) // Pink with slight yellow blend (80-90% pink)
        case .inspired: return Color.purple
        case .calm: return Color.green
        }
    }
    
    var displayName: String {
        switch self {
        case .joy: return "Joy"
        case .inspired: return "Inspired"
        case .calm: return "Calm"
        }
    }
}

import SwiftUI

