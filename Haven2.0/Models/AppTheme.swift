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
    
    // Glassmorphism Colors (theme-aware)
    var glassBackground: Color { get }  // For glassmorphism cards
    var glassBorder: Color { get }        // For glassmorphism borders
    var glassOverlay: Color { get }       // For glassmorphism overlay
    
    // Card Colors (theme-aware)
    var cardFill: Color { get }           // Card fill color
    var cardStroke: Color { get }         // Card stroke color
    var cardShadow: Color { get }         // Card shadow color
    
    // Shared Backgrounds (used across all screens)
    var primaryGradient: LinearGradient { get }
    var secondaryGradient: LinearGradient { get }
    var particleColors: [Color] { get }
    
    // Fonts
    var headerFont: Font { get }
    var titleFont: Font { get }
    var bodyFont: Font { get }
    
    // UI Elements (CONSISTENT VALUES)
    var cardCornerRadius: CGFloat { get }  // Always 16
    var cardBorderWidth: CGFloat { get }   // Always 1
    var shadowRadius: CGFloat { get }      // Always 8
    
    // Additional Sizes & Spacing
    var iconCircleSize: CGFloat { get }     // Default: 44
    var smallCornerRadius: CGFloat { get } // Default: 12 (for smaller elements)
    
    // Opacity Levels
    var iconBackgroundOpacity: Double { get }  // Default: 0.2
    var textSecondaryOpacity: Double { get }    // Default: 0.8
    var textTertiaryOpacity: Double { get }     // Default: 0.7
    
    // Padding & Spacing
    var cardPadding: CGFloat { get }           // Default: 16
    var cardVerticalPadding: CGFloat { get }   // Default: 12
    var sectionSpacing: CGFloat { get }        // Default: 24
    var sectionPadding: CGFloat { get }        // Default: 20 (for section headers)
    var itemSpacing: CGFloat { get }           // Default: 12
    
    // Stroke Widths
    var selectedStrokeWidth: CGFloat { get }   // Default: 3 (for selected items)
    
    // Day Selector Shadows (for InfiniteDaySelector only)
    var daySelectorCircleShadowColor: Color { get }
    var daySelectorCircleShadowRadius: CGFloat { get }
    var daySelectorTextShadowColor: Color { get }
    var daySelectorTextShadowRadius: CGFloat { get }
    var daySelectorTextShadowX: CGFloat { get }
    var daySelectorTextShadowY: CGFloat { get }
    
    // Leaderboard Styling
    var leaderboardCardBackground: Color { get }
    var leaderboardCardBorder: Color { get }
    var leaderboardCardBorderWidth: CGFloat { get }
    var leaderboardCardCornerRadius: CGFloat { get }
    var leaderboardCurrentUserBorder: Color { get }
    var leaderboardCurrentUserBorderWidth: CGFloat { get }
    
    // NEW: Accessibility & Requirements (Apple HIG)
    var minimumTouchTarget: CGFloat { get }  // Apple requirement: 44pt
    var focusRingColor: Color { get }
    var focusRingWidth: CGFloat { get }
    
    // NEW: Error & Feedback Colors
    var errorColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }
    var infoColor: Color { get }
    
    // NEW: Animation Properties
    var buttonPressAnimation: Animation { get }
    var cardLiftAnimation: Animation { get }
    var pageTransitionAnimation: Animation { get }
    
    // NEW: Font Sizes (for typography system)
    var headerFontSize: CGFloat { get }      // 11
    var paragraphFontSize: CGFloat { get }    // 10
    var smallFontSize: CGFloat { get }        // 7 or 8
    var headerFontWeight: Font.Weight { get } // .semibold
    var paragraphFontWeight: Font.Weight { get } // .regular
}

// MARK: - Purple Theme (Default)
struct PurpleTheme: AppTheme {
    let id = "purple"
    let name = "Purple"
    
    let primaryColor = Color(red: 0.3, green: 0.2, blue: 0.8) // Softer purple
    let secondaryColor = Color(red: 0.2, green: 0.5, blue: 0.9) // Softer blue
    let accentColor = Color(red: 0.9, green: 0.6, blue: 0.2) // Orange undertone for button selections
    let cardBackground = Color.white.opacity(0.95)
    let textPrimary = Color.white // White text for purple theme
    let textSecondary = Color.white.opacity(0.8) // White with opacity for secondary
    
