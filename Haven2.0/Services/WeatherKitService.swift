//
//  WeatherKitService.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import Foundation
#if canImport(WeatherKit)
import WeatherKit
#endif
import CoreLocation
import SwiftUI

@MainActor
class WeatherKitService: NSObject, ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var currentWeather: WeatherData?
    @Published var hourlyWeather: [WeatherData] = []
    @Published var errorMessage: String?
    
    #if canImport(WeatherKit)
    private let weatherService = WeatherService()
    #endif
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is required for weather data"
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
    
    func loadWeatherData() {
        guard isAuthorized, let location = currentLocation else {
            requestLocationPermission()
            return
        }
        
        #if canImport(WeatherKit)
        loadWeatherDataAsync(for: location)
        #else
        // Fallback for simulator or when WeatherKit is not available
        await MainActor.run {
            self.currentWeather = WeatherData.sample
            self.hourlyWeather = generateSampleWeather()
            self.errorMessage = "WeatherKit not available (simulator mode)"
        }
        #endif
    }
    
    private func generateSampleWeather() -> [WeatherData] {
        return (0...23).map { hour in
            WeatherData(
                temperature: 70 + Int(sin(Double(hour - 6) * .pi / 12) * 20),
                condition: hour < 6 ? .cloudy : hour < 18 ? .sunny : .cloudy,
                icon: hour < 6 ? "cloud.fill" : hour < 18 ? "sun.max.fill" : "cloud.fill",
                description: hour < 6 ? "Cloudy" : hour < 18 ? "Sunny" : "Cloudy"
            )
        }
    }
    
    func getWeatherForHour(_ hour: Int) -> WeatherData {
        guard hour >= 0 && hour < hourlyWeather.count else {
            return WeatherData.sample
        }
        return hourlyWeather[hour]
    }
    
    func getWeatherForTime(_ date: Date) -> WeatherData {
        let hour = Calendar.current.component(.hour, from: date)
        return getWeatherForHour(hour)
    }
    
    func getWeatherForScrollPosition(_ scrollOffset: CGFloat, selectedDate: Date) -> WeatherData {
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        let targetHour = (baseHour + hourOffset) % 24
        return getWeatherForHour(targetHour)
    }
    
    private func loadWeatherDataAsync(for location: CLLocation) {
        // Use a simple approach to avoid namespace conflicts
        _Concurrency.Task {
            do {
                let weather = try await weatherService.weather(for: location)
                await MainActor.run {
                    self.currentWeather = WeatherData(from: weather.currentWeather)
                    self.hourlyWeather = weather.hourlyForecast.prefix(24).map { WeatherData(from: $0) }
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load weather data: \(error.localizedDescription)"
                }
            }
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension WeatherKitService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        _Concurrency.Task {
            await MainActor.run {
                self.currentLocation = location
                self.loadWeatherData()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _Concurrency.Task {
            await MainActor.run {
                self.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        _Concurrency.Task {
            await MainActor.run {
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    self.isAuthorized = true
                    self.locationManager.requestLocation()
                case .denied, .restricted:
                    self.isAuthorized = false
                    self.errorMessage = "Location access denied"
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Weather Data Conversion
#if canImport(WeatherKit)
extension WeatherData {
    init(from weather: CurrentWeather) {
        self.temperature = Int(weather.temperature.value)
        self.condition = CustomWeatherCondition(from: weather.condition)
        self.icon = WeatherData.iconForCondition(weather.condition)
        self.description = weather.condition.description
    }
    
    init(from weather: HourWeather) {
        self.temperature = Int(weather.temperature.value)
        self.condition = CustomWeatherCondition(from: weather.condition)
        self.icon = WeatherData.iconForCondition(weather.condition)
        self.description = weather.condition.description
    }
    
    static func iconForCondition(_ condition: WeatherKit.WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear:
            return "sun.max.fill"
        case .partlyCloudy, .mostlyCloudy, .cloudy:
            return "cloud.fill"
        case .drizzle, .rain, .heavyRain:
            return "cloud.rain.fill"
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return "cloud.bolt.fill"
        default:
            return "sun.max.fill"
        }
    }
}

extension CustomWeatherCondition {
    init(from condition: WeatherKit.WeatherCondition) {
        switch condition {
        case .clear, .mostlyClear:
            self = .sunny
        case .partlyCloudy, .mostlyCloudy, .cloudy:
            self = .cloudy
        case .drizzle, .rain, .heavyRain:
            self = .rainy
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms:
            self = .stormy
        default:
            self = .sunny
        }
    }
}
#endif
