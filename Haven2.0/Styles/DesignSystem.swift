//
//  DesignSystem.swift
//  Haven2.0
//
//  Reusable design system components for consistent UI
//

import SwiftUI
import AudioToolbox

// MARK: - Standard Button Modifier
struct StandardButtonStyle: ViewModifier {
    let theme: any AppTheme
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(buttonTextColor(for: theme))
            .padding(.vertical, 10)
            .padding(.horizontal, theme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                    .stroke(buttonOutlineColor(for: theme), lineWidth: theme.cardBorderWidth)
            )
            .opacity(isDisabled ? OpacityConstants.disabled : 1.0)
    }
    
    private func buttonOutlineColor(for theme: any AppTheme) -> Color {
        return theme.cardStroke
    }
    
    private func buttonTextColor(for theme: any AppTheme) -> Color {
        return theme.textPrimary
    }
}

extension View {
    func standardButton(theme: any AppTheme, isDisabled: Bool = false) -> some View {
        self.modifier(StandardButtonStyle(theme: theme, isDisabled: isDisabled))
    }
}

// MARK: - Standard Card Modifier
struct StandardCardModifier: ViewModifier {
    let theme: any AppTheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, theme.cardPadding)
            .padding(.vertical, theme.cardVerticalPadding)
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

extension View {
    func standardCard(theme: any AppTheme) -> some View {
        self.modifier(StandardCardModifier(theme: theme))
    }
}

// MARK: - Standard Badge View
struct StandardBadge: View {
    let text: String
    let size: BadgeSize
    let color: Color
    let theme: any AppTheme
    
    enum BadgeSize {
        case small
        case medium
        
        var frameSize: CGFloat {
            switch self {
            case .small: return BadgeConstants.smallSize
            case .medium: return BadgeConstants.mediumSize
            }
        }
        
