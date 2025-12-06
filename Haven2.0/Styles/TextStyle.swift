//
//  TextStyle.swift
//  Haven2.0
//
//  Text style definitions and modifiers
//

import SwiftUI

// MARK: - Text Style Modifier
struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    let theme: any AppTheme
    
    func body(content: Content) -> some View {
        content
            .font(AppStyleSheet.font(for: style))
            .foregroundColor(AppStyleSheet.textColor(for: style, theme: theme))
    }
}

// MARK: - Convenience Extension
extension Text {
    func styled(_ style: TextStyle, theme: any AppTheme) -> some View {
        self.modifier(TextStyleModifier(style: style, theme: theme))
    }
}

