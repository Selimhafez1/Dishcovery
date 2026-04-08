import Foundation
import FirebaseAuth
import FirebaseFirestore

final class SessionManager: ObservableObject {
    @Published var user: User?
    @Published var preferredLanguage: String = "en"
    @Published var firstName: String = ""
    @Published var lastName: String = ""

    private let db = Firestore.firestore()

    init() {
        self.user = Auth.auth().currentUser

        if let uid = user?.uid {
            fetchUserProfile(uid: uid)
        }
    }

    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        preferredLanguage: String,
        completion: @escaping (String?) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                completion(error.localizedDescription)
                return
            }

            guard let firebaseUser = result?.user else {
                completion("Failed to create user.")
                return
            }

            self.user = firebaseUser

            let data: [String: Any] = [
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "preferredLanguage": preferredLanguage
            ]

            self.db.collection("users").document(firebaseUser.uid).setData(data) { error in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.firstName = firstName
                        self.lastName = lastName
                        self.preferredLanguage = preferredLanguage
                    }
                    completion(nil)
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                completion(error.localizedDescription)
                return
            }

            guard let firebaseUser = result?.user else {
                completion("Failed to sign in.")
                return
            }

            self.user = firebaseUser
            self.fetchUserProfile(uid: firebaseUser.uid)
            completion(nil)
        }
    }

    func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.firstName = data["firstName"] as? String ?? ""
                    self.lastName = data["lastName"] as? String ?? ""
                    self.preferredLanguage = data["preferredLanguage"] as? String ?? "en"
                }
            }
        }
    }

    func updatePreferredLanguage(_ language: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).updateData([
            "preferredLanguage": language
        ]) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.preferredLanguage = language
                }
            }
        }
    }

    func deleteAccount(completion: @escaping (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion("No signed-in user found.")
            return
        }

        let uid = user.uid
        let userDocRef = db.collection("users").document(uid)
        let favoritesRef = userDocRef.collection("favorites")

        favoritesRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion("Failed to load favorites: \(error.localizedDescription)")
                return
            }

            let batch = self?.db.batch()

            snapshot?.documents.forEach { doc in
                batch?.deleteDocument(doc.reference)
            }

            batch?.deleteDocument(userDocRef)

            batch?.commit { error in
                if let error = error {
                    completion("Failed to delete user data: \(error.localizedDescription)")
                    return
                }

                user.delete { error in
                    if let error = error {
                        completion(error.localizedDescription)
                    } else {
                        DispatchQueue.main.async {
                            self?.user = nil
                            self?.firstName = ""
                            self?.lastName = ""
                            self?.preferredLanguage = "en"
                        }
                        completion(nil)
                    }
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.firstName = ""
            self.lastName = ""
            self.preferredLanguage = "en"
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
