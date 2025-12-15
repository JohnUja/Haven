//
//  AccountSecurityView.swift
//  Haven2.0
//
//  Unified view for email and password management
//

import SwiftUI
import FirebaseAuth

struct AccountSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var newEmail: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var activeSection: SecuritySection = .password
    
    enum SecuritySection {
        case password
        case email
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Provider Status (Informational)
                        providerStatusSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Section Selector
                        if authService.canChangeEmail {
                            sectionSelector
                                .padding(.horizontal, 20)
                            
                            // Password Section
                            if activeSection == .password {
                                passwordSection
                                    .padding(.horizontal, 20)
                            }
                            
                            // Email Section
                            if activeSection == .email {
                                emailSection
                                    .padding(.horizontal, 20)
                            }
                        } else {
                            // Social sign-in users
                            socialSignInMessage
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationTitle("Account Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading || !canSave)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let email = authService.currentUser?.email {
                    newEmail = email
                }
            }
        }
    }
    
    // MARK: - Provider Status Section
    @ViewBuilder
    private var providerStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIGN-IN METHOD")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                .textCase(.uppercase)
            
            HStack {
                Label("Signed in with \(authService.currentProviderDisplayName)", systemImage: authService.canChangeEmail ? "envelope.fill" : "lock.fill")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Spacer()
                
                if authService.canChangeEmail {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .padding(.horizontal, themeManager.currentTheme.cardPadding)
            .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
            .background(transparentInputBackground(theme: themeManager.currentTheme))
            .cornerRadius(themeManager.currentTheme.smallCornerRadius)
            
            if !authService.canChangeEmail {
                Text("To change your email or password, please update your account settings in \(authService.currentProviderDisplayName).")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.horizontal, themeManager.currentTheme.cardPadding)
            }
        }
    }
    
    // MARK: - Section Selector
    @ViewBuilder
    private var sectionSelector: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    activeSection = .password
                }
            }) {
                Text("Password")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(activeSection == .password ? .white : themeManager.currentTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                            .fill(activeSection == .password ? themeManager.currentTheme.accentColor : themeManager.currentTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                    .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                            )
                    )
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    activeSection = .email
                }
            }) {
                Text("Email")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(activeSection == .email ? .white : themeManager.currentTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                            .fill(activeSection == .email ? themeManager.currentTheme.accentColor : themeManager.currentTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                    .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                            )
                    )
            }
        }
    }
    
    // MARK: - Password Section
    @ViewBuilder
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHANGE PASSWORD")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                .textCase(.uppercase)
            
            transparentSecureField(
                placeholder: "Current Password",
                text: $currentPassword,
                theme: themeManager.currentTheme
            )
            
            transparentSecureField(
                placeholder: "New Password",
                text: $newPassword,
                theme: themeManager.currentTheme
            )
            
            transparentSecureField(
                placeholder: "Confirm New Password",
                text: $confirmPassword,
                theme: themeManager.currentTheme
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            } else if let success = successMessage {
                Text(success)
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(.green)
                    .padding(.top, 8)
            } else {
                Text("Password must be at least 6 characters long")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Email Section
    @ViewBuilder
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHANGE EMAIL")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                .textCase(.uppercase)
            
            // Current Email (Read-only)
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Email")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                
                Text(authService.currentUser?.email ?? "Not available")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.horizontal, themeManager.currentTheme.cardPadding)
                    .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                    .background(transparentInputBackground(theme: themeManager.currentTheme))
                    .cornerRadius(themeManager.currentTheme.smallCornerRadius)
            }
            
            transparentSecureField(
                placeholder: "Current Password (for verification)",
                text: $currentPassword,
                theme: themeManager.currentTheme
            )
            
            transparentTextField(
                placeholder: "New Email",
                text: $newEmail,
                theme: themeManager.currentTheme
            )
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            
            if let error = errorMessage {
                Text(error)
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            } else if let success = successMessage {
                Text(success)
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(.green)
                    .padding(.top, 8)
            } else {
                Text("A verification email will be sent to your new email address")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Social Sign-In Message
    @ViewBuilder
    private var socialSignInMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.accentColor)
            
            Text("Email & Password Managed by \(authService.currentProviderDisplayName)")
                .font(themeManager.currentTheme.titleFont)
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("To change your email or password, please update your account settings in \(authService.currentProviderDisplayName).")
                .font(themeManager.currentTheme.bodyFont)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Validation
    private var canSave: Bool {
        if activeSection == .password {
            return !currentPassword.isEmpty && 
                   !newPassword.isEmpty && 
                   newPassword == confirmPassword && 
                   newPassword.count >= 6
        } else {
            return !currentPassword.isEmpty && 
                   !newEmail.isEmpty && 
                   newEmail != authService.currentUser?.email &&
                   newEmail.contains("@")
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        _Concurrency.Task {
            do {
                if activeSection == .password {
                    try await authService.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword
                    )
                    await MainActor.run {
                        isLoading = false
                        successMessage = "Password changed successfully!"
                        // Clear fields after success
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    }
                } else {
                    try await authService.changeEmail(
                        to: newEmail,
                        currentPassword: currentPassword
                    )
                    await MainActor.run {
                        isLoading = false
                        successMessage = "Verification email sent to \(newEmail). Please check your inbox to complete the change."
                        // Clear password field
                        currentPassword = ""
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



