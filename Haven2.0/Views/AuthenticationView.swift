//
//  AuthenticationView.swift
//  TimeFlow
//
//  Created by AI on 2025-11-02.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.7),
                    Color.blue.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo/Icon
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 20)
                    
                    Text("Haven 2.0")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your personal productivity haven")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Sign-in Options - All buttons with consistent styling
                VStack(spacing: 20) {
                    // Sign in with Apple - Official Button (dedicated Apple button)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                // Handle in AuthenticationService delegate
                                break
                            case .failure(let error):
                                authService.errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    )
                    .onAppear {
                        // Set up completion handler for Apple Sign In
                        authService.signInWithApple { [self] authResult in
                            handleAuthResult(result: authResult)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    
                    // Sign in with Google - Matching style
                    Button(action: {
                        handleGoogleSignIn()
                    }) {
                        HStack(spacing: 12) {
                            // Google G icon (you can use SF Symbol or add custom icon)
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.blue, Color.yellow, Color.green],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 24, height: 24)
                                
                                Text("G")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(authService.isLoading)
                    .opacity(authService.isLoading ? 0.6 : 1.0)
                }
                .padding(.horizontal, 40)
                
                // Loading indicator
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding(.top, 20)
                }
                
                // Terms and Privacy
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authService.errorMessage ?? "An unknown error occurred")
        }
    }
    
    
    // MARK: - Google Sign In Handler
    private func handleGoogleSignIn() {
        authService.signInWithGoogle { [self] result in
            handleAuthResult(result: result)
        }
    }
    
    // MARK: - Auth Result Handler
    private func handleAuthResult(result: Result<AuthResult, Error>) {
        switch result {
        case .success(let authResult):
            // Check if user already exists
            if let existingUser = users.first(where: { $0.email == authResult.email }) {
                // Update existing user
                existingUser.name = authResult.name
                // Update auth provider info if needed
            } else {
                // Create new user
                let newUser = User(
                    id: authResult.userID,
                    email: authResult.email,
                    name: authResult.name,
                    gamificationCurrency: 100 // Welcome bonus
                )
                modelContext.insert(newUser)
                
                // Setup default themes for new user
                setupDefaultThemes(for: newUser)
            }
            
            do {
                try modelContext.save()
                authService.isAuthenticated = true
            } catch {
                authService.errorMessage = "Failed to save user: \(error.localizedDescription)"
                showError = true
            }
            
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Setup Default Themes
    private func setupDefaultThemes(for user: User) {
        // Check if themes already exist
        let themeFetchDescriptor = FetchDescriptor<Theme>()
        let existingThemes = (try? modelContext.fetch(themeFetchDescriptor)) ?? []
        
        if existingThemes.isEmpty {
            // Add default theme
            let defaultTheme = Theme(
                name: "Default",
                themeDescription: "Clean and minimal design",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Default theme",
                isDefault: true
            )
            modelContext.insert(defaultTheme)
            
            // Add other themes...
            // (Copy from MainTabView setupDefaultUser logic)
        }
    }
}
