//
//  HapticFeedbackHelper.swift
//  Haven2.0
//
//  Consistent haptic feedback throughout the app
//

import UIKit
import SwiftUI

enum HapticType {
    case selection
    case impact(style: UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(type: UINotificationFeedbackGenerator.FeedbackType)
}

class HapticFeedbackHelper {
    static let shared = HapticFeedbackHelper()
    
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    private init() {
        setupGenerators()
    }
    
    private func setupGenerators() {
        impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        
        impactGenerator?.prepare()
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
    }
    
    func trigger(_ type: HapticType) {
        switch type {
        case .selection:
            selectionGenerator?.selectionChanged()
            selectionGenerator?.prepare()
            
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
            
        case .notification(let notificationType):
            notificationGenerator?.notificationOccurred(notificationType)
            notificationGenerator?.prepare()
        }
    }
}

// SwiftUI convenience
extension View {
    func hapticFeedback(_ type: HapticType, onTrigger trigger: Bool) -> some View {
        self.onChange(of: trigger) { _, newValue in
            if newValue {
                HapticFeedbackHelper.shared.trigger(type)
            }
        }
    }
}

