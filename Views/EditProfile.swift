import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfile: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var username: String = ""
    @State private var original: String = ""
    @State private var isSaving = false
    
    init(initialUsername: String, onSaved: @escaping (String) -> Void = { _ in }) {
        _username = State(initialValue: initialUsername)
        _original = State(initialValue: initialUsername)
        self.onSaved = onSaved
    }

    var onSaved: (String) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar (same style as Settings)
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea(edges: .top)
                .frame(height: 60)
                .overlay(
                    HStack(spacing: 20) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .medium))
                        }
                        .padding(.leading, 16)

                        Text("Edit Profile")
                            .font(.custom("Jost-SemiBold", size: 22))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 15),
                    alignment: .topLeading
                )

            // Body
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Username")
                            .font(.custom("Jost", size: 14).weight(.semibold))
                            .foregroundColor(.secondary)

                        TextField("Enter new username", text: $username)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Button(action: save) {
                            HStack {
                                Spacer()
                                Text(isSaving ? "Saving…" : "Save")
                                    .font(.custom("Jost", size: 16).weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(
                                (canSave ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!canSave)
                    }
                    .padding(16)
                }
                .background(colorScheme == .light ? Color.white : Color.black)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if original.isEmpty { loadUsername() }
        }
        .enableSwipeBack()
    }

    private var canSave: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && username != original && !isSaving
    }

    private func loadUsername() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snap, _ in
            let current = (snap?.data()?["username"] as? String) ?? Auth.auth().currentUser?.displayName ?? ""
            self.username = current
            self.original = current
        }
    }

    private func save() {
        guard let uid = Auth.auth().currentUser?.uid, canSave else { return }
        isSaving = true
        Firestore.firestore().collection("users").document(uid)
            .updateData(["username": username]) { error in
                isSaving = false
                if error == nil {
                    onSaved(username)
                    dismiss()
                }
            }
    }
}

#Preview {
    NavigationStack {
        EditProfile(initialUsername: "simonator420") { updated in
            print("Saved username:", updated)
        }
    }
}
