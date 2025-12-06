//
//  ShadowStyle.swift
//  Haven2.0
//
//  Shadow and outline style definitions
//

import SwiftUI

// MARK: - Gamified Number Shadow Effect
struct GamifiedNumberShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.8), radius: 2, x: -1, y: -1)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: -1)
            .shadow(color: .black.opacity(0.8), radius: 2, x: -1, y: 1)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 0)
    }
}

// MARK: - Header Shadow
struct HeaderShadow: ViewModifier {
    let intensity: ShadowIntensity
    
    enum ShadowIntensity {
        case strong    // Page headers
        case medium    // Section headers
        case subtle    // Titles
    }
    
    func body(content: Content) -> some View {
        switch intensity {
        case .strong:
            return content
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
        case .medium:
            return content
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        case .subtle:
            return content
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
    }
}

extension View {
    func gamifiedNumberShadow() -> some View {
        self.modifier(GamifiedNumberShadow())
    }
    
    func headerShadow(intensity: HeaderShadow.ShadowIntensity = .medium) -> some View {
        self.modifier(HeaderShadow(intensity: intensity))
    }
}

