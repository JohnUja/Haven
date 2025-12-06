//
//  ToastManager.swift
//  Haven2.0
//
//  Toast notification queue management
//

import SwiftUI

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double
    
    enum ToastType {
        case success
        case error
        case warning
        case info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }
}

@Observable
class ToastManager {
    var currentToast: ToastMessage?
    private var queue: [ToastMessage] = []
    private var isShowing = false
    
    func show(_ message: String, type: ToastMessage.ToastType, duration: Double = 2.0) {
        let toast = ToastMessage(message: message, type: type, duration: duration)
        
        if isShowing {
            queue.append(toast)
        } else {
            displayToast(toast)
        }
    }
    
    private func displayToast(_ toast: ToastMessage) {
        isShowing = true
        currentToast = toast
        
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.currentToast = nil
            self.isShowing = false
            
            if !self.queue.isEmpty {
                let nextToast = self.queue.removeFirst()
                self.displayToast(nextToast)
            }
        }
    }
}

// SwiftUI View Modifier
struct ToastModifier: ViewModifier {
    @Bindable var toastManager: ToastManager
    let theme: any AppTheme
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    StandardToastView(
                        message: toast.message,
                        type: toast.type,
                        theme: theme
                    )
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(Double(ZIndexConstants.popup))
                }
            }
    }
}

extension View {
    func toastManager(_ manager: ToastManager, theme: any AppTheme) -> some View {
        self.modifier(ToastModifier(toastManager: manager, theme: theme))
    }
}

// Enhanced Toast View
struct StandardToastView: View {
    let message: String
    let type: ToastMessage.ToastType
    let theme: any AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, ToastConstants.paddingH)
        .padding(.vertical, ToastConstants.paddingV)
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                .fill(Color.black.opacity(ToastConstants.backgroundOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                        .stroke(type.color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

