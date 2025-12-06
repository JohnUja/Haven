//
//  ProfileEditView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-05.
//  Profile editing screen with editable fields
//

import SwiftUI
import FirebaseAuth

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var showingPasswordChange = false
    @State private var showingPasswordReset = false
    @State private var showingEmailVerification = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteUsernameEntry = false
    @State private var deleteConfirmationUsername: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching home screen style
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar Section
                        avatarSection
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                        
                        // Profile Fields
                        profileFieldsSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        
                        // Delete Account Button
                        deleteAccountSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteUsernameEntry = true
                }
            } message: {
                Text("This will permanently delete your account. This action cannot be undone.")
            }
            .sheet(isPresented: $showingDeleteUsernameEntry) {
                DeleteAccountConfirmationView(
                    username: username,
                    confirmationText: $deleteConfirmationUsername,
                    onConfirm: {
                        deleteAccount()
                    },
                    onCancel: {
                        deleteConfirmationUsername = ""
                        showingDeleteUsernameEntry = false
                    }
                )
            }
            .sheet(isPresented: $showingPasswordChange) {
                AccountSecurityView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingEmailVerification) {
                EmailVerificationView()
                    .environmentObject(authService)
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 16) {
            // Avatar Circle with user's photo or custom avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                // User's photo from Firebase Auth (if available)
                if let photoURL = authService.currentUser?.photoURL,
                   let url = URL(string: photoURL.absoluteString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    // Fallback to system icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                }
            }
            
            // Change Avatar Button
            Button(action: {
                // TODO: Implement avatar change (allow custom avatar upload)
                // For now, avatar is from auth provider (Apple/Google/Game Center)
            }) {
                Text("CHANGE AVATAR")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Profile Fields Section
    private var profileFieldsSection: some View {
        VStack(spacing: 20) {
            // Name Field
            profileField(
                label: "Name",
                value: $name,
                placeholder: "Enter your name"
            )
            
            // Username Field
            profileField(
                label: "Username",
                value: $username,
                placeholder: "Enter username"
            )
            
            // Account Security Section (Email & Password)
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Security")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                
                Button(action: {
                    showingPasswordChange = true
                }) {
                    HStack {
                        Label("Email & Password", systemImage: "lock.shield.fill")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .padding(.horizontal, themeManager.currentTheme.cardPadding)
                    .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                    .background(transparentInputBackground(theme: themeManager.currentTheme))
                    .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                }
                
                if authService.canChangeEmail {
                    Button(action: {
                        showingPasswordReset = true
                    }) {
                        HStack {
                            Label("Reset Password", systemImage: "key.fill")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                        .padding(.horizontal, themeManager.currentTheme.cardPadding)
                        .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                        .background(transparentInputBackground(theme: themeManager.currentTheme))
                        .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                    }
                }
            }
            
            // Email Verification Field
            if authService.currentUser?.email != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Verification")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingEmailVerification = true
                    }) {
                        HStack {
                            Text(authService.currentUser?.isEmailVerified == true ? "Email Verified" : "Verify Email")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            
            // Email Field
            profileField(
                label: "Email",
                value: $email,
                placeholder: "Enter email",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            
            // Phone Number Field
            profileField(
                label: "Phone number",
                value: $phoneNumber,
                placeholder: "(XXX) XXX-XXXX",
                keyboardType: .phonePad
            )
        }
    }
    
    // MARK: - Profile Field Helper
    private func profileField(
        label: String,
        value: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
            
            transparentTextField(
                placeholder: placeholder,
                text: value,
                theme: themeManager.currentTheme
            )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        Button(action: {
            showingDeleteConfirmation = true
        }) {
            Text("DELETE ACCOUNT")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Load Profile Data
    private func loadProfileData() {
        if let user = authService.currentUser {
            name = user.displayName ?? ""
            email = user.email ?? ""
            // Use displayName as username for delete account confirmation
            username = user.displayName ?? "User"
            phoneNumber = "" // TODO: Get from Firestore user document
        }
    }
    
    // MARK: - Save Profile
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            do {
                // Update display name in Firebase Auth
                if let user = authService.currentUser {
                    let changeRequest = user.createProfileChangeRequest()
                    if !name.isEmpty {
                        changeRequest.displayName = name
                    }
                    try await changeRequest.commitChanges()
                    
                    // TODO: Update email if changed (requires reauthentication)
                    // TODO: Update username and phone in Firestore
                    // TODO: Update phone number
                    
                    await MainActor.run {
                        isLoading = false
                        dismiss()
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
    
    // MARK: - Delete Account
    private func deleteAccount() {
        // Get the actual display name from Firebase Auth
        let actualDisplayName = authService.currentUser?.displayName ?? ""
        
        // Normalize both strings for comparison (lowercase, trim whitespace)
        let normalizedConfirmation = deleteConfirmationUsername.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDisplayName = actualDisplayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate match
        guard !normalizedConfirmation.isEmpty,
              !normalizedDisplayName.isEmpty,
              normalizedConfirmation == normalizedDisplayName else {
            errorMessage = "Username does not match. Please type your username exactly as shown: \"\(actualDisplayName)\""
            showingDeleteUsernameEntry = false
            // Show error alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingDeleteUsernameEntry = true
            }
            return
        }
        
        isLoading = true
        
        _Concurrency.Task {
            do {
                // Use FirebaseAuthService deleteAccount method
                try await authService.deleteAccount()
                
                // Also delete Firestore user data
                if let uid = authService.currentUser?.uid {
                    let firestoreService = FirestoreService.shared
                    try? await firestoreService.deleteUser(uid: uid)
                }
                    
                    // Clear local data on main thread
                    await MainActor.run {
                        isLoading = false
                        deleteConfirmationUsername = ""
                        showingDeleteUsernameEntry = false
                        dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    deleteConfirmationUsername = ""
                    showingDeleteUsernameEntry = false
                }
            }
        }
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Password Fields Section
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
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                theme: themeManager.currentTheme
                            )
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(.red)
                                    .padding(.top, 8)
                            } else {
                                Text("Password must be at least 6 characters long")
                                    .font(themeManager.currentTheme.bodyFont)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        changePassword()
                    }
                    .disabled(isLoading || newPassword.isEmpty || newPassword != confirmPassword)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword, newPassword.count >= 6 else {
            errorMessage = "Passwords don't match or are too short"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            do {
                try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                    await MainActor.run {
                        isLoading = false
                        dismiss()
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

#Preview {
    ProfileEditView()
        .environmentObject(FirebaseAuthService.shared)
}

