//
//  FirebaseAuthenticationView.swift
//  Haven2.0
//
//  Created by John Uja on 2025-11-03.
//  Updated by John Uja on 2025-11-05.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import GameKit // <-- 1. IMPORT GAMEKIT
import UIKit

// --- 2. DELETED 'AuthError' and 'AuthProvider' ENUMS ---
// They are now correctly defined in FirebaseAuthService.swift
// --------------------------------------------------------

struct FirebaseAuthenticationView: View {
    @Environment(FirebaseAuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var showError = false
    @State private var showRestorePurchasesInfo = false
    @State private var showEmailSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    
    // --- This variable will hold the nonce for the *current* Apple Sign-In attempt ---
    @State private var currentAppleNonce: String?
    
    var body: some View {
        ZStack {
            // Solid black background matching Dynaus reference
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 120) // Increased from 60 to move options lower
                        
                    // App Logo/Icon - matching reference image (three sparkles)
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            // Two smaller purple sparkles
                            Image(systemName: "sparkle")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                            
                            Image(systemName: "sparkle")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                            
                            // Larger pink sparkle
                            Image(systemName: "sparkle")
                                .font(.system(size: 40))
                                .foregroundColor(.pink)
                        }
                        
                        // App name with Montserrat font, white text
                        Text("Haven")
                            .font(AppStyleSheet.font(for: .pageHeader))
                            .foregroundColor(.white)
                        
                        // Tagline with Montserrat font, white text
                        Text("Your personal productivity haven")
                            .font(AppStyleSheet.font(for: .body))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if showEmailSignUp {
                        // Email/Password Sign Up Form (username removed - will be in onboarding)
                        VStack(spacing: 16) {
                            transparentTextField(
                                placeholder: "Email",
                                text: $email,
                                theme: themeManager.currentTheme
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 20)
                            
                            transparentSecureField(
                                placeholder: "Password",
                                text: $password,
                                theme: themeManager.currentTheme
                            )
                            .padding(.horizontal, 20)
                            
                            Button(action: {
                                _Concurrency.Task {
                                    await handleEmailAuth()
                                }
                            }) {
                                // Button text with dark outline
                                ZStack {
                                    // Outline layer
                                    ForEach([-1, 0, 1], id: \.self) { x in
                                        ForEach([-1, 0, 1], id: \.self) { y in
                                            if x != 0 || y != 0 {
                                                Text(isSignUp ? "Sign Up" : "Sign In")
                                                    .font(.system(size: 18, weight: .semibold, design: .rounded)) // Increased from 17
                                                    .foregroundColor(.black.opacity(0.3))
                                                    .offset(x: CGFloat(x), y: CGFloat(y))
                                            }
                                        }
                                    }
                                    // Main text
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded)) // Increased from 17
                                    .foregroundColor(.white)
                                }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 55)
                                    .background(Color.purple)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                            .disabled(email.isEmpty || password.isEmpty || password.count < 6)
                            .opacity((email.isEmpty || password.isEmpty || password.count < 6) ? 0.6 : 1.0)
                            
                            Button(action: {
                                isSignUp.toggle()
                            }) {
                                // Text with dark outline
                                ZStack {
                                    // Outline layer
                                    ForEach([-1, 0, 1], id: \.self) { x in
                                        ForEach([-1, 0, 1], id: \.self) { y in
                                            if x != 0 || y != 0 {
                                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                                    .font(.system(size: 15, weight: .regular, design: .rounded)) // Increased from subheadline
                                                    .foregroundColor(.black.opacity(0.2))
                                                    .offset(x: CGFloat(x), y: CGFloat(y))
                                            }
                                        }
                                    }
                                    // Main text
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                        .font(.system(size: 15, weight: .regular, design: .rounded)) // Increased from subheadline
                                    .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            
                            Button(action: {
                                showEmailSignUp = false
                            }) {
                                // Text with dark outline
                                ZStack {
                                    // Outline layer
                                    ForEach([-1, 0, 1], id: \.self) { x in
                                        ForEach([-1, 0, 1], id: \.self) { y in
                                            if x != 0 || y != 0 {
                                                Text("Back to Sign In Options")
                                                    .font(.system(size: 13, weight: .regular, design: .rounded)) // Increased from caption
                                                    .foregroundColor(.black.opacity(0.2))
                                                    .offset(x: CGFloat(x), y: CGFloat(y))
                                            }
                                        }
                                    }
                                    // Main text
                                Text("Back to Sign In Options")
                                        .font(.system(size: 13, weight: .regular, design: .rounded)) // Increased from caption
                                    .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // Sign-in Options - Custom buttons, smaller, consistent styling
                        VStack(spacing: 12) {
                            
                            // Apple Sign-In - White button with black text
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    let rawNonce = FirebaseAuthService.randomNonceString()
                                    currentAppleNonce = rawNonce
                                    request.requestedScopes = [.fullName, .email]
                                    request.nonce = FirebaseAuthService.sha256(rawNonce)
                                },
                                onCompletion: { result in
                                    _Concurrency.Task {
                                        await handleAppleSignIn(result: result)
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)

                            Button(action: {
                                showRestorePurchasesInfo = true
                            }) {
                                Text("Restore Purchases")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                    .underline()
                            }
                            .padding(.horizontal, 40)
                            
                            // Google Sign-In - Dark grey button with white text
                            Button(action: {
                                _Concurrency.Task {
                                    await handleGoogleSignIn()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    // Google G icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.red, Color.blue, Color.yellow, Color.green],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 20, height: 20)
                                        
                                        Text("G")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(AppStyleSheet.font(for: .body))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            
                            // Game Center - Dark grey button with white text
                            Button(action: {
                                _Concurrency.Task {
                                    await handleGameCenterSignIn()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    // Game Center Logo
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.green)
                                    
                                    Text("Continue with Game Center")
                                        .font(AppStyleSheet.font(for: .body))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            
                            // Email/Password option - Dark grey button with white text
                            Button(action: {
                                showEmailSignUp = true
                                isSignUp = false
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                    
                                    Text("Continue with Email")
                                        .font(AppStyleSheet.font(for: .body))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            
                            // Try as Guest - White underlined text
                            Button(action: {
                                _Concurrency.Task {
                                    await handleGuestSignIn()
                                }
                            }) {
                                Text("Try as Guest")
                                    .font(AppStyleSheet.font(for: .body))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            .disabled(authService.isLoading)
                            .opacity(authService.isLoading ? 0.6 : 1.0)
                            .padding(.horizontal, 40)
                            
                            #if DEBUG
                            // Clear Guest Auth (Development Only - for testing)
                            Button(action: {
                                // --- FIX: Use _Concurrency.Task ---
                                _Concurrency.Task {
                                    await clearGuestAuth()
                                }
                            }) {
                                Text("Clear Guest Auth (Debug)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                                    .underline()
                            }
                            
                            // Test Account (Development Only)
                            Button(action: {
                                // --- FIX: Use _Concurrency.Task ---
                                _Concurrency.Task {
                                    await handleTestAccountSignIn()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "testtube.2")
                                        .foregroundColor(.primary)
                                    
                                    Text("Test Account")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(authService.isLoading)
                            .opacity(authService.isLoading ? 0.6 : 1.0)
                            #endif
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Loading indicator
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(1.5)
                            .padding(.top, 20)
                    }
                    
                    // Terms and Privacy
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authService.errorMessage ?? "An unknown error occurred")
        }
        .alert("Restore Purchases", isPresented: $showRestorePurchasesInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Restore Purchases is available from the sign-in screen so returning users can find it quickly. Full App Store restore support still needs to be connected to billing.")
        }
    }
    
    // MARK: - Sign In Handlers
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        guard let rawNonce = currentAppleNonce else {
            authService.errorMessage = "Apple Sign-In Nonce was missing."
            showError = true
            return
        }
        
        switch result {
        case .success(let authorization):
            do {
                try await authService.continueSignInWithApple(authorization: authorization, rawNonce: rawNonce)
                await createOrUpdateLocalUser()
            } catch {
                authService.errorMessage = error.localizedDescription
                showError = true
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                authService.errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        // Clean up the nonce
        currentAppleNonce = nil
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await authService.signInWithGoogle()
            await createOrUpdateLocalUser()
        } catch {
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleGameCenterSignIn() async {
        do {
            try await authService.signInWithGameCenter()
            await createOrUpdateLocalUser()
        } catch {
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleEmailAuth() async {
        do {
            if isSignUp {
                // Username/displayName will be set in onboarding - pass empty for now
                try await authService.signUp(email: email, password: password, displayName: "")
            } else {
                try await authService.signIn(email: email, password: password)
            }
            await createOrUpdateLocalUser()
        } catch {
            authService.errorMessage = error.localizedDescription
            showError = true
            // --- FIX: Removed stray '.' ---
        }
    }
    
    private func handleGuestSignIn() async {
        print("FirebaseAuthenticationView: Guest sign-in button tapped")
        await clearGuestAuth()
        
        do {
            try await authService.signInAsGuest()
            print("FirebaseAuthenticationView: Guest sign-in successful, creating local user...")
            await createOrUpdateLocalUser()
            print("FirebaseAuthenticationView: Local user created/updated")
        } catch {
            let errorMsg = error.localizedDescription
            print("FirebaseAuthenticationView: Guest sign-in error - \(errorMsg)")
            print("FirebaseAuthenticationView: Full error - \(error)")
            authService.errorMessage = errorMsg
            showError = true
        }
    }
    
    private func handleTestAccountSignIn() async {
        await clearGuestAuth()
        
        do {
            try await authService.signInAsTestAccount()
            await createOrUpdateLocalUser()
        } catch {
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func clearGuestAuth() async {
        if authService.isGuest {
            do {
                try authService.signOut()
                print("FirebaseAuthenticationView: Cleared guest auth")
            } catch {
                print("FirebaseAuthenticationView: Error clearing guest auth: \(error)")
            }
        }
    }
    
    // MARK: - Local User Management
    @MainActor
    private func createOrUpdateLocalUser() async {
        do {
            _ = try await LocalUserProvisioningService.ensureLocalUserExists(in: modelContext)
        } catch {
            authService.errorMessage = "Failed to prepare your local account: \(error.localizedDescription)"
            showError = true
        }
    }
    
    @MainActor
    private func setupDefaultThemes(for user: User) async {
        _ = user
        do {
            _ = try await LocalUserProvisioningService.ensureLocalUserExists(in: modelContext)
        } catch {
            authService.errorMessage = "Failed to sync your themes: \(error.localizedDescription)"
            showError = true
        }
    }
}

