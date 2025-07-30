import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo or Title
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: 15) {
                    // Anonymous Sign In Button
                    Button(action: {
                        Task {
                            await signInAnonymously()
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill.questionmark")
                            Text("Continue as Guest")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            AppleSignInManager.shared.requestAppleAuthorization(request)
                        },
                        onCompletion: { result in
                            handleAppleID(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Authentication Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Anonymous Sign In
    @MainActor
    private func signInAnonymously() async {
        isLoading = true
        
        do {
            let result = try await authManager.authenticateAnonymously()
            if result != nil {
                dismiss()
            }
        } catch {
            alertMessage = "Failed to sign in anonymously: \(error.localizedDescription)"
            showAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In Handler
    func handleAppleID(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        if case let .success(auth) = result {
            guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("AppleAuthorization failed: AppleID credential not available")
                alertMessage = "Apple Sign In failed: Credential not available"
                showAlert = true
                isLoading = false
                return
            }
            
            Task {
                do {
                    let result = try await authManager.appleAuth(
                        appleIDCredentials,
                        nonce: AppleSignInManager.nonce
                    )
                    
                    await MainActor.run {
                        if result != nil {
                            dismiss()
                        }
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        print("AppleAuthorization failed: \(error)")
                        alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        showAlert = true
                        isLoading = false
                    }
                }
            }
        }
        else if case let .failure(error) = result {
            print("AppleAuthorization failed: \(error)")
            alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}
