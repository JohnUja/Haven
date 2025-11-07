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

// --- 2. DELETED 'AuthError' and 'AuthProvider' ENUMS ---
// They are now correctly defined in FirebaseAuthService.swift
// --------------------------------------------------------

struct FirebaseAuthenticationView: View {
    @EnvironmentObject private var authService: FirebaseAuthService
    @Environment(\.modelContext) private var modelContext
    @State private var showError = false
    @State private var showEmailSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    
    // --- This variable will hold the nonce for the *current* Apple Sign-In attempt ---
    @State private var currentAppleNonce: String?
    
    // --- 3. ADDED PLACEHOLDER FOR 'User' and 'Theme' ---
    // This allows the file to compile until your SwiftData models
    // (like User.swift) are correctly imported or defined.
    typealias User = String // Placeholder - REMOVE IF 'User' MODEL IS ACCESSIBLE
    typealias Theme = String // Placeholder - REMOVE IF 'Theme' MODEL IS ACCESSIBLE
    // --------------------------------------------------
    
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
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer()
                        .frame(height: 40)
                        
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
                    
                    if showEmailSignUp {
                        // Email/Password Sign Up Form
                        VStack(spacing: 16) {
                            if isSignUp {
                                TextField("Display Name (Optional)", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.words)
                                    .padding(.horizontal, 20)
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 20)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                _Concurrency.Task {
                                    await handleEmailAuth()
                                }
                            }) {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
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
                            .disabled(email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty && password.count < 6))
                            .opacity((email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty && password.count < 6)) ? 0.6 : 1.0)
                            
                            Button(action: {
                                isSignUp.toggle()
                            }) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Button(action: {
                                showEmailSignUp = false
                            }) {
                                Text("Back to Sign In Options")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // Sign-in Options - All buttons with consistent styling
                        VStack(spacing: 20) {
                            
                            // Apple Sign-In - Official Button (dedicated Apple button)
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    // Create the nonce
                                    let rawNonce = FirebaseAuthService.randomNonceString()
                                    currentAppleNonce = rawNonce
                                    
                                    // Set the nonce on the request
                                    request.requestedScopes = [.fullName, .email]
                                    request.nonce = FirebaseAuthService.sha256(rawNonce)
                                    print("Apple Sign-In: Nonce generated and set")
                                },
                                onCompletion: { result in
                                    // Handle the result
                                    _Concurrency.Task {
                                        await handleAppleSignIn(result: result)
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            
                            // Google Sign-In - Official Button (matching style)
                            GoogleSignInButton(action: {
                                _Concurrency.Task {
                                    await handleGoogleSignIn()
                                }
                            })
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            
                            // Game Center - Matching style button
                            Button(action: {
                                _Concurrency.Task {
                                    await handleGameCenterSignIn()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    // Game Center Logo
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("Continue with Game Center")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
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
                            
                            // Email/Password option - Matching style
                            Button(action: {
                                showEmailSignUp = true
                                isSignUp = false
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 17))
                                    
                                    Text("Continue with Email")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Try as Guest
                            Button(action: {
                                // --- FIX: Use _Concurrency.Task ---
                                _Concurrency.Task {
                                    await handleGuestSignIn()
                                }
                            }) {
                                Text("Try as Guest")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .underline()
                            }
                            .disabled(authService.isLoading)
                            .opacity(authService.isLoading ? 0.6 : 1.0)
                            
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
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Test Account")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
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
                        .frame(height: 40)
                }
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authService.errorMessage ?? "An unknown error occurred")
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
                try await authService.signUp(email: email, password: password, displayName: displayName)
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
        // This function needs to be implemented once your
        // SwiftData 'User' and 'Theme' models are available.
        
        guard let firebaseUser = authService.currentUser else {
            print("createOrUpdateLocalUser: No firebase user found.")
            return
        }
        print("createOrUpdateLocalUser: Logic to create/update local user for \(firebaseUser.uid) goes here.")
        
        // --- Placeholder Logic ---
        // You will need to uncomment and adapt the code below
        // once your SwiftData models are finalized.
        
        /*
        let firebaseUID = firebaseUser.uid
        let fetchDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { $0.id == firebaseUID }
        )
        
        let existingUsers = (try? modelContext.fetch(fetchDescriptor)) ?? []
        
        if let existingUser = existingUsers.first {
            print("Updating existing local user: \(existingUser.id)")
            existingUser.email = firebaseUser.email ?? existingUser.email
            existingUser.name = firebaseUser.displayName ?? existingUser.name
        } else {
            print("Creating new local user: \(firebaseUser.uid)")
            let newUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                name: firebaseUser.displayName ?? "User",
                gamificationCurrency: 100 // Welcome bonus
            )
            modelContext.insert(newUser)
            
            await setupDefaultThemes(for: newUser)
        }
        
        do {
            try modelContext.save()
            print("Local user saved successfully.")
            
            // ... (Sync to Firestore logic) ...
            
        } catch {
            authService.errorMessage = "Failed to save user: \(error.localizedDescription)"
            showError = true
        }
         */
    }
    
    @MainActor
    private func setupDefaultThemes(for user: User) async {
        // This function needs to be implemented once your
        // SwiftData 'Theme' model is available.
        
        print("Setup default themes logic goes here.")
        
        /*
        let themeFetchDescriptor = FetchDescriptor<Theme>()
        let existingThemes = (try? modelContext.fetch(themeFetchDescriptor)) ?? []
        
        if existingThemes.isEmpty {
             let defaultTheme = Theme(
                 name: "Default",
                 themeDescription: "Clean and minimal design",
                 unlockMethod: .defaultTheme,
                 unlockRequirement: "Default theme",
                 isDefault: true
             )
             modelContext.insert(defaultTheme)
             print("Default theme inserted.")
        }
        */
    }
}

