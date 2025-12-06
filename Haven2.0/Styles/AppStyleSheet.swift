//
//  AppStyleSheet.swift
//  Haven2.0
//
//  Unified styling system for the entire app
//  Provides consistent fonts, shadows, and spacing
//

import SwiftUI
import UIKit

// MARK: - Text Style Enum
enum TextStyle {
    case pageHeader        // Montserrat, bold, 32pt, dark shadow
    case sectionHeader     // Montserrat, semibold, 20pt, subtle shadow
    case title             // Montserrat, medium, 18pt
    case body              // Monospace, regular, 16pt
    case caption           // Monospace, regular, 12pt
    case gamifiedNumber    // Monospace, bold, 36pt, dark shadow outline
    case taskTitle         // Monospace, semibold, 16pt
    case settingsText      // Monospace, regular, 14pt
    case dayScrollerLabel  // System Rounded, medium, 11pt (preserved)
    case dayScrollerNumber // System Rounded, semibold, 15pt (preserved)
}

// MARK: - App Style Sheet
struct AppStyleSheet {
    
    // MARK: - Fonts (System Default, Semi-bold Headers, Regular Body)
    static func font(for style: TextStyle) -> Font {
        switch style {
        case .pageHeader:
            return .system(size: 32, weight: .semibold, design: .default)
        case .sectionHeader:
            return .system(size: 20, weight: .semibold, design: .default)
        case .title:
            return .system(size: 18, weight: .semibold, design: .default)
        case .body:
            return .system(size: 16, weight: .regular, design: .default)
        case .caption:
            return .system(size: 12, weight: .regular, design: .default)
        case .gamifiedNumber:
            return .system(size: 36, weight: .semibold, design: .default)
        case .taskTitle:
            return .system(size: 16, weight: .semibold, design: .default)
        case .settingsText:
            return .system(size: 14, weight: .regular, design: .default)
        case .dayScrollerLabel:
            return .system(size: 11, weight: .regular, design: .default)
        case .dayScrollerNumber:
            return .system(size: 15, weight: .semibold, design: .default)
        }
    }
    
    // MARK: - Text Color (from theme)
    static func textColor(for style: TextStyle, theme: any AppTheme) -> Color {
        switch style {
        case .pageHeader, .sectionHeader, .title, .taskTitle:
            return theme.textPrimary
        case .body, .caption, .settingsText:
            return theme.textPrimary
        case .gamifiedNumber:
            return theme.textPrimary
        case .dayScrollerLabel, .dayScrollerNumber:
            return theme.textPrimary // Theme-aware, not always white
        }
    }
    
    // MARK: - Glassmorphism Card Modifier
    static func glassCard(theme: any AppTheme) -> some ViewModifier {
        GlassCardModifier(theme: theme)
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    let theme: any AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                    )
            )
    }
}

// MARK: - Convenience View Extension
extension View {
    func appTextStyle(_ style: TextStyle, theme: any AppTheme) -> some View {
        self
            .font(AppStyleSheet.font(for: style))
            .foregroundColor(AppStyleSheet.textColor(for: style, theme: theme))
    }
}

