//
//  AuthenticationService.swift
//  TimeFlow
//
//  Created by AI on 2025-11-02.
//

import Foundation
import SwiftUI
import AuthenticationServices

// MARK: - Authentication Result
struct AuthResult {
    let userID: String
    let email: String
    let name: String
    let provider: AuthProvider // Uses AuthProvider from FirebaseAuthService
    let idToken: String?
    let accessToken: String?
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authCompletion: ((Result<AuthResult, Error>) -> Void)?
    
    // MARK: - Sign in with Apple
    func signInWithApple(completion: @escaping (Result<AuthResult, Error>) -> Void) {
        self.authCompletion = completion
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Sign in with Google (Disabled - Use FirebaseAuthService instead)
    func signInWithGoogle(completion: @escaping (Result<AuthResult, Error>) -> Void) {
        // Google Sign-In is now handled by FirebaseAuthService
        // This method is kept for backward compatibility but disabled
        let error = NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In requires GoogleSignIn SDK. Please use FirebaseAuthService for authentication."])
        completion(.failure(error))
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        
        // Sign out from Apple (handled automatically)
        // Note: Apple Sign In doesn't have an explicit sign out method
        // The user needs to revoke access in Settings > Apple ID > Password & Security > Apps Using Apple ID
    }
    
    // MARK: - Check Authentication Status
    func checkAuthenticationStatus() {
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: KeychainHelper.shared.getAppleUserID() ?? "") { [weak self] state, error in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.isAuthenticated = true
                case .revoked, .notFound:
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                default:
                    self?.isAuthenticated = false
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = NSError(domain: "AuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID credential"])
            isLoading = false
            errorMessage = error.localizedDescription
            authCompletion?(.failure(error))
            return
        }
        
        // Use Swift's concurrency Task explicitly to avoid conflict with SwiftData Task model
        _createConcurrencyTask {
            let userID = appleIDCredential.user
            let email = appleIDCredential.email ?? KeychainHelper.shared.getEmail() ?? ""
            let fullName = appleIDCredential.fullName
            
            var displayName = ""
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                displayName = "\(givenName) \(familyName)"
            } else if let givenName = fullName?.givenName {
                displayName = givenName
            } else {
                displayName = KeychainHelper.shared.getName() ?? "Apple User"
            }
            
            // Store in keychain for future use
            if let identityToken = appleIDCredential.identityToken,
               let identityTokenString = String(data: identityToken, encoding: .utf8) {
                KeychainHelper.shared.saveAppleCredentials(
                    userID: userID,
                    email: email,
                    name: displayName,
                    idToken: identityTokenString
                )
            }
            
            let authResult = AuthResult(
                userID: userID,
                email: email,
                name: displayName,
                provider: .apple,
                idToken: String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8),
                accessToken: nil
            )
            
            self.isLoading = false
            self.isAuthenticated = true
            self.authCompletion?(.success(authResult))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.isLoading = false
        self.errorMessage = error.localizedDescription
        self.authCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.haven2.timeflow"
    
    private init() {}
    
    func saveAppleCredentials(userID: String, email: String, name: String, idToken: String) {
        save(key: "apple_user_id", value: userID)
        save(key: "apple_email", value: email)
        save(key: "apple_name", value: name)
        save(key: "apple_id_token", value: idToken)
    }
    
    func getAppleUserID() -> String? {
        return get(key: "apple_user_id")
    }
    
    func getEmail() -> String? {
        return get(key: "apple_email")
    }
    
    func getName() -> String? {
        return get(key: "apple_name")
    }
    
    private func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
}
