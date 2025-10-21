//
//  WeatherSettingsView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI

struct WeatherSettingsView: View {
    @StateObject private var weatherManager = WeatherManager()
    
    var body: some View {
        List {
            Section("Temperature Unit") {
                HStack {
                    Text("Use Celsius")
                    Spacer()
                    Toggle("", isOn: $weatherManager.isCelsius)
                        .onChange(of: weatherManager.isCelsius) { _, newValue in
                            weatherManager.toggleTemperatureUnit()
                        }
                }
                
                Text("Currently showing: \(weatherManager.isCelsius ? "°C" : "°F")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Weather Features") {
                HStack {
                    Text("Enable Weather")
                    Spacer()
                    Toggle("", isOn: $weatherManager.isWeatherEnabled)
                        .onChange(of: weatherManager.isWeatherEnabled) { _, newValue in
                            weatherManager.toggleWeather()
                        }
                }
                
                Text("Weather effects will appear on the timeline when enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Location") {
                HStack {
                    Text("Location Permission")
                    Spacer()
                    if weatherManager.locationPermissionStatus == .authorized {
                        Text("Granted")
                            .foregroundColor(.green)
                    } else {
                        Text("Not Granted")
                            .foregroundColor(.red)
                    }
                }
                
                if weatherManager.locationPermissionStatus != .authorized {
                    Button("Request Location Permission") {
                        weatherManager.requestLocationPermission()
                    }
                }
                
                Text("Location is needed to show accurate weather data for your area")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Weather Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        WeatherSettingsView()
    }
}