    // Shared Backgrounds - DARKENED purple gradient
    let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.2, blue: 0.7).opacity(0.95), // Darker purple
            Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.85), // Darker blue
            Color(red: 0.6, green: 0.2, blue: 0.5).opacity(0.75) // Darker pink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.98, green: 0.95, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.pink.opacity(0.1), Color.cyan.opacity(0.1)]
    
        // Purple theme - controlled fonts
        let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
        let titleFont = Font.system(size: 10, weight: .regular, design: .default)
        let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism (default theme - light glass)
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.white.opacity(0.2)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.white.opacity(0.2)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    // Additional Sizes & Spacing
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    
    // Opacity Levels
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    
    // Padding & Spacing
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    
    // Stroke Widths
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.green.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 5
    let daySelectorTextShadowColor = Color.black.opacity(0.3)
    let daySelectorTextShadowRadius: CGFloat = 1
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.white.opacity(0.2)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.white
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes (for typography system)
    var headerFontSize: CGFloat { 11 }
    var paragraphFontSize: CGFloat { 10 }
    var smallFontSize: CGFloat { 8 }
    var headerFontWeight: Font.Weight { .semibold }
    var paragraphFontWeight: Font.Weight { .regular }
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
    
    let primaryGradient = LinearGradient(
        colors: [Color.orange.opacity(0.9), Color.red.opacity(0.8), Color.yellow.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.yellow.opacity(0.8),
            Color.orange.opacity(0.9),
            Color.pink.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.yellow, Color.orange, Color.red, Color.pink]
    
    // Custom themes - controlled fonts with sizes 11/10/7-8
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.white.opacity(0.2)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.white.opacity(0.2)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.black.opacity(0.3)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.white.opacity(0.2)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.white
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
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
    
    let primaryGradient = LinearGradient(
        colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.7), Color.mint.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.8),
            Color.cyan.opacity(0.6),
            Color.mint.opacity(0.7)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let particleColors = [Color.blue, Color.cyan, Color.mint, Color.teal]
    
    // Custom themes - controlled fonts with sizes 11/10/7-8
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.white.opacity(0.2)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.white.opacity(0.2)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.black.opacity(0.3)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.white.opacity(0.2)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.white
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Light Theme (Black/White/Grey Only)
struct LightTheme: AppTheme {
    let id = "light"
    let name = "Light"
    
    let primaryColor = Color.black
    let secondaryColor = Color.gray
    let accentColor = Color.gray
    let cardBackground = Color.white
    let textPrimary = Color.black
    let textSecondary = Color.gray
    
    // Light mode backgrounds - white/grey gradients only
    let primaryGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 0.98, green: 0.98, blue: 0.98), // Light grey
            Color(red: 0.95, green: 0.95, blue: 0.95) // Medium grey
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 0.98),
            Color(red: 0.95, green: 0.95, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.gray.opacity(0.1), Color.black.opacity(0.05)]
    
    // Light theme - system default fonts
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism (light mode - white/black/grey only)
    let glassBackground = Color.white.opacity(0.9)
    let glassBorder = Color.black.opacity(0.2)
    let glassOverlay = Color.white.opacity(0.1)
    
    // Card Colors (light mode - white/black/grey only)
    let cardFill = Color.white
    let cardStroke = Color.black.opacity(0.3)
    let cardShadow = Color.black.opacity(0.1)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.black.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.9)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling (Light theme - black borders)
    let leaderboardCardBackground = Color.white.opacity(0.9)
    let leaderboardCardBorder = Color.black.opacity(0.3)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.black
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.black.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes (Light theme - system default)
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Dark Theme (Black/White/Grey Only)
struct DarkTheme: AppTheme {
    let id = "dark"
    let name = "Dark"
    
    let primaryColor = Color.white
    let secondaryColor = Color.gray
    let accentColor = Color.gray
    let cardBackground = Color.black
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    // Dark mode backgrounds - black/grey gradients only
    let primaryGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.1, green: 0.1, blue: 0.1), // Dark grey
            Color(red: 0.15, green: 0.15, blue: 0.15) // Medium grey
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.1, blue: 0.1),
            Color(red: 0.15, green: 0.15, blue: 0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.gray.opacity(0.2), Color.white.opacity(0.1)]
    
    // Light theme - system default fonts
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism (dark mode - black/white/grey only)
    let glassBackground = Color.black.opacity(0.7)
    let glassBorder = Color.white.opacity(0.2)
    let glassOverlay = Color.black.opacity(0.1)
    
    // Card Colors (dark mode - black/white/grey only)
    let cardFill = Color.black.opacity(0.8)
    let cardStroke = Color.white.opacity(0.3)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.black.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.9)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling (Dark theme - white borders)
    let leaderboardCardBackground = Color.black.opacity(0.7)
    let leaderboardCardBorder = Color.white.opacity(0.3)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.white
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes (Dark theme - system default)
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Sunset Theme
struct SunsetTheme: AppTheme {
    let id = "sunset"
    let name = "Sunset"
    