        var textSize: CGFloat {
            switch self {
            case .small: return BadgeConstants.smallTextSize
            case .medium: return BadgeConstants.mediumTextSize
            }
        }
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size.frameSize, height: size.frameSize)
            .overlay(
                Text(text)
                    .font(.system(size: size.textSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Standard Progress Bar
struct StandardProgressBar: View {
    let progress: CGFloat  // 0.0 to 1.0
    let height: ProgressBarHeight
    let theme: any AppTheme
    
    enum ProgressBarHeight {
        case thin
        case standard
        case thick
        
        var height: CGFloat {
            switch self {
            case .thin: return ProgressBarConstants.thin
            case .standard: return ProgressBarConstants.standard
            case .thick: return ProgressBarConstants.thick
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .thin: return ProgressBarConstants.thinCornerRadius
            case .standard: return ProgressBarConstants.standardCornerRadius
            case .thick: return ProgressBarConstants.thickCornerRadius
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height.cornerRadius)
                    .fill(theme.glassBorder.opacity(OpacityConstants.subtleBorder))
                    .frame(height: height.height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: height.cornerRadius)
                    .fill(theme.textPrimary)
                    .frame(width: geometry.size.width * progress, height: height.height)
            }
        }
        .frame(height: height.height)
    }
}

// MARK: - Standard Empty State
struct StandardEmptyState: View {
    let icon: String
    let title: String
    let description: String?
    let theme: any AppTheme
    let isHero: Bool
    
    init(icon: String, title: String, description: String? = nil, theme: any AppTheme, isHero: Bool = false) {
        self.icon = icon
        self.title = title
        self.description = description
        self.theme = theme
        self.isHero = isHero
    }
    
    var body: some View {
        VStack(spacing: EmptyStateConstants.spacingAfterIcon) {
            Image(systemName: icon)
                .font(.system(size: isHero ? EmptyStateConstants.heroIconSize : EmptyStateConstants.standardIconSize))
                .foregroundColor(theme.textPrimary.opacity(EmptyStateConstants.iconOpacity))
            
            Text(title)
                .appTextStyle(.sectionHeader, theme: theme)
            
            if let description = description {
                Text(description)
                    .appTextStyle(.body, theme: theme)
                    .opacity(theme.textSecondaryOpacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EmptyStateConstants.horizontalPadding)
            }
        }
        .padding(.horizontal, EmptyStateConstants.horizontalPadding)
        .padding(.vertical, EmptyStateConstants.verticalPadding)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Standard Pill/Badge View
struct StandardPill: View {
    let text: String
    let size: PillSize
    let backgroundColor: Color
    let textColor: Color
    
    enum PillSize {
        case small
        case medium
        
        var height: CGFloat {
            switch self {
            case .small: return PillConstants.smallHeight
            case .medium: return PillConstants.mediumHeight
            }
        }
        
        var paddingH: CGFloat {
            switch self {
            case .small: return PillConstants.smallPaddingH
            case .medium: return PillConstants.mediumPaddingH
            }
        }
        
        var paddingV: CGFloat {
            switch self {
            case .small: return PillConstants.smallPaddingV
            case .medium: return PillConstants.mediumPaddingV
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10  // .caption2
            case .medium: return 12  // .caption
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .medium, design: .default))
            .foregroundColor(textColor)
            .padding(.horizontal, size.paddingH)
            .padding(.vertical, size.paddingV)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Standard Loading Indicator
struct StandardLoadingIndicator: View {
    let theme: any AppTheme
    let size: LoadingSize
    
    enum LoadingSize {
        case standard
        case large
        
        var scale: CGFloat {
            switch self {
            case .standard: return 1.0
            case .large: return 1.5
            }
        }
    }
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
            .scaleEffect(size.scale)
    }
}

// MARK: - Standard Divider
struct StandardDivider: View {
    let theme: any AppTheme
    let leadingPadding: CGFloat
    
    init(theme: any AppTheme, leadingPadding: CGFloat = 0) {
        self.theme = theme
        self.leadingPadding = leadingPadding
    }
    
    var body: some View {
        Divider()
            .background(theme.glassBorder.opacity(OpacityConstants.subtleBorder))
            .padding(.leading, leadingPadding)
    }
}

// MARK: - Standard Popup Overlay
struct StandardPopupOverlay<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    let theme: any AppTheme
    
    init(theme: any AppTheme, onDismiss: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(OpacityConstants.overlayBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(AnimationConstants.standardSpring) {
                        onDismiss()
                    }
                }
            
            // Content
            content
                .standardCard(theme: theme)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Standard Sheet Modifier
struct StandardSheetModifier: ViewModifier {
    let theme: any AppTheme
    let detent: PresentationDetent
    
    func body(content: Content) -> some View {
        content
            .presentationDetents([detent])
            .presentationDragIndicator(.visible)
            .background(theme.primaryGradient.ignoresSafeArea())
    }
}

extension View {
    func standardSheet(theme: any AppTheme, detent: PresentationDetent = .medium) -> some View {
        self.modifier(StandardSheetModifier(theme: theme, detent: detent))
    }
}

// MARK: - Standard Toolbar Button
struct StandardToolbarButton: View {
    let title: String
    let action: () -> Void
    let theme: any AppTheme
    let isPrimary: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isPrimary ? .semibold : .regular, design: .default))
                .foregroundColor(theme.textPrimary)
        }
    }
}

// MARK: - Standard Icon Button
struct StandardIconButton: View {
    let icon: String
    let size: IconSize
    let theme: any AppTheme
    let action: () -> Void
    
    enum IconSize {
        case small
        case medium
        case large
        
        var frameSize: CGFloat {
            switch self {
            case .small: return IconConstants.small
            case .medium: return IconConstants.medium
            case .large: return IconConstants.large
            }
        }
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 32
            case .large: return 44
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.frameSize, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .frame(width: size.circleSize, height: size.circleSize)
                .background(
                    Circle()
                        .fill(theme.glassBackground.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                        )
                )
        }
    }
}

// MARK: - Standard Priority Indicator
struct StandardPriorityIndicator: View {
    let priority: PriorityType
    let size: CGFloat = 8
    
    var body: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: size, height: size)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .green
        case .low: return .blue
        }
    }
}

// MARK: - Standard Toast View
struct StandardToast: View {
    let message: String
    let theme: any AppTheme
    let duration: Double
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(.white)
            .padding(.horizontal, ToastConstants.paddingH)
            .padding(.vertical, ToastConstants.paddingV)
            .background(
                RoundedRectangle(cornerRadius: ToastConstants.cornerRadius)
                    .fill(Color.black.opacity(ToastConstants.backgroundOpacity))
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.2)) {
                    isVisible = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }
            }
    }
}

