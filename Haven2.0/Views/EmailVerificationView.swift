//
//  EmailVerificationView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Email verification view using Firebase
//

import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isEmailVerified = false
    
    private var userEmail: String? {
        authService.currentUser?.email
    }
    
    private var isVerified: Bool {
        authService.currentUser?.isEmailVerified ?? false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: isVerified ? "checkmark.circle.fill" : "envelope")
                                .font(.system(size: 60))
                                .foregroundColor(isVerified ? .green : themeManager.currentTheme.accentColor)
                            
                            Text(isVerified ? "Email Verified" : "Verify Your Email")
                                .font(themeManager.currentTheme.titleFont)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            
                            if let email = userEmail {
                                Text(email)
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                            
                            if isVerified {
                                Text("Your email address has been verified.")
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                Text("We've sent a verification email to your address. Please check your inbox and click the verification link.")
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Error/Success Messages
                        if let error = errorMessage {
                            Text(error)
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.errorColor)
                                .padding(.horizontal, 20)
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.successColor)
                                .padding(.horizontal, 20)
                        }
                        
                        if !isVerified {
                            // Resend Verification Email Button
                            Button(action: {
                                sendVerificationEmail()
                            }) {
                                Text("Resend Verification Email")
                                    .font(themeManager.currentTheme.bodyFont)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                    .background(themeManager.currentTheme.accentColor)
                                    .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.6 : 1.0)
                            .padding(.horizontal, 20)
                            
                            // Check Verification Status Button
                            Button(action: {
                                checkVerificationStatus()
                            }) {
                                Text("Check Verification Status")
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                    .background(
                                        RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                            .stroke(themeManager.currentTheme.accentColor, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                    )
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.6 : 1.0)
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                }
            }
            .onAppear {
                isEmailVerified = isVerified
            }
        }
    }
    
    private func sendVerificationEmail() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        _Concurrency.Task {
            do {
                try await authService.sendEmailVerification()
                await MainActor.run {
                    isLoading = false
                    successMessage = "Verification email sent! Check your inbox."
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func checkVerificationStatus() {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            do {
                // Reload user to get latest verification status
                try await authService.currentUser?.reload()
                await MainActor.run {
                    isLoading = false
                    isEmailVerified = authService.currentUser?.isEmailVerified ?? false
                    if isEmailVerified {
                        successMessage = "Email verified successfully!"
                    } else {
                        errorMessage = "Email not yet verified. Please check your inbox."
                    }
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