    let primaryColor = Color.orange
    let secondaryColor = Color.red
    let accentColor = Color(red: 1.0, green: 0.65, blue: 0.0) // Golden orange
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let primaryGradient = LinearGradient(
        colors: [
            Color.orange.opacity(0.9),
            Color.red.opacity(0.8),
            Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.red.opacity(0.8),
            Color.orange.opacity(0.9),
            Color.pink.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.orange, Color.red, Color(red: 1.0, green: 0.65, blue: 0.0), Color.pink]
    
    let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    let titleFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    let bodyFont = Font.system(size: 16, weight: .medium, design: .rounded)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.white.opacity(0.2)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.white.opacity(0.2)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.black.opacity(0.3)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.white.opacity(0.2)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.white
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Vintage Theme
struct VintageTheme: AppTheme {
    let id = "vintage"
    let name = "Vintage"
    
    let primaryColor = Color.brown
    let secondaryColor = Color(red: 0.6, green: 0.5, blue: 0.4) // Sepia
    let accentColor = Color(red: 0.7, green: 0.6, blue: 0.5) // Tan
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let primaryGradient = LinearGradient(
        colors: [
            Color.brown.opacity(0.8),
            Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.7),
            Color(red: 0.7, green: 0.6, blue: 0.5).opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.8),
            Color.brown.opacity(0.7),
            Color(red: 0.5, green: 0.4, blue: 0.3).opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.brown.opacity(0.3), Color(red: 0.6, green: 0.5, blue: 0.4).opacity(0.2)]
    
    // Vintage theme - controlled fonts with sizes 11/10/7-8
    let headerFont = Font.system(size: 11, weight: .semibold, design: .serif)
    let titleFont = Font.system(size: 10, weight: .regular, design: .serif)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .serif)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.brown.opacity(0.3)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.brown.opacity(0.3)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.brown.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.brown.opacity(0.3)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.brown
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Neon Theme
struct NeonTheme: AppTheme {
    let id = "neon"
    let name = "Neon"
    
