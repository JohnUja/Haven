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
    @EnvironmentObject private var authService: FirebaseAuthService
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var showingPasswordChange = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteUsernameEntry = false
    @State private var deleteConfirmationUsername: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color(.systemBackground)
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
                    .font(.system(size: 14, weight: .semibold))
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
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingPasswordChange = true
                }) {
                    HStack {
                        Text("Change Password")
                            .font(.system(size: 16))
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
            .sheet(isPresented: $showingPasswordChange) {
                ChangePasswordView()
                    .environmentObject(authService)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: value)
                .font(.system(size: 16))
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        Button(action: {
            showingDeleteConfirmation = true
        }) {
            Text("DELETE ACCOUNT")
                .font(.system(size: 16, weight: .semibold))
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
            username = "" // TODO: Get from Firestore user document
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
        // Verify username matches (should already be validated in sheet)
        guard deleteConfirmationUsername.lowercased() == username.lowercased() else {
            errorMessage = "Username does not match. Please type your username exactly as shown."
            showingDeleteUsernameEntry = false
            return
        }
        
        isLoading = true
        
        _Concurrency.Task {
            do {
                if let user = authService.currentUser {
                    try await user.delete()
                    await MainActor.run {
                        isLoading = false
                        deleteConfirmationUsername = ""
                        showingDeleteUsernameEntry = false
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
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
    @EnvironmentObject private var authService: FirebaseAuthService
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                } header: {
                    Text("Change Password")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text("Password must be at least 6 characters long")
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
                if let user = authService.currentUser {
                    // Reauthenticate first
                    let credential = EmailAuthProvider.credential(
                        withEmail: user.email ?? "",
                        password: currentPassword
                    )
                    try await user.reauthenticate(with: credential)
                    
                    // Update password
                    try await user.updatePassword(to: newPassword)
                    
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
}

#Preview {
    ProfileEditView()
        .environmentObject(FirebaseAuthService.shared)
}

