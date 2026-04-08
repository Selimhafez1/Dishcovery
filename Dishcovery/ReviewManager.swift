import Foundation
import FirebaseFirestore

class ReviewManager: ObservableObject {
    @Published var reviews: [AppReview] = []

    private let db = Firestore.firestore()

    func fetchReviews(for restaurantID: String) {
        db.collection("reviews")
            .whereField("restaurantID", isEqualTo: restaurantID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Fetch reviews error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No review documents found")
                    self.reviews = []
                    return
                }

                print("Fetched \(documents.count) app reviews for restaurantID: \(restaurantID)")

                self.reviews = documents.compactMap { doc in
                    let data = doc.data()

                    guard let restaurantID = data["restaurantID"] as? String,
                          let userName = data["userName"] as? String,
                          let text = data["text"] as? String,
                          let createdAt = data["createdAt"] as? Timestamp else {
                        print("⚠️ Failed to parse review doc: \(doc.documentID)")
                        return nil
                    }

                    let rating = data["rating"] as? Int ?? 3

                    return AppReview(
                        id: doc.documentID,
                        restaurantID: restaurantID,
                        userName: userName,
                        text: text,
                        rating: rating,
                        createdAt: createdAt.dateValue()
                    )
                }
            }
    }

    func addReview(
        restaurantID: String,
        userName: String,
        text: String,
        rating: Int
    ) {
        let reviewID = UUID().uuidString

        let data: [String: Any] = [
            "restaurantID": restaurantID,
            "userName": userName,
            "text": text,
            "rating": rating,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("reviews")
            .document(reviewID)
            .setData(data) { error in
                if let error = error {
                    print("Error adding review: \(error.localizedDescription)")
                } else {
                    print("Review added successfully with id: \(reviewID)")
                }
            }
    }
}