    let primaryColor = Color.cyan
    let secondaryColor = Color.pink
    let accentColor = Color.purple
    let cardBackground = Color.black.opacity(0.8)
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    let primaryGradient = LinearGradient(
        colors: [
            Color.cyan.opacity(0.9),
            Color.pink.opacity(0.8),
            Color.purple.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.pink.opacity(0.9),
            Color.purple.opacity(0.8),
            Color.cyan.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
        let particleColors = [Color.cyan, Color.pink, Color.purple, Color(red: 1.0, green: 0.0, blue: 1.0)] // Magenta-like color
    
    let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    let titleFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    let bodyFont = Font.system(size: 16, weight: .medium, design: .rounded)
    
    // Glassmorphism (dark with neon borders)
    let glassBackground = Color.black.opacity(0.7)
    let glassBorder = Color.cyan.opacity(0.5) // Neon border
    let glassOverlay = Color.black.opacity(0.1)
    
    // Card Colors
    let cardFill = Color.black.opacity(0.8)
    let cardStroke = Color.cyan.opacity(0.5) // Neon stroke
    let cardShadow = Color.cyan.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.cyan.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 5
    let daySelectorTextShadowColor = Color.white.opacity(0.9)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.black.opacity(0.7)
    let leaderboardCardBorder = Color.cyan.opacity(0.5)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.cyan
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.cyan.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Balanced Theme
struct BalancedTheme: AppTheme {
    let id = "balanced"
    let name = "Balanced"
    
    let primaryColor = Color.green
    let secondaryColor = Color.blue
    let accentColor = Color.teal
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let primaryGradient = LinearGradient(
        colors: [
            Color.green.opacity(0.7),
            Color.blue.opacity(0.6),
            Color.teal.opacity(0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.7),
            Color.teal.opacity(0.6),
            Color.green.opacity(0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.green.opacity(0.2), Color.blue.opacity(0.2), Color.teal.opacity(0.2)]
    
    // Light theme - system default fonts
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.green.opacity(0.3)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.green.opacity(0.3)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.green.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.green.opacity(0.3)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.green
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Consistency Theme
struct ConsistencyTheme: AppTheme {
    let id = "consistency"
    let name = "Consistency"
    
    let primaryColor = Color.indigo
    let secondaryColor = Color.purple
    let accentColor = Color.blue
    let cardBackground = Color.white.opacity(0.9)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    
    let primaryGradient = LinearGradient(
        colors: [
            Color.indigo.opacity(0.8),
            Color.purple.opacity(0.7),
            Color.blue.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [
            Color.purple.opacity(0.8),
            Color.blue.opacity(0.7),
            Color.indigo.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let particleColors = [Color.indigo.opacity(0.2), Color.purple.opacity(0.2), Color.blue.opacity(0.2)]
    
    // Light theme - system default fonts
    let headerFont = Font.system(size: 11, weight: .semibold, design: .default)
    let titleFont = Font.system(size: 10, weight: .regular, design: .default)
    let bodyFont = Font.system(size: 10, weight: .regular, design: .default)
    
    // Glassmorphism
    let glassBackground = Color.white.opacity(0.1)
    let glassBorder = Color.indigo.opacity(0.3)
    let glassOverlay = Color.white.opacity(0.05)
    
    // Card Colors
    let cardFill = Color.white.opacity(0.1)
    let cardStroke = Color.indigo.opacity(0.3)
    let cardShadow = Color.black.opacity(0.3)
    
    let cardCornerRadius: CGFloat = 16
    let cardBorderWidth: CGFloat = 1
    let shadowRadius: CGFloat = 8
    
    let iconCircleSize: CGFloat = 44
    let smallCornerRadius: CGFloat = 12
    let iconBackgroundOpacity: Double = 0.2
    let textSecondaryOpacity: Double = 0.8
    let textTertiaryOpacity: Double = 0.7
    let cardPadding: CGFloat = 16
    let cardVerticalPadding: CGFloat = 12
    let sectionSpacing: CGFloat = 24
    let sectionPadding: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let selectedStrokeWidth: CGFloat = 3
    
    // Day Selector Shadows
    let daySelectorCircleShadowColor = Color.indigo.opacity(0.5)
    let daySelectorCircleShadowRadius: CGFloat = 4
    let daySelectorTextShadowColor = Color.white.opacity(0.8)
    let daySelectorTextShadowRadius: CGFloat = 2
    let daySelectorTextShadowX: CGFloat = 0
    let daySelectorTextShadowY: CGFloat = 1
    
    // Leaderboard Styling
    let leaderboardCardBackground = Color.white.opacity(0.1)
    let leaderboardCardBorder = Color.indigo.opacity(0.3)
    let leaderboardCardBorderWidth: CGFloat = 1
    let leaderboardCardCornerRadius: CGFloat = 12
    let leaderboardCurrentUserBorder = Color.indigo
    let leaderboardCurrentUserBorderWidth: CGFloat = 2.5
    
    // NEW: Accessibility
    let minimumTouchTarget: CGFloat = 44
    let focusRingColor = Color.white.opacity(0.6)
    let focusRingWidth: CGFloat = 2
    
    // NEW: Error & Feedback Colors
    let errorColor = Color.red
    let successColor = Color.green
    let warningColor = Color.orange
    let infoColor = Color.blue
    
    // NEW: Animations
    var buttonPressAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.7)
    }
    var cardLiftAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    var pageTransitionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // NEW: Font Sizes
    let headerFontSize: CGFloat = 11
    let paragraphFontSize: CGFloat = 10
    let smallFontSize: CGFloat = 8
    let headerFontWeight: Font.Weight = .semibold
    let paragraphFontWeight: Font.Weight = .regular
}

// MARK: - Theme Manager
@Observable
class ThemeManager {
    var currentTheme: any AppTheme = PurpleTheme()
    
    private let themes: [any AppTheme] = [
        // Default Themes (Free)
        PurpleTheme(),
        LightTheme(),
        DarkTheme(),
        // Level Unlock Themes
        EnergeticTheme(),
        CalmTheme(),
        // Crystal-Purchasable Shop Themes
        SunsetTheme(),
        VintageTheme(),
        NeonTheme(),
        // Mood-Based Themes
        BalancedTheme(),
        ConsistencyTheme()
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

