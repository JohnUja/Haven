//
//  WeatherManager.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import Foundation
import SwiftUI

@MainActor
class WeatherManager: ObservableObject {
    @Published var isWeatherEnabled: Bool = true
    @Published var isCelsius: Bool = false // Temperature unit toggle
    @Published var currentWeather: WeatherData = WeatherData.sample
    @Published var hourlyWeather: [WeatherData] = []
    
    init() {
        generateSampleHourlyWeather()
    }
    
    func toggleWeather() {
        isWeatherEnabled.toggle()
    }
    
    func toggleTemperatureUnit() {
        isCelsius.toggle()
    }
    
    func getTemperatureString(_ temperature: Int) -> String {
        if isCelsius {
            let celsius = Int((Double(temperature) - 32) * 5/9)
            return "\(celsius)°C"
        } else {
            return "\(temperature)°F"
        }
    }
    
    func getWeatherForTime(_ date: Date) -> WeatherData {
        guard isWeatherEnabled else {
            return WeatherData.sample
        }
        
        let hour = Calendar.current.component(.hour, from: date)
        
        // Return weather for the specific hour, or sample if not available
        if hour < hourlyWeather.count {
            return hourlyWeather[hour]
        }
        
        return WeatherData.sample
    }
    
    func getWeatherForScrollPosition(_ scrollOffset: CGFloat, selectedDate: Date) -> WeatherData {
        guard isWeatherEnabled else {
            return WeatherData.sample
        }
        
        // Calculate which hour we're looking at based on scroll position
        // Each hour is 120 points high, so we can calculate the hour
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        print("Scroll offset: \(scrollOffset), Hour offset: \(hourOffset), Target hour: \(targetHour)")
        return getWeatherForHour(targetHour)
    }
    
    func getWeatherForHour(_ hour: Int) -> WeatherData {
        guard hour >= 0 && hour < hourlyWeather.count else {
            return WeatherData.sample
        }
        return hourlyWeather[hour]
    }
    
    private func generateSampleHourlyWeather() {
        hourlyWeather = (0...23).map { hour in
            WeatherData(
                temperature: generateTemperatureForHour(hour),
                condition: generateConditionForHour(hour),
                icon: generateIconForHour(hour),
                description: generateDescriptionForHour(hour)
            )
        }
    }
    
    private func generateTemperatureForHour(_ hour: Int) -> Int {
        // Simulate realistic temperature changes throughout the day
        let baseTemp = 70
        let variation = Int(sin(Double(hour - 6) * .pi / 12) * 20)
        let temp = baseTemp + variation
        
        print("Hour \(hour): Temperature \(temp)°F")
        return temp
    }
    
    private func generateConditionForHour(_ hour: Int) -> WeatherCondition {
        // Simulate weather patterns with more variety
        switch hour {
        case 0...5:
            return .cloudy  // Early morning clouds
        case 6...8:
            return .sunny   // Sunrise
        case 9...11:
            return .sunny   // Clear morning
        case 12...14:
            return .sunny   // Clear afternoon
        case 15...17:
            return .cloudy  // Afternoon clouds
        case 18...20:
            return .rainy   // Evening rain
        case 21...23:
            return .stormy  // Night storm
        default:
            return .sunny
        }
    }
    
    private func generateIconForHour(_ hour: Int) -> String {
        let condition = generateConditionForHour(hour)
        switch condition {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .stormy:
            return "cloud.bolt.fill"
        }
    }
    
    private func generateDescriptionForHour(_ hour: Int) -> String {
        let condition = generateConditionForHour(hour)
        return condition.displayName
    }
}

// MARK: - Weather Data Models
struct WeatherData {
    let temperature: Int
    let condition: WeatherCondition
    let icon: String
    let description: String
    
    static let sample = WeatherData(
        temperature: 72,
        condition: .sunny,
        icon: "sun.max.fill",
        description: "Sunny"
    )
}

enum WeatherCondition: CaseIterable {
    case sunny, cloudy, rainy, stormy
    
    var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .stormy: return "Stormy"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .rainy: return .blue
        case .stormy: return .purple
        }
    }
}
