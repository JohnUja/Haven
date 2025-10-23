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
    
    private let weatherKitService = WeatherKitService()
    
    init() {
        // Try to load real weather data first
        weatherKitService.requestLocationPermission()
        loadRealWeatherData()
    }
    
    func toggleWeather() {
        isWeatherEnabled.toggle()
    }
    
    func toggleTemperatureUnit() {
        isCelsius.toggle()
    }
    
    private func loadRealWeatherData() {
        Task {
            await weatherKitService.loadWeatherData()
            await MainActor.run {
                if let realWeather = weatherKitService.currentWeather {
                    self.currentWeather = realWeather
                }
                if !weatherKitService.hourlyWeather.isEmpty {
                    self.hourlyWeather = weatherKitService.hourlyWeather
                } else {
                    // Fallback to sample data if real weather fails
                    self.generateSampleHourlyWeather()
                }
            }
        }
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
        
        // Try real weather first, fallback to sample
        let realWeather = weatherKitService.getWeatherForTime(date)
        if realWeather != WeatherData.sample {
            return realWeather
        }
        
        let hour = Calendar.current.component(.hour, from: date)
        if hour < hourlyWeather.count {
            return hourlyWeather[hour]
        }
        
        return WeatherData.sample
    }
    
    func getWeatherForScrollPosition(_ scrollOffset: CGFloat, selectedDate: Date) -> WeatherData {
        guard isWeatherEnabled else {
            return WeatherData.sample
        }
        
        // Try real weather first, fallback to sample
        let realWeather = weatherKitService.getWeatherForScrollPosition(scrollOffset, selectedDate: selectedDate)
        if realWeather != WeatherData.sample {
            return realWeather
        }
        
        // Calculate which hour we're looking at based on scroll position
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        
        return getWeatherForHour(targetHour)
    }
    
    func getWeatherForHour(_ hour: Int) -> WeatherData {
        guard isWeatherEnabled else {
            return WeatherData.sample
        }
        
        // Try real weather first, fallback to sample
        let realWeather = weatherKitService.getWeatherForHour(hour)
        if realWeather != WeatherData.sample {
            return realWeather
        }
        
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
