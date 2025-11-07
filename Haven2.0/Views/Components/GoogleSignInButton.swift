//
//  GoogleSignInButton.swift
//  Haven2.0
//
//  Created by AI on 2025-01-13.
//  Updated to use official Google Sign-In button
//

import SwiftUI
import GoogleSignIn
import UIKit

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        // Use the official Google Sign-In button from GoogleSignIn
        GoogleSignInButtonWrapper(action: action)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
    }
}

// Wrapper to use GoogleSignIn's official GIDSignInButton
struct GoogleSignInButtonWrapper: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .light
        
        // Add tap gesture to trigger action when button is tapped
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.buttonTapped))
        button.addGestureRecognizer(tapGesture)
        
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
        // Remove old gesture recognizers and add new one
        if let gestureRecognizers = uiView.gestureRecognizers {
            for gesture in gestureRecognizers {
                if gesture is UITapGestureRecognizer {
                    uiView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.buttonTapped))
        uiView.addGestureRecognizer(tapGesture)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.8), .pink.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        GoogleSignInButton(action: {})
            .padding()
    }
}

