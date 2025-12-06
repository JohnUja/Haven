//
//  AccessibilityExtensions.swift
//  Haven2.0
//
//  Apple HIG Requirements & Accessibility Extensions
//

import SwiftUI

// MARK: - Touch Target Extension (Apple Requirement: 44x44pt minimum)
extension View {
    /// Ensures view meets Apple's minimum touch target requirement (44x44pt)
    func minimumTouchTarget(theme: any AppTheme) -> some View {
        self.frame(minWidth: theme.minimumTouchTarget, minHeight: theme.minimumTouchTarget)
            .contentShape(Rectangle()) // Makes entire area tappable
    }
    
    /// Adds accessibility labels and hints for VoiceOver
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds focus ring for keyboard navigation
    func focusRing(theme: any AppTheme, isFocused: Bool) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.focusRingColor, lineWidth: theme.focusRingWidth)
                .opacity(isFocused ? 1 : 0)
        )
    }
    
    /// Supports Dynamic Type for text scaling
    /// Accepts variadic DynamicTypeSize values and applies them as a range
    func dynamicTypeSize(_ sizes: DynamicTypeSize...) -> some View {
        guard !sizes.isEmpty else { return self }
        
        if sizes.count == 1 {
            // Single size
            return self.dynamicTypeSize(sizes[0])
        } else {
            // Multiple sizes - create a range from min to max
            // DynamicTypeSize conforms to Comparable, so we can sort directly
            let sorted = sizes.sorted()
            return self.dynamicTypeSize(sorted.first!...sorted.last!)
        }
    }
}

// MARK: - Status Bar Style Extension
extension View {
    func statusBarStyle(for theme: any AppTheme) -> some View {
        self.preferredColorScheme(theme.id == "dark" ? .dark : (theme.id == "light" ? .light : nil))
    }
}

