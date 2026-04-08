import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FavoritesManager: ObservableObject {
    @Published var favorites: [FavoriteRestaurant] = []

    private let db = Firestore.firestore()

    func fetchFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("favorites")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Fetch favorites error: \(error.localizedDescription)")
                    return
                }

                let items: [FavoriteRestaurant] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard let restaurantName = data["restaurantName"] as? String,
                          let rawRestaurantName = data["rawRestaurantName"] as? String,
                          let placeID = data["placeID"] as? String,
                          let timestamp = data["createdAt"] as? Timestamp else {
                        return nil
                    }

                    return FavoriteRestaurant(
                        id: doc.documentID,
                        restaurantName: restaurantName,
                        rawRestaurantName: rawRestaurantName,
                        placeID: placeID,
                        createdAt: timestamp.dateValue()
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.favorites = items
                }
            }
    }

    func addFavorite(
        restaurantName: String,
        rawRestaurantName: String,
        placeID: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion("User not signed in.")
            return
        }

        let alreadyExists = favorites.contains {
            $0.placeID == placeID && !placeID.isEmpty
        }

        if alreadyExists {
            completion(nil)
            return
        }

        let docRef = db.collection("users")
            .document(uid)
            .collection("favorites")
            .document()

        let data: [String: Any] = [
            "restaurantName": restaurantName,
            "rawRestaurantName": rawRestaurantName,
            "placeID": placeID,
            "createdAt": Timestamp(date: Date())
        ]

        docRef.setData(data) { [weak self] error in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                self?.fetchFavorites()
                completion(nil)
            }
        }
    }

    func removeFavorite(id: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("favorites")
            .document(id)
            .delete { [weak self] error in
                if let error = error {
                    print("Remove favorite error: \(error.localizedDescription)")
                } else {
                    self?.fetchFavorites()
                }
            }
    }

    func isFavorite(placeID: String) -> Bool {
        favorites.contains { $0.placeID == placeID && !placeID.isEmpty }
    }
}
