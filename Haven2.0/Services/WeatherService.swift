//
//  WeatherService.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

@MainActor
class WeatherService: ObservableObject {
    @Published var currentWeather: Weather?
    @Published var hourlyForecast: Forecast<HourWeather>?
    @Published var isLocationAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather() async {
        guard let location = currentLocation else {
            errorMessage = "Location not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let current = weatherService.weather(for: location)
            async let hourly = weatherService.weather(for: location, including: .hourly)
            
            self.currentWeather = try await current
            self.hourlyForecast = try await hourly
        } catch {
            self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func getWeatherForTime(_ date: Date) -> WeatherData {
        guard let hourly = hourlyForecast else {
            return WeatherData.sample
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Find the closest hour in the forecast
        let closestHour = hourly.forecast.min { hour1, hour2 in
            let hour1Diff = abs(calendar.component(.hour, from: hour1.date) - hour)
            let hour2Diff = abs(calendar.component(.hour, from: hour2.date) - hour)
            return hour1Diff < hour2Diff
        }
        
        guard let weather = closestHour else {
            return WeatherData.sample
        }
        
        return WeatherData(
            temperature: Int(weather.temperature.value),
            condition: mapWeatherCondition(weather.condition),
            icon: mapWeatherIcon(weather.condition),
            description: weather.condition.description
        )
    }
    
    private func mapWeatherCondition(_ condition: WeatherCondition) -> WeatherConditionType {
        switch condition {
        case .clear, .mostlyClear:
            return .sunny
        case .partlyCloudy, .mostlyCloudy, .cloudy:
            return .cloudy
        case .rain, .drizzle, .showers:
            return .rainy
        case .thunderstorms, .stormy:
            return .stormy
        default:
            return .sunny
        }
    }
    
    private func mapWeatherIcon(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear:
            return "sun.max.fill"
        case .partlyCloudy, .mostlyCloudy, .cloudy:
            return "cloud.fill"
        case .rain, .drizzle, .showers:
            return "cloud.rain.fill"
        case .thunderstorms, .stormy:
            return "cloud.bolt.fill"
        default:
            return "sun.max.fill"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        isLocationAuthorized = true
        
        Task {
            await fetchWeather()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            isLocationAuthorized = false
            errorMessage = "Location access denied"
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - Weather Data Models
struct WeatherData {
    let temperature: Int
    let condition: WeatherConditionType
    let icon: String
    let description: String
    
    static let sample = WeatherData(
        temperature: 72,
        condition: .sunny,
        icon: "sun.max.fill",
        description: "Sunny"
    )
}

enum WeatherConditionType {
    case sunny, cloudy, rainy, stormy
    
    var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .stormy: return "Stormy"
        }
    }
}
