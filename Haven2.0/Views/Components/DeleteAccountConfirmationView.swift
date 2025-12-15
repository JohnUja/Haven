//
//  DeleteAccountConfirmationView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-05.
//  Username confirmation for account deletion
//

import SwiftUI

struct DeleteAccountConfirmationView: View {
    let username: String
    @Binding var confirmationText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(ThemeManager.self) private var themeManager
    
    private var isValid: Bool {
        let normalizedConfirmation = confirmationText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return !normalizedConfirmation.isEmpty && normalizedConfirmation == normalizedUsername
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // Warning Message
                VStack(spacing: 12) {
                    Text("Delete Your Account?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This action cannot be undone. All your data will be permanently deleted.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Username Entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type your username to confirm:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    transparentTextField(
                        placeholder: "Enter username",
                        text: $confirmationText,
                        theme: themeManager.currentTheme
                    )
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                .padding(.horizontal, 24)
                
                // Username Display
                Text("Your username: \(username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isValid ? Color.red : Color.gray)
                            )
                    }
                    .disabled(!isValid)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Confirm Deletion")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DeleteAccountConfirmationView(
        username: "testuser",
        confirmationText: .constant(""),
        onConfirm: {},
        onCancel: {}
    )
}

