//
//  ThemeHelpers.swift
//  Haven2.0
//
//  Centralized theme helper extensions for consistent styling
//

import SwiftUI

// MARK: - Theme Helper Extensions
extension View {
    /// Apply glassmorphism card styling using theme
    func glassCard(theme: any AppTheme) -> some View {
        self.modifier(AppStyleSheet.glassCard(theme: theme))
    }
    
    /// Apply standard card background with theme colors (no shadows)
    func themedCardBackground(theme: any AppTheme, fill: Color? = nil, stroke: Color? = nil) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(fill ?? theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(stroke ?? theme.glassBorder, lineWidth: theme.cardBorderWidth)
                )
        )
    }
    
    /// Apply theme-aware text color (no shadows)
    func themedText(theme: any AppTheme, style: TextStyle = .body) -> some View {
        self
            .font(AppStyleSheet.font(for: style))
            .foregroundColor(AppStyleSheet.textColor(for: style, theme: theme))
    }
}

// MARK: - Color Helper Extensions
extension Color {
    /// Get theme-aware text color (white in dark mode, black in light mode)
    static func themeText(theme: any AppTheme) -> Color {
        theme.textPrimary
    }
    
    /// Get theme-aware secondary text color
    static func themeTextSecondary(theme: any AppTheme) -> Color {
        theme.textSecondary
    }
}

// MARK: - RoundedRectangle Theme Extension
extension RoundedRectangle {
    /// Create a RoundedRectangle with theme corner radius
    static func themed(theme: any AppTheme) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
    }
}

