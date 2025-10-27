import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLogoutMessage = false
    
    @State private var showEditProfile = false
    var onUsernameChanged: ((String) -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            VStack{
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
                            
                            Text("Settings")
                                .font(.custom("Jost-SemiBold", size: 22))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                            .padding(.leading, 16)
                            .padding(.top, 15),
                        alignment: .topLeading
                    )
                ScrollView {
                    VStack(spacing: 0) {
                        settingsRow(icon:"gear", title: "System Settings") {
                            openSystemSettings()
                        }
                        
                        if isLoggedIn {
                            Divider()
                            settingsRow(icon: "pencil", title: "Edit Profile") {
                                showEditProfile = true
                            }
                        }
                        
                        Divider()
                        // TODO: Change links on whole page to point at correct link
                        settingsRow(icon: "star.fill", title: "Rate us") {
                            if let url =
                                //URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review"),
                                URL(string: "https://apple.com"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                        
                        settingsRow(icon: "square.and.arrow.up", title: "Share", action: {showShareSheet = true})
                        
                        Divider()
                        
                        settingsRow(icon: "doc.text", title: "Terms & Conditions") {
                            if let url = URL(string: "https://simonsalaj.com/statistiq/terms-and-condition"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                        
                        settingsRow(icon: "lock.doc", title: "Privacy Policy") {
                            if let url = URL(string: "https://simonsalaj.com/statistiq/privacy-policy"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                        
                        settingsRow(icon: "info.circle", title: "About Us") {
                            if let url = URL(string: "https://simonsalaj.com/statistiq/about"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        if isLoggedIn {
                            Divider()
                            settingsRow(icon: "door.left.hand.open", title: "Log out", isLogOut: true) {
                                try? Auth.auth().signOut()
                                isLoggedIn = false
                                showLogoutMessage = true
                                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showLogoutMessage = false
                                    dismiss()
                                }
                            }
                            
                        }
                        
                        if isLoggedIn {
                            Divider()
                            
                            settingsRow(icon: "trash", title: "Delete Account", isLogOut: true) {
                                showDeleteConfirmation = true
                            }
                        }
                        NavigationLink(
                            destination: EditProfile(
                                initialUsername: "",                 // EditProfile loads the real name onAppear
                                onSaved: { updated in
                                    onUsernameChanged?(updated)      // bubble up to parent if needed
                                }
                            ),
                            isActive: $showEditProfile
                        ) { EmptyView() }.hidden()

                    }
                    .background(colorScheme == .light ? Color.white : Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .overlay(
            Group {
                if showLogoutMessage {
                    VStack {
                        Spacer()
                        Text("You have successfully logged out.")
                            .font(.custom("Jost", size: 16).weight(.medium))
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.45)
                    }
                }
            },
            alignment: .top
        )
        .animation(.easeInOut(duration: 0.3), value: showLogoutMessage)
        
        .onAppear{
            if Auth.auth().currentUser != nil || UserDefaults.standard.bool(forKey: "isLoggedIn"){
                isLoggedIn = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Check out StatistIQ – a smart basketball app!",
                               // URL(string: "https://apps.apple.com/app/idYOUR_APP_ID_HERE")!])
                               URL(string: "https://apple.com")!])
        }
        
        .alert("Are you sure you want to delete your account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    func settingsRow(icon: String, title: String, isLogOut: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(
                            isLogOut
                            ? .red
                            : (colorScheme == .dark ? .white : .black)
                        )
                
                Text(title)
                    .font(.custom("Jost", size: 18).weight(.medium))
//                    .foregroundColor(isLogOut ? .red : .black)
                    .foregroundColor(
                        isLogOut
                        ? .red
                        : (colorScheme == .dark ? .white : .black)
                    )
                
                Spacer()
                if !isLogOut {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Delete Firestore user document first
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("Failed to delete Firestore data: \(error.localizedDescription)")
            }
            
            // Then delete Auth account
            user.delete { error in
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                } else {
                    print("Account deleted successfully")
                    isLoggedIn = false
                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    dismiss()
                }
            }
        }
    }
    
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

#Preview { SettingsView()}
