import Foundation
import Firebase
import FirebaseAuth
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        configureAuthStateChanges()
        verifySignInWithAppleID()
    }
    
    // MARK: - Auth State Changes
    private func configureAuthStateChanges() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Task { @MainActor in
                self.user = user
                self.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Anonymous Authentication
    func authenticateAnonymously() async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signInAnonymously()
            return result
        } catch {
            print("FirebaseAuthError: authenticateAnonymously() failed. \(error)")
            throw error
        }
    }
    
    // MARK: - Generic Authentication
    func authenticateUser(credentials: AuthCredential) async throws -> AuthDataResult? {
        if Auth.auth().currentUser != nil {
            return try await linkAccount(credentials: credentials)
        } else {
            return try await signIn(credentials: credentials)
        }
    }
    
    private func signIn(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signIn(with: credentials)
            return result
        } catch {
            print("FirebaseAuthError: signIn(credentials:) failed. \(error)")
            throw error
        }
    }
    
    private func linkAccount(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            guard let user = Auth.auth().currentUser else {
                throw AuthError.noCurrentUser
            }
            let result = try await user.link(with: credentials)
            return result
        } catch {
            print("FirebaseAuthError: linkAccount(credentials:) failed. \(error)")
            throw error
        }
    }
    
    // MARK: - Apple Sign In
    func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> AuthDataResult? {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return nil
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return nil
        }
        
        // Create credentials
        let credentials = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        do {
            return try await authenticateUser(credentials: credentials)
        } catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }
    
    // MARK: - Apple ID Credential Verification
    func verifySignInWithAppleID() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found
                        do {
                            try await self.signOut()
                        } catch {
                            print("FirebaseAuthError: signOut() failed. \(error)")
                        }
                    default:
                        break
                    }
                } catch {
                    print("Error checking Apple ID credential state: \(error)")
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            print("FirebaseAuthError: signOut() failed. \(error)")
            throw error
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        
        do {
            try await user.delete()
        } catch {
            print("FirebaseAuthError: deleteAccount() failed. \(error)")
            throw error
        }
    }
}

// MARK: - Auth Errors
enum AuthError: Error {
    case noCurrentUser
    
    var localizedDescription: String {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        }
    }
}
