//
//  FirebaseAuthService.swift
//  Haven2.0
//
//  Created by John Uja 2025-11-03.
//  Updated by Gemini on 2025-11-05.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit // For NONCE HASHING
import GameKit // For Game Center

// These are required for the new Google Sign-In function
import GoogleSignIn

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredential
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case googleSignInError
    case appleSignInError(String)
    case gameCenterError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredential:
            return "Invalid credentials"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network error. Please try again."
        case .googleSignInError:
            return "Could not get Google ID token or find top view controller."
        case .appleSignInError(let detail):
            return "Apple Sign-In Error: \(detail)"
        case .gameCenterError(let detail):
            return "Game Center Error: \(detail)"
        }
    }
}

// MARK: - Auth Provider
enum AuthProvider: String, Codable {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case anonymous = "anonymous" // For guest mode
    case test = "test" // For testing/demo accounts
    case gameCenter = "gamecenter"
}

// MARK: - Firebase Auth Service
@MainActor
@Observable
class FirebaseAuthService: NSObject {
    static let shared = FirebaseAuthService()
    
    var isAuthenticated = false
    var currentUser: FirebaseAuth.User?
    var isLoading = false
    var errorMessage: String?
    var isGuest = false
    
    nonisolated(unsafe) private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    // NOTE: appleAuthContinuation and currentNonce are no longer needed here,
    // as the view will manage the nonce for the request.
    
