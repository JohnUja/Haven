//
//  AppleWeatherBackground.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI
import WeatherKit

struct AppleWeatherBackground: View {
    let weatherData: WeatherData
    let scrollOffset: CGFloat
    let selectedDate: Date
    
    private var weatherColors: [Color] {
        // Apple-style weather colors based on real weather conditions
        switch weatherData.condition {
        case .sunny:
            return createSunnyGradient()
        case .cloudy:
            return createCloudyGradient()
        case .rainy:
            return createRainyGradient()
        case .stormy:
            return createStormyGradient()
        case .overcast:
            return createCloudyGradient()
        case .showers:
            return createRainyGradient()
        }
    }
    
    private var timeBasedColors: [Color] {
        let _ = Calendar.current.component(.hour, from: selectedDate)
        let scrollHour = getScrollHour()
        
        switch scrollHour {
        case 5...7: // Dawn
            return [.orange.opacity(0.8), .yellow.opacity(0.6), .pink.opacity(0.4)]
        case 8...16: // Day
            return [.blue.opacity(0.6), .cyan.opacity(0.4), .white.opacity(0.2)]
        case 17...19: // Dusk
            return [.orange.opacity(0.6), .red.opacity(0.4), .purple.opacity(0.3)]
        default: // Night
            return [.purple.opacity(0.8), .black.opacity(0.6), .blue.opacity(0.4)]
        }
    }
    
    private var finalColors: [Color] {
        // Blend weather colors with time-based colors
        return blendColors(weatherColors, timeBasedColors)
    }
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: finalColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Weather-specific overlays
            weatherOverlay
        }
    }
    
    @ViewBuilder
    private var weatherOverlay: some View {
        switch weatherData.condition {
        case .sunny:
            SunnyOverlay()
        case .cloudy:
            CloudyOverlay()
        case .rainy:
            RainyOverlay()
        case .stormy:
            StormyOverlay()
        case .overcast:
            CloudyOverlay()
        case .showers:
            RainyOverlay()
        }
    }
    
    private func getScrollHour() -> Int {
        let hourOffset = Int(abs(scrollOffset) / 120)
        let baseHour = Calendar.current.component(.hour, from: selectedDate)
        return (baseHour + hourOffset) % 24
    }
    
    private func createSunnyGradient() -> [Color] {
        return [
            .yellow.opacity(0.9),
            .orange.opacity(0.7),
            .white.opacity(0.5)
        ]
    }
    
    private func createCloudyGradient() -> [Color] {
        return [
            .gray.opacity(0.8),
            .blue.opacity(0.6),
            .white.opacity(0.3)
        ]
    }
    
    private func createRainyGradient() -> [Color] {
        return [
            .blue.opacity(0.8),
            .gray.opacity(0.6),
            .white.opacity(0.3)
        ]
    }
    
    private func createStormyGradient() -> [Color] {
        return [
            .purple.opacity(0.9),
            .black.opacity(0.8),
            .blue.opacity(0.5)
        ]
    }
    
    private func blendColors(_ colors1: [Color], _ colors2: [Color]) -> [Color] {
        let maxCount = max(colors1.count, colors2.count)
        var blended: [Color] = []
        
        for i in 0..<maxCount {
            let color1 = i < colors1.count ? colors1[i] : colors1.last ?? .clear
            let color2 = i < colors2.count ? colors2[i] : colors2.last ?? .clear
            
            // Simple blending - in a real implementation, you'd use proper color blending
            let blendedColor = color1.opacity(0.7)
            blended.append(blendedColor)
        }
        
        return blended
    }
}

// MARK: - Weather Overlays
struct SunnyOverlay: View {
    var body: some View {
        ZStack {
            // Sun rays
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 2, height: 100)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .offset(y: -50)
            }
            
            // Sun
            Circle()
                .fill(Color.yellow.opacity(0.6))
                .frame(width: 80, height: 80)
                .offset(x: 100, y: -200)
        }
    }
}

struct CloudyOverlay: View {
    var body: some View {
        ZStack {
            // Cloud shapes
            ForEach(0..<3, id: \.self) { index in
                CloudShape()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 120, height: 60)
                    .offset(x: CGFloat(index * 80 - 80), y: CGFloat(index * 40 - 100))
            }
        }
    }
}

struct RainyOverlay: View {
    var body: some View {
        ZStack {
            // Rain drops
            ForEach(0..<50, id: \.self) { index in
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 1, height: 20)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .animation(
                        .linear(duration: Double.random(in: 0.5...2.0))
                        .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
    }
}

struct StormyOverlay: View {
    var body: some View {
        ZStack {
            // Lightning
            ForEach(0..<3, id: \.self) { index in
                LightningShape()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 4, height: 100)
                    .offset(x: CGFloat(index * 60 - 60), y: -100)
            }
            
            // Dark clouds
            ForEach(0..<4, id: \.self) { index in
                CloudShape()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 150, height: 80)
                    .offset(x: CGFloat(index * 80 - 120), y: CGFloat(index * 30 - 150))
            }
        }
    }
}

// MARK: - Custom Shapes
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Main cloud body
        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.3, width: width * 0.8, height: height * 0.7))
        
        // Left puff
        path.addEllipse(in: CGRect(x: 0, y: height * 0.2, width: width * 0.6, height: height * 0.6))
        
        // Right puff
        path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.1, width: width * 0.6, height: height * 0.6))
        
        return path
    }
}

struct LightningShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Lightning bolt shape
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.2, y: height))
        
        return path
    }
}
