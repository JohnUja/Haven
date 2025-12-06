//
//  TypographyExtensions.swift
//  Haven2.0
//
//  Consistent typography system
//

import SwiftUI

extension Text {
    func appHeaderStyle(theme: any AppTheme) -> some View {
        self.font(.system(size: theme.headerFontSize, weight: theme.headerFontWeight, design: .default))
            .foregroundColor(theme.textPrimary)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5) // Support all sizes
    }
    
    func appParagraphStyle(theme: any AppTheme) -> some View {
        self.font(.system(size: theme.paragraphFontSize, weight: theme.paragraphFontWeight, design: .default))
            .foregroundColor(theme.textPrimary)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
    
    func appSmallStyle(theme: any AppTheme) -> some View {
        self.font(.system(size: theme.smallFontSize, weight: .regular, design: .default))
            .foregroundColor(theme.textSecondary)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}