    private override init() {
        super.init()
        
        // This is already on the MainActor, so no Task is needed.
        self.checkAuthState()
        
        // Set up auth state listener
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            _Concurrency.Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentUser = user
                self.isAuthenticated = user != nil
                self.isGuest = user?.isAnonymous ?? false
                print("FirebaseAuthService: Auth state changed - authenticated: \(user != nil), guest: \(user?.isAnonymous ?? false)")
                
                // Check developer mode status when auth state changes
                DeveloperModeService.shared.checkDeveloperStatus()
            }
        }
    }
    
    // MARK: - Check Auth State
    
    private func checkAuthState() {
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            self.isGuest = user.isAnonymous
            print("FirebaseAuthService: Restored session - user: \(user.uid), guest: \(user.isAnonymous)")
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isGuest = false
            print("FirebaseAuthService: No existing session")
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Sign In as Guest (Anonymous)
    func signInAsGuest() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            print("FirebaseAuthService: Attempting guest sign-in...")
            let result = try await Auth.auth().signInAnonymously()
            currentUser = result.user
            isAuthenticated = true
            isGuest = true
            print("FirebaseAuthService: Guest sign-in successful - user ID: \(result.user.uid)")
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            print("FirebaseAuthService: Guest sign-in failed - \(errorMsg)")
            print("FirebaseAuthService: Error details - \(error)")
            throw error
        }
    }
    
    // MARK: - Sign In as Test Account (For Testing/Demo)
    func signInAsTestAccount(email: String = "test@haven.app", displayName: String = "Test User") async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: "test123456")
            currentUser = result.user
            isAuthenticated = true
            isGuest = false
            
            if let user = currentUser, user.displayName != displayName {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            
            // Check developer mode status after test account login
            DeveloperModeService.shared.checkDeveloperStatus()
            
        } catch {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: "test123456")
                
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
                
                currentUser = result.user
                isAuthenticated = true
                isGuest = false
            } catch {
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
    
    // MARK: - Sign In with Email & Password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("FirebaseAuthService: Starting email sign-in...")
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FirebaseAuthService: Firebase configured")
        }
        
        do {
            print("FirebaseAuthService: Signing in with email: \(email)")
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            isGuest = false
            print("FirebaseAuthService: Email sign-in successful - user ID: \(result.user.uid)")
        } catch {
            print("FirebaseAuthService: Email sign-in error: \(error)")
            print("FirebaseAuthService: Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Up with Email & Password
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("FirebaseAuthService: Starting email sign-up...")
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FirebaseAuthService: Firebase configured")
        }
        
        // Validate password length
        guard password.count >= 6 else {
            let error = AuthError.weakPassword
            errorMessage = error.localizedDescription
            throw error
        }
        
        do {
            print("FirebaseAuthService: Creating user with email: \(email)")
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name if provided
            if !displayName.isEmpty {
                print("FirebaseAuthService: User created, updating display name...")
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            
            currentUser = result.user
            isAuthenticated = true
            isGuest = false
            print("FirebaseAuthService: Email sign-up successful - user ID: \(result.user.uid)")
        } catch {
            print("FirebaseAuthService: Email sign-up error: \(error)")
            print("FirebaseAuthService: Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign In with Apple (NEW FLOW)
    // This function is now called by the View on successful ASAuthorization
    func continueSignInWithApple(authorization: ASAuthorization, rawNonce: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("FirebaseAuthService: Starting Apple Sign-In flow...")
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FirebaseAuthService: Firebase configured")
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("FirebaseAuthService: Failed to get Apple ID credential")
            throw AuthError.appleSignInError("Invalid Apple credential type.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("FirebaseAuthService: Failed to get Apple ID token")
            throw AuthError.appleSignInError("Failed to get Apple ID token.")
        }
        
        print("FirebaseAuthService: Got Apple ID token, creating credential...")
        
        let fullName = appleIDCredential.fullName
        
        // Use OAuthProvider for Apple Sign-In
        // According to Firebase documentation, use the static method OAuthProvider.appleCredential
        // This is the correct API for Apple Sign-In (not an instance method)
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: fullName
        )
        
        do {
            print("FirebaseAuthService: Signing in with Firebase...")
            let result = try await Auth.auth().signIn(with: credential)
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isGuest = false
            print("FirebaseAuthService: Apple Sign-In successful - user ID: \(result.user.uid)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("FirebaseAuthService: Apple Sign-In Error: \(error)")
            print("FirebaseAuthService: Error details: \(error.localizedDescription)")
            throw error
        }
    }

    
    // MARK: - Sign In with Google (UPDATED & WORKING)
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("FirebaseAuthService: Starting Google Sign-In flow...")
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FirebaseAuthService: Firebase configured")
        }
        
        // Ensure Google Sign-In is configured
        if GIDSignIn.sharedInstance.configuration == nil {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let clientID = plist["CLIENT_ID"] as? String {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                print("FirebaseAuthService: Google Sign-In configured")
            } else {
                print("FirebaseAuthService: ERROR - GoogleService-Info.plist not found or CLIENT_ID missing")
                throw AuthError.googleSignInError
            }
        }
        
        guard let windowScene = await MainActor.run(body: {
            UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        }) else {
            print("FirebaseAuthService: ERROR - No active window scene found")
            throw AuthError.googleSignInError
        }
        
        let window: UIWindow? = await MainActor.run {
            windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
        }
        
        guard let topVC = window?.rootViewController else {
            print("FirebaseAuthService: ERROR - No root view controller found")
            throw AuthError.googleSignInError
        }
        
        do {
            print("FirebaseAuthService: Attempting Google Sign-In...")
            let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
            
            guard let idToken = gidSignInResult.user.idToken?.tokenString else {
                print("FirebaseAuthService: ERROR - No ID token from Google")
                throw AuthError.googleSignInError
            }
            
            print("FirebaseAuthService: Got Google ID token, creating Firebase credential...")
            let accessToken = gidSignInResult.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            print("FirebaseAuthService: Signing in with Firebase...")
            let result = try await Auth.auth().signIn(with: credential)
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isGuest = false
            print("FirebaseAuthService: Google Sign-In successful - user ID: \(result.user.uid)")
            
        } catch {
            print("FirebaseAuthService: Google Sign-In Error: \(error)")
            print("FirebaseAuthService: Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign In with Game Center (UPDATED for Firebase 10.5.0+)
    // Note: Firebase 10.5.0+ automatically uses gamePlayerID/teamPlayerID instead of deprecated playerID
    func signInWithGameCenter() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("FirebaseAuthService: Starting Game Center Sign-In flow...")
        
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FirebaseAuthService: Firebase configured")
        }
        
        do {
            let localPlayer = GKLocalPlayer.local
            
            // Authenticate with Game Center
            // This handler is called multiple times during the auth process
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if localPlayer.isAuthenticated {
                    print("Game Center: Already authenticated")
                    continuation.resume()
                    return
                }
                
                localPlayer.authenticateHandler = { viewController, error in
                    if let vc = viewController {
                        // Present Game Center authentication view controller
                        _Concurrency.Task { @MainActor in
                            let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                            let window = windowScene?.windows.first(where: \.isKeyWindow) ?? windowScene?.windows.first
                            window?.rootViewController?.present(vc, animated: true)
                        }
                        return // Don't resume yet - wait for user interaction
                    } else if localPlayer.isAuthenticated {
                        // Player is now authenticated
                        print("Game Center: Authentication successful")
                        print("Game Center: Player ID: \(localPlayer.gamePlayerID)")
                        print("Game Center: Team Player ID: \(localPlayer.teamPlayerID)")
                        continuation.resume()
                    } else if let error = error {
                        // Error occurred during authentication
                        print("Game Center: Authentication failed - \(error.localizedDescription)")
                        continuation.resume(throwing: AuthError.gameCenterError(error.localizedDescription))
                    } else {
                        // User cancelled or no error but not authenticated
                        print("Game Center: Authentication cancelled or failed silently")
                        continuation.resume(throwing: AuthError.gameCenterError("Please sign in to Game Center in Settings to continue."))
                    }
                }
            }
            
            // Verify player is authenticated before getting credential
            guard localPlayer.isAuthenticated else {
                throw AuthError.gameCenterError("Game Center authentication failed. Please sign in to Game Center in Settings.")
            }
            
            // Get Game Center credential for Firebase
            // Firebase 10.5.0+ automatically uses gamePlayerID/teamPlayerID
            print("FirebaseAuthService: Getting Game Center credential...")
            let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthCredential, Error>) in
                GameCenterAuthProvider.getCredential { credential, error in
                    if let error = error {
                        print("FirebaseAuthService: Failed to get Game Center credential - \(error.localizedDescription)")
                        print("FirebaseAuthService: Error code: \((error as NSError).code)")
                        print("FirebaseAuthService: Error domain: \((error as NSError).domain)")
                        continuation.resume(throwing: error)
                    } else if let credential = credential {
                        print("FirebaseAuthService: Got Game Center credential successfully")
                        continuation.resume(returning: credential)
                    } else {
                        continuation.resume(throwing: AuthError.gameCenterError("Unknown error getting Game Center credential."))
                    }
                }
            }
            
            // Sign in to Firebase with Game Center credential
            print("FirebaseAuthService: Signing in with Firebase...")
            let result = try await Auth.auth().signIn(with: credential)
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isGuest = false
            print("FirebaseAuthService: Game Center sign-in successful - user ID: \(result.user.uid)")
            
        } catch {
            print("FirebaseAuthService: Game Center Sign-In Error: \(error)")
            print("FirebaseAuthService: Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            isGuest = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await user.delete()
            currentUser = nil
            isAuthenticated = false
            isGuest = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Link Guest Account
    func linkAccount(provider: AuthProvider, credential: AuthCredential) async throws {
        guard let user = currentUser, user.isAnonymous else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await user.link(with: credential)
            currentUser = result.user
            isGuest = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Email Verification
    func sendEmailVerification() async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await user.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Change Email (Compatible Version)
    func changeEmail(to newEmail: String, currentPassword: String) async throws {
        guard let user = currentUser, let currentEmail = user.email else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // 1. Reauthenticate first
            let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
            try await user.reauthenticate(with: credential)
            
            // 2. Update Email (Using the older method - warning is acceptable for now)
            // Note: Yellow warning is okay until you upgrade Firebase SDK to 10.18.0+
            try await user.updateEmail(to: newEmail)
            
            // 3. Send verification to the new email manually
            try await user.sendEmailVerification()
            
            print("Email updated to \(newEmail) and verification sent.")
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Provider Helpers
    
    /// Returns true if the user has a password and can use the changeEmail/changePassword functions
    var canChangeEmail: Bool {
        guard let user = currentUser else { return false }
        return user.providerData.contains { $0.providerID == "password" }
    }
    
    /// Returns a nice name for the UI (e.g., "Google", "Apple", "Email")
    var currentProviderDisplayName: String {
        guard let user = currentUser, let providerID = user.providerData.first?.providerID else {
            return "Unknown"
        }
        switch providerID {
        case "google.com": return "Google"
        case "apple.com": return "Apple"
        case "gamecenter", "gc.apple.com": return "Game Center"
        case "password": return "Email"
        default: return providerID.capitalized
        }
    }
    
    // MARK: - Change Password
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw AuthError.userNotFound
        }
        
        guard newPassword.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Reauthenticate first
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            
            // Update password
            try await user.updatePassword(to: newPassword)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Nonce Helper Functions
    // These are now static so the View can call them
    
    /// Generates a random nonce string.
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var randoms: [UInt8] = Array(repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard errorCode == errSecSuccess else {
                fatalError("Unable to generate random bytes")
            }
            
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                
                let index = Int(random) % charset.count
                result.append(charset[index])
                remainingLength -= 1
            }
        }
        return result
    }
    
    /// Hashes a string using SHA256.
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate & PresentationContextProviding
// These extensions are no longer needed, as the view will
// handle the ASAuthorization logic directly.
// We are keeping the class as an NSObject subclass for other potential delegate conformance.

