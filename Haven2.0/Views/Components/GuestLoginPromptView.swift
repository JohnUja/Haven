//
//  GuestLoginPromptView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import SwiftUI

struct GuestLoginPromptView: View {
    @Environment(FirebaseAuthService.self) private var authService
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                    onDismiss?()
                }
            
            VStack(spacing: 24) {
                // Celebration icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 20)
                
                Text("You've created your first task! 🎉")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text("Create a free account to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "Save your progress forever")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Create unlimited tasks")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Unlock timeline & routines")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Join leaderboards")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Sync across devices")
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        // Trigger login view - signOut throws, so handle it
                        do {
                            try authService.signOut()
                        } catch {
                            // Silently handle sign out error
                            print("Sign out error: \(error)")
                        }
                    }) {
                        Text("Sign Up Free")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                        onDismiss?()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 16))
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