// MARK: - Transparent Input Field Helpers
/// Shared transparent text field styling for consistent input fields across the app
func transparentTextField(
    placeholder: String,
    text: Binding<String>,
    theme: any AppTheme,
    axis: Axis = .horizontal,
    lineLimit: ClosedRange<Int>? = nil
) -> some View {
    Group {
        if let lineLimit = lineLimit {
            TextField("", text: text, axis: axis) // Empty placeholder to avoid duplicate
                .lineLimit(lineLimit)
        } else {
            TextField("", text: text) // Empty placeholder to avoid duplicate
        }
    }
    .font(.system(size: 16, weight: .regular, design: .default))
    .foregroundColor(theme.textPrimary)
    .accentColor(theme.accentColor)
    .padding(.horizontal, theme.cardPadding)
    .padding(.vertical, theme.cardVerticalPadding)
    .background(transparentInputBackground(theme: theme))
    .cornerRadius(theme.smallCornerRadius)
    .placeholder(when: text.wrappedValue.isEmpty) {
        Text(placeholder)
            .foregroundColor(theme.textSecondary.opacity(0.8)) // Increased opacity for better visibility
            .font(.system(size: 16, weight: .regular, design: .default))
    }
}

// Helper extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

/// Shared transparent text editor styling for multi-line text input
func transparentTextEditor(
    text: Binding<String>,
    theme: any AppTheme,
    placeholder: String? = nil,
    minHeight: CGFloat = 80
) -> some View {
    ZStack(alignment: .topLeading) {
        if let placeholder = placeholder, text.wrappedValue.isEmpty {
            Text(placeholder)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(theme.textSecondary.opacity(0.8)) // Increased opacity for better visibility
                .padding(.horizontal, theme.cardPadding) // Same spacing as text
                .padding(.vertical, theme.cardVerticalPadding) // Same spacing as text
        }
        TextEditor(text: text)
            .font(.system(size: 16, weight: .regular, design: .default))
            .foregroundColor(theme.textPrimary)
            .scrollContentBackground(.hidden) // Hide default TextEditor background
            .frame(minHeight: minHeight)
            .padding(.horizontal, theme.cardPadding)
            .padding(.vertical, theme.cardVerticalPadding)
    }
    .background(transparentInputBackground(theme: theme))
    .cornerRadius(theme.smallCornerRadius)
}

/// Shared transparent secure field styling (for passwords)
func transparentSecureField(
    placeholder: String,
    text: Binding<String>,
    theme: any AppTheme
) -> some View {
    SecureField(placeholder, text: text)
        .font(.system(size: 16, weight: .regular, design: .default))
        .foregroundColor(theme.textPrimary)
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding)
        .background(transparentInputBackground(theme: theme))
        .cornerRadius(theme.smallCornerRadius)
}

/// Shared transparent input background styling
func transparentInputBackground(theme: any AppTheme) -> some View {
    // Light theme: white/light grey, Dark theme: dark grey, Purple: translucent
    let backgroundColor: Color = {
        switch theme.id {
        case "light":
            return Color.white.opacity(0.9)
        case "dark":
            return Color.gray.opacity(0.3)
        default:
            return theme.glassBackground.opacity(0.5)
        }
    }()
    
    return backgroundColor
        .overlay(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .stroke(theme.glassBorder.opacity(0.5), lineWidth: theme.cardBorderWidth)
        )
}

// MARK: - Standard Error View
struct StandardErrorView: View {
    let message: String
    let theme: any AppTheme
    let type: ErrorType
    
    enum ErrorType {
        case error
        case success
        case warning
        case info
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .error: return Color.red
            case .success: return Color.green
            case .warning: return Color.orange
            case .info: return Color.blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, theme.cardPadding)
        .padding(.vertical, theme.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .stroke(type.color.opacity(0.3), lineWidth: theme.cardBorderWidth)
                )
        )
    }
}

// MARK: - Skeleton Loader (for better perceived performance)
struct SkeletonCard: View {
    let theme: any AppTheme
    let height: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground.opacity(0.3))
            .frame(height: height)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.glassBorder.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Interactive Card (with press feedback)
struct InteractiveCard<Content: View>: View {
    let content: Content
    let theme: any AppTheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(theme: any AppTheme, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            HapticFeedbackHelper.shared.trigger(.selection)
            action()
        }) {
            content
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(theme.buttonPressAnimation, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Icon Style Extension
extension Image {
    func appIconStyle(size: IconSize, theme: any AppTheme) -> some View {
        self.font(.system(size: size.frameSize, weight: .medium))
            .foregroundColor(theme.textPrimary)
            .symbolRenderingMode(.hierarchical)
    }
    
    enum IconSize {
        case small
        case medium
        case large
        
        var frameSize: CGFloat {
            switch self {
            case .small: return IconConstants.small
            case .medium: return IconConstants.medium
            case .large: return IconConstants.large
            }
        }
    }
}

