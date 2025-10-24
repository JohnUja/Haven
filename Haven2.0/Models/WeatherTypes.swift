//
//  WeatherTypes.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import Foundation
import SwiftUI

// MARK: - Weather Data Models
struct WeatherData: Equatable {
    let temperature: Int
    let condition: CustomWeatherCondition
    let icon: String
    let description: String
    
    static let sample = WeatherData(
        temperature: 72,
        condition: .sunny,
        icon: "sun.max.fill",
        description: "Sunny"
    )
}

enum CustomWeatherCondition: CaseIterable, Equatable {
    case sunny, cloudy, rainy, stormy, overcast, showers
    
    var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .stormy: return "Stormy"
        case .overcast: return "Overcast"
        case .showers: return "Showers"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .rainy: return .blue
        case .stormy: return .purple
        case .overcast: return .gray
        case .showers: return .blue
        }
    }
}
