import SwiftUI

struct DataUploader: View {
    private let apiService = APIService()
    private let firestoreService = FirestoreService()
    
    @State private var uploadDone = false
    
    var body: some View {
        VStack {
            if uploadDone {
                Text("✅ Operation was completed.")
            } else {
                Text("⏳ Loading...")
                    .onAppear {
                        uploadTeamsOnce()
                    }
            }
        }
    }
    
    private func uploadTeamsOnce() {
        apiService.fetchTeams { teams in
            firestoreService.saveTeams(teams)
            DispatchQueue.main.async {
                uploadDone = true
            }
        }
    }
}
