import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: Set<Int> = []
    private var listener: ListenerRegistration?
    
    func start() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        stop()
        listener = Firestore.firestore()
            .collection("users").document(uid)
            .addSnapshotListener { [weak self] doc, _ in
                guard let self = self, let data = doc?.data() else { return }
                let arr = (data["favoriteTeams"] as? [Any]) ?? []
                let set = Set(arr.compactMap { ($0 as? NSNumber)?.intValue ?? ($0 as? Int) })
                DispatchQueue.main.async {
                    self.favorites = set
                }
            }
    }
    
    func stop() {
        listener?.remove(); listener = nil
    }
    
    func contains(_ id: Int?) -> Bool {
        guard let id = id else { return false }
        return favorites.contains(id)
    }
    
    func toggle(teamId: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .setData(["favoriteTeams": favorites.contains(teamId)
                      ? FieldValue.arrayRemove([teamId])
                      : FieldValue.arrayUnion([teamId])],
                     merge: true)
    }
}
