//
//  UserDetailsView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-13.
//

import SwiftUI
import FirebaseAuth

struct UserDetailsView: View {
    @Environment(FirebaseAuthService.self) var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var displayName: String = ""
    @State private var showingEditName = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account Information") {
                    if let user = authService.currentUser {
                        // Email
                        HStack {
                            Label("Email", systemImage: "envelope.fill")
                            Spacer()
                            Text(user.email ?? "Not provided")
                                .foregroundColor(.secondary)
                        }
                        
                        // Display Name
                        HStack {
                            Label("Display Name", systemImage: "person.fill")
                            Spacer()
                            Text(user.displayName ?? "Not set")
                                .foregroundColor(.secondary)
                        }
                        
                        // Sign-in Method
                        HStack {
                            Label("Sign-in Method", systemImage: "key.fill")
                            Spacer()
                            Text(providerName(user.providerData.first?.providerID ?? ""))
                                .foregroundColor(.secondary)
                        }
                        
                        // User ID
                        HStack {
                            Label("User ID", systemImage: "number")
                            Spacer()
                            Text(user.uid.prefix(8) + "...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        // Account Created
                        if let creationDate = user.metadata.creationDate {
                            HStack {
                                Label("Member Since", systemImage: "calendar")
                                Spacer()
                                Text(creationDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Actions") {
                    Button(action: {
                        showingEditName = true
                    }) {
                        Label("Edit Display Name", systemImage: "pencil")
                    }
                }
            }
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditName) {
                EditDisplayNameView()
                    .environmentObject(authService)
            }
        }
    }
    
    private func providerName(_ providerID: String) -> String {
        switch providerID {
        case "apple.com": return "Apple"
        case "google.com": return "Google"
        case "password": return "Email"
        case "anonymous": return "Guest"
        case "gc.apple.com": return "Game Center"
        default: return providerID
        }
    }
}

struct EditDisplayNameView: View {
    @Environment(FirebaseAuthService.self) var authService
    @Environment(\.dismiss) private var dismiss
    
    // --- THIS WAS MISSING ---
    @Environment(ThemeManager.self) private var themeManager
    // ------------------------
    
    @State private var displayName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Make sure 'transparentTextField' is defined in your project
                    // If not, use a standard TextField("Display Name", text: $displayName)
                    transparentTextField(
                        placeholder: "Display Name",
                        text: $displayName,
                        theme: themeManager.currentTheme
                    )
                    .autocapitalization(.words)
                } header: {
                    Text("Display Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Display Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDisplayName()
                    }
                    .disabled(isLoading || displayName.isEmpty)
                }
            }
            .onAppear {
                displayName = authService.currentUser?.displayName ?? ""
            }
        }
    }
    
    private func saveDisplayName() {
            guard let user = authService.currentUser else { return }
            isLoading = true
            errorMessage = nil
            
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            // Fixed: Added _Concurrency to avoid conflict with your own 'Task' model
            _Concurrency.Task {
                do {
                    try await changeRequest.commitChanges()
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
