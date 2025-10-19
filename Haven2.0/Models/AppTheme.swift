//
//  AppTheme.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI

// MARK: - Theme Protocol
protocol AppTheme {
    var id: String { get }
    var name: String { get }
    
    // Core Colors
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var cardBackground: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    
    // Background
    var backgroundGradient: LinearGradient { get }
    var particleColors: [Color] { get }
    
    // Fonts
    var headerFont: Font { get }
    var titleFont: Font { get }
    var bodyFont: Font { get }
    
    // UI Elements
    var cardCornerRadius: CGFloat { get }
    var shadowRadius: CGFloat { get }
}

// MARK: - Default Theme
struct DefaultTheme: AppTheme {
    let id = "default"
    let name = "Default"
    
    let primaryColor = Color(red: 0.3, green: 0.2, blue: 0.8) // Softer purple
    let secondaryColor = Color(red: 0.2, green: 0.5, blue: 0.9) // Softer blue
    let accentColor = Color(red: 0.9, green: 0.6, blue: 0.2) // Softer orange
    let cardBackground = Color.white.opacity(0.95)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.98, green: 0.95, blue: 1.0),
            Color(red: 0.97, green: 0.98, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.pink.opacity(0.1), Color.cyan.opacity(0.1)]
    
        let headerFont = Font.custom("Montserrat", size: 28).weight(.medium)
        let titleFont = Font.custom("Montserrat", size: 20).weight(.medium)
        let bodyFont = Font.custom("Montserrat", size: 16).weight(.regular)
    
    let cardCornerRadius: CGFloat = 16
    let shadowRadius: CGFloat = 8
}

// MARK: - Energetic Theme
struct EnergeticTheme: AppTheme {
    let id = "energetic"
    let name = "Energetic"
    
    let primaryColor = Color.orange
    let secondaryColor = Color.yellow
    let accentColor = Color.red
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.black
    let textSecondary = Color.gray
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color.yellow.opacity(0.8),
            Color.orange.opacity(0.9),
            Color.pink.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.yellow, Color.orange, Color.red, Color.pink]
    
    let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    let titleFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    let bodyFont = Font.system(size: 16, weight: .medium, design: .rounded)
    
    let cardCornerRadius: CGFloat = 16
    let shadowRadius: CGFloat = 8
}

// MARK: - Calm Theme
struct CalmTheme: AppTheme {
    let id = "calm"
    let name = "Calm"
    
    let primaryColor = Color.blue
    let secondaryColor = Color.cyan
    let accentColor = Color.mint
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.8),
            Color.cyan.opacity(0.6),
            Color.mint.opacity(0.7)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let particleColors = [Color.blue, Color.cyan, Color.mint, Color.teal]
    
    let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    let titleFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    let bodyFont = Font.system(size: 16, weight: .medium, design: .rounded)
    
    let cardCornerRadius: CGFloat = 20
    let shadowRadius: CGFloat = 6
}

// MARK: - Theme Manager
@Observable
class ThemeManager {
    var currentTheme: any AppTheme = DefaultTheme()
    
    private let themes: [any AppTheme] = [
        DefaultTheme(),
        EnergeticTheme(),
        CalmTheme()
    ]
    
    func setTheme(to themeId: String) {
        if let theme = themes.first(where: { $0.id == themeId }) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentTheme = theme
            }
        }
    }
    
    func getAllThemes() -> [any AppTheme] {
        return themes
    }
}
