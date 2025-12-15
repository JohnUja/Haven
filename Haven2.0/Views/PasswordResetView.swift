//
//  PasswordResetView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Password reset view using Firebase
//

import SwiftUI
import FirebaseAuth

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            Text("Reset Password")
                                .font(themeManager.currentTheme.titleFont)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            
                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            
                            transparentTextField(
                                placeholder: "Enter your email",
                                text: $email,
                                theme: themeManager.currentTheme
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        }
                        .padding(.horizontal, 20)
                        
                        // Error/Success Messages
                        if let error = errorMessage {
                            Text(error)
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(.green)
                                .padding(.horizontal, 20)
                        }
                        
                        // Send Reset Link Button
                        Button(action: {
                            sendPasswordReset()
                        }) {
                            Text("Send Reset Link")
                                .font(themeManager.currentTheme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                .background(themeManager.currentTheme.accentColor)
                                .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                        }
                        .disabled(isLoading || email.isEmpty)
                        .opacity(isLoading || email.isEmpty ? 0.6 : 1.0)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                }
            }
        }
    }
    
    private func sendPasswordReset() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        _Concurrency.Task {
            do {
                try await authService.sendPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password reset email sent! Check your inbox."
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

