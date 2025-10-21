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
                    Text("Not Available")
                        .foregroundColor(.orange)
                }
                
                Text("Location features will be added in a future update")
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
