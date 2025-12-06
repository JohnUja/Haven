//
//  DesignConstants.swift
//  Haven2.0
//
//  Standard design constants for consistent UI throughout the app
//

import SwiftUI
import AudioToolbox

// MARK: - Opacity Constants
struct OpacityConstants {
    static let disabled: Double = 0.6
    static let secondaryText: Double = 0.7
    static let tertiaryText: Double = 0.5
    static let overlayBackground: Double = 0.3
    static let completedItem: Double = 0.7
    static let subtleBorder: Double = 0.3
}

// MARK: - Z-Index Constants
struct ZIndexConstants {
    static let background: Int = 0
    static let content: Int = 1
    static let floating: Int = 100
    static let dragging: Int = 1000
    static let overlay: Int = 999
    static let popup: Int = 1001
    static let tooltip: Int = 1002
}

// MARK: - Animation Constants
struct AnimationConstants {
    static let quick: Double = 0.2
    static let standard: Double = 0.3
    static let smooth: Double = 0.4
    static let slow: Double = 0.6
    
    static var quickSpring: Animation {
        .spring(response: quick, dampingFraction: 0.7)
    }
    
    static var standardSpring: Animation {
        .spring(response: standard, dampingFraction: 0.7)
    }
    
    static var smoothSpring: Animation {
        .spring(response: smooth, dampingFraction: 0.8)
    }
    
    static var slowSpring: Animation {
        .spring(response: slow, dampingFraction: 0.8)
    }
}

// MARK: - Badge/Notification Sizes
struct BadgeConstants {
    static let smallSize: CGFloat = 12  // Tab bar badges
    static let mediumSize: CGFloat = 16  // In-app notifications
    static let smallTextSize: CGFloat = 8
    static let mediumTextSize: CGFloat = 10
    static let smallOffsetX: CGFloat = 8
    static let smallOffsetY: CGFloat = -8
    static let mediumOffsetX: CGFloat = 6
    static let mediumOffsetY: CGFloat = -6
}

// MARK: - Progress Bar Heights
struct ProgressBarConstants {
    static let thin: CGFloat = 4  // Inline, compact
    static let standard: CGFloat = 8  // Cards, detail views
    static let thick: CGFloat = 12  // Profile, major progress
    
    static let thinCornerRadius: CGFloat = 2
    static let standardCornerRadius: CGFloat = 4
    static let thickCornerRadius: CGFloat = 8
}

// MARK: - Empty State Constants
struct EmptyStateConstants {
    static let standardIconSize: CGFloat = 48
    static let heroIconSize: CGFloat = 60
    static let iconOpacity: Double = 0.5
    static let horizontalPadding: CGFloat = 40
    static let verticalPadding: CGFloat = 80
    static let spacingAfterIcon: CGFloat = 16
    static let spacingAfterTitle: CGFloat = 12
}

// MARK: - Pill/Badge/Tag Sizes
struct PillConstants {
    static let smallHeight: CGFloat = 20
    static let mediumHeight: CGFloat = 24
    static let smallPaddingH: CGFloat = 6
    static let smallPaddingV: CGFloat = 2
    static let mediumPaddingH: CGFloat = 8
    static let mediumPaddingV: CGFloat = 4
}

// MARK: - Icon Sizes
struct IconConstants {
    static let extraSmall: CGFloat = 10  // Inline indicators
    static let small: CGFloat = 12  // Badges, small buttons
    static let medium: CGFloat = 14  // Standard buttons, inline
    static let large: CGFloat = 18  // Header icons, primary actions
    static let extraLarge: CGFloat = 24  // Category icons, main actions
    static let hero: CGFloat = 48  // Empty states, feature icons
}

// MARK: - List/Row Constants
struct ListConstants {
    static let minimumRowHeight: CGFloat = 44  // Touch target
    static let standardRowHeight: CGFloat = 56
    static let rowPaddingV: CGFloat = 12
    static let rowPaddingH: CGFloat = 16  // Use theme.cardPadding
}

// MARK: - Toast/Notification Constants
struct ToastConstants {
    static let cornerRadius: CGFloat = 12  // Use theme.smallCornerRadius
    static let paddingH: CGFloat = 12
    static let paddingV: CGFloat = 8
    static let infoDuration: Double = 2.0
    static let actionDuration: Double = 5.0
    static let backgroundOpacity: Double = 0.85
}

// MARK: - Haptic Feedback IDs
struct HapticConstants {
    static let lightTap: SystemSoundID = 1520  // Selection
    static let medium: SystemSoundID = 1519  // Drag start
    static let heavy: SystemSoundID = 1057  // Confirmation/important
    static let tink: SystemSoundID = 1104  // Completion
}

// MARK: - Long Press Durations
struct GestureConstants {
    static let longPressMinimum: Double = 0.3  // Standard long press
    static let dragLongPressMinimum: Double = 0.5  // Drag gesture
}

// MARK: - Accessibility Constants
struct AccessibilityConstants {
    static let minimumTouchTarget: CGFloat = 44  // Apple HIG requirement
    static let focusRingWidth: CGFloat = 2
    static let focusRingOpacity: Double = 0.6
}

// MARK: - Error State Constants
struct ErrorStateConstants {
    static let iconSize: CGFloat = 24
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
}

// MARK: - Skeleton Loader Constants
struct SkeletonConstants {
    static let animationDuration: Double = 1.5
    static let shimmerOpacity: Double = 0.3
}

