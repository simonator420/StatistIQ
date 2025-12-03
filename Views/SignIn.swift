import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FacebookLogin
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    var onLogin: (() -> Void)? = nil
    @State private var currentNonce: String?
    
    @StateObject private var authManager = AuthManager()
    @State private var appleAuthDelegate: AppleAuthDelegate?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with Back Button and Title
                Color(red: 0.12, green: 0.16, blue: 0.27)
                    .ignoresSafeArea(.all, edges: .top)
                    .frame(height: 60)
                    .overlay(
                        HStack(spacing: 20) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .medium))
                            }
                            .padding(.leading, 16)
                            
                            Text("Sign in")
                                .font(.custom("Jost-SemiBold", size: 22))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                            .padding(.leading, 16)
                            .padding(.top, 15),
                        alignment: .topLeading
                    )
                
                // Content
                VStack(spacing: 20) {
                    Text("StatistIQ")
                        .font(.custom("Jost-SemiBold", size: 28))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                        .padding(.top, 135)
                    
                    // Sign in buttons
                    socialSignInButton(title: "Sign in with Google", imageName: "google_icon") {
                        signInWithGoogle()
                    }
                    // Dissabled for now - needed to connect in meta developer center
//                    socialSignInButton(title: "Sign in with Facebook", imageName: "facebook_icon") {
//                        signInWithFacebook()
//                    }
                    //                    socialSignInButton(title: "Sign in with Apple", imageName: "apple.logo") {
                    //                        LoginView()
                    //                    }
                    ZStack {
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                AppleSignInManager.shared.requestAppleAuthorization(request)
                            },
                            onCompletion: { result in
                                handleAppleID(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .cornerRadius(10)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Sign in with Apple")
                                .font(.custom("Jost", size: 16).weight(.medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(red: 0.12, green: 0.16, blue: 0.27))
                        .cornerRadius(10)
                        
                        .allowsHitTesting(false)
                    }
                    .frame(height: 44)
                    
                    // Terms & Privacy text
                    Text(makeAttributedText())
                        .font(.custom("Jost", size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }
    
    
    // Reusable social button
    func socialSignInButton(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        HStack {
            if imageName == "apple.logo" {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(imageName)
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            Text(title)
                .font(.custom("Jost", size: 16).weight(.medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 10) // ✅ stejné zaoblení jako dříve
                .fill(Color(red: 0.12, green: 0.16, blue: 0.27))
        )
        .onTapGesture {
            action() // ✅ vyvolá akci
        }
    }
    
    
    func getRootViewController() -> UIViewController {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController }
            .first ?? UIViewController()
    }
    
    func startAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.presentationContextProvider = getPresentationAnchor()
        controller.performRequests()
    }
    
    func getPresentationAnchor() -> PresentationAnchorProvider {
        PresentationAnchorProvider(rootViewController: getRootViewController())
    }
    
    // Nonce utilities
    func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in charset.randomElement()! })
    }
    
    func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: input.data(using: .utf8)!)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
    
    func handleAppleID(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        if case let .success(auth) = result {
            guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("❌ AppleAuthorization failed: AppleID credential not available")
                alertMessage = "Apple Sign In failed: Credential not available"
                showAlert = true
                isLoading = false
                return
            }
            
            Task {
                do {
                    let authResult = try await authManager.appleAuth(
                        appleIDCredentials,
                        nonce: AppleSignInManager.nonce
                    )
                    
                    guard let authResult = authResult else {
                        await MainActor.run {
                            alertMessage = "Apple Sign In failed: No result"
                            showAlert = true
                            isLoading = false
                        }
                        return
                    }
                    
                    // ✅ Extract user details
                    let uid = authResult.user.uid
                    let email = authResult.user.email ?? appleIDCredentials.email ?? ""
                    
                    // Full name may only be available on first login
                    let fullName = [
                        appleIDCredentials.fullName?.givenName,
                        appleIDCredentials.fullName?.familyName
                    ].compactMap { $0 }.joined(separator: " ")
                    
                    let isNew = authResult.additionalUserInfo?.isNewUser ?? false
                    
                    if isNew {
                        // Create a default username
                        let username = email.isEmpty ? "apple_user\(Int.random(in: 1000...9999))" : email.components(separatedBy: "@").first!
                        
                        saveUserToFirestore(uid: uid, username: username, email: email, name: fullName)
                    } else {
                        fetchUserProfile(uid: uid) { data in
                            if let data = data {
                                print("✅ Returning Apple user: \(data["username"] ?? "Unknown")")
                            }
                        }
                    }
                    
                    await MainActor.run {
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        onLogin?()
                        dismiss()
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        print("❌ AppleAuthorization failed: \(error)")
                        alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        showAlert = true
                        isLoading = false
                    }
                }
            }
        } else if case let .failure(error) = result {
            print("❌ AppleAuthorization failed: \(error)")
            alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
        }
    }
    
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            guard error == nil else {
                print("Google Sign-In failed: \(error!.localizedDescription)")
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In error: \(error.localizedDescription)")
                    return
                }
                guard let authResult = authResult else { return }
                
                let uid = authResult.user.uid
                let email = authResult.user.email ?? ""
                let displayName = authResult.user.displayName ?? user.profile?.name ?? ""
                let isNew = authResult.additionalUserInfo?.isNewUser ?? false
                
                if isNew {
                    let username = email.isEmpty ? "google_user\(Int.random(in: 1000...9999))" : email.components(separatedBy: "@").first!
                    saveUserToFirestore(uid: uid, username: username, email: email, name: displayName)
                }
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                onLogin?()
                dismiss()
            }
        }
    }
    
    // MARK: - Firestore Helpers
    func saveUserToFirestore(uid: String, username: String, email: String, name: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "id": uid,
            "username": username,
            "email": email,
            "name": name,
            "favoriteTeams": [],
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Failed to save user: \(error.localizedDescription)")
            } else {
                print("User saved/updated in Firestore: \(username)")
            }
        }
    }
    
    
    func fetchUserProfile(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch user: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(snapshot?.data())
        }
    }
    
    func signInWithFacebook() {
        let loginManager = LoginManager()
        
        loginManager.logIn(permissions: ["public_profile", "email"], from: getRootViewController()) { result, error in
            if let error = error {
                print("Facebook Login failed: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, !result.isCancelled else {
                print("Facebook Login cancelled by user")
                return
            }
            
            guard let accessToken = AccessToken.current?.tokenString else {
                print("Failed to get Facebook access token")
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In with Facebook failed: \(error.localizedDescription)")
                    return
                }
                
                guard let authResult = authResult else { return }
                let uid = authResult.user.uid
                let email = authResult.user.email ?? ""
                let displayName = authResult.user.displayName ?? ""
                let isNew = authResult.additionalUserInfo?.isNewUser ?? false
                
                if isNew {
                    let username = email.isEmpty ? "fb_user\(Int.random(in: 1000...9999))" : email.components(separatedBy: "@").first!
                    saveUserToFirestore(uid: uid, username: username, email: email, name: displayName)
                } else {
                    fetchUserProfile(uid: uid) { data in
                        if let data = data {
                            print("Returning Facebook user: \(data["username"] ?? "Unknown")")
                        }
                    }
                }
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                onLogin?()
                dismiss()
            }
        }
    }
    
    func makeAttributedText() -> AttributedString {
        var fullText = AttributedString("By signing in you agree with StatistIQ's Privacy Policy and Terms of Use.")
        
        let normalColor = Color.gray
        let linkColor = Color(red: 0.12, green: 0.16, blue: 0.27)
        
        fullText.foregroundColor = normalColor
        
        if let privacyRange = fullText.range(of: "Privacy Policy") {
            fullText[privacyRange].foregroundColor = linkColor
            fullText[privacyRange].link = URL(string: "https://simonator420.github.io/statistiq-legal/privacy.html")!
        }
        
        if let termsRange = fullText.range(of: "Terms of Use") {
            fullText[termsRange].foregroundColor = linkColor
            fullText[termsRange].link = URL(string: "https://simonator420.github.io/statistiq-legal/terms.html")!
        }
        
        return fullText
    }
}

// MARK: - ASAuthorizationController Delegate Wrapper
class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    let nonce: String
    let dismiss: DismissAction
    
    init(nonce: String, dismiss: DismissAction) {
        self.nonce = nonce
        self.dismiss = dismiss
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            print("Failed to get identity token")
            return
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Task {
            do {
                let result = try await Auth.auth().signIn(with: credential)
                print("Apple login successful: \(result.user.uid)")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                dismiss()
            } catch {
                print("Firebase Apple Sign-In failed: \(error.localizedDescription)")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
    }
}

// MARK: - Presentation Anchor Provider
class PresentationAnchorProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let rootViewController: UIViewController
    
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        rootViewController.view.window!
    }
}

#Preview {
    SignInView()
}

