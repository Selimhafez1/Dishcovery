import SwiftUI

struct RestaurantDetailView: View {
    enum ResultTab: String, CaseIterable {
        case reviews = "Reviews"
        case menu = "Menu"
    }

    let restaurantName: String
    let rawRestaurantName: String
    let placeID: String

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var menuDataManager: MenuDataManager

    @State private var selectedTab: ResultTab = .reviews
    @State private var reviews: [PlaceReview] = []
    @State private var translatedReviews: [Int: String] = [:]
    @State private var isLoadingReviews = false
    @State private var isTranslatingReviews = false
    @StateObject private var reviewManager = ReviewManager()
    @State private var newReviewText = ""
    @State private var isSubmittingReview = false
    @State private var translatedAppReviews: [String: String] = [:]
    @State private var isTranslatingAppReviews = false

    private let translator = TranslationManager.shared

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurantName)
                    .font(.headline)

                if !rawRestaurantName.isEmpty && rawRestaurantName != restaurantName {
                    Text(rawRestaurantName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Picker("Result Tab", selection: $selectedTab) {
                ForEach(ResultTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Group {
                switch selectedTab {
                case .reviews:
                    reviewsTabView
                case .menu:
                    menuTabView
                }
            }

            Spacer()
        }
        .navigationTitle(restaurantName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reviewManager.fetchReviews(for: placeID)
            await loadReviews()
        }
        .task(id: reviewManager.reviews.count) {
            await translateAppReviews(reviewManager.reviews)
        }
    }

    private var reviewsTabView: some View {
        Group {
            if isLoadingReviews {
                ProgressView("Loading reviews...")
                    .padding(.top, 20)

            } else {
                VStack {
                    if isTranslatingReviews {
                        ProgressView("Translating reviews...")
                            .padding(.horizontal)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            // Write a Review
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Write a Review")
                                    .font(.headline)
                                    .padding(.horizontal)

                                TextField("Share your experience...", text: $newReviewText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                                    .padding(.horizontal)

                                Button {
                                    let trimmed = newReviewText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }

                                    isSubmittingReview = true

                                    Task {
                                        isSubmittingReview = true
                                        defer { isSubmittingReview = false }

                                        do {
                                            let predictedRating = try await ReviewPredictionService.shared.predictRating(for: trimmed)

                                            reviewManager.addReview(
                                                restaurantID: placeID,
                                                userName: "\(session.firstName) \(session.lastName)".trimmingCharacters(in: .whitespaces),
                                                text: trimmed,
                                                rating: predictedRating
                                            )

                                            newReviewText = ""
                                        } catch {
                                            print("Rating prediction failed: \(error.localizedDescription)")
                                        }
                                    }

                                    newReviewText = ""
                                    isSubmittingReview = false
                                } label: {
                                    if isSubmittingReview {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Text("Submit Review")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal)
                            }
                            
                            
                            if isTranslatingAppReviews {
                                ProgressView("Translating app reviews...")
                                    .padding(.horizontal)
                            }

                            // App Reviews
                            VStack(alignment: .leading, spacing: 12) {
                                Text("App Reviews")
                                    .font(.headline)
                                    .padding(.horizontal)

                                if reviewManager.reviews.isEmpty {
                                    Text("No app reviews yet.")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                } else {
                                    ForEach(reviewManager.reviews) { review in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(review.userName)
                                                .font(.headline)

                                            Text("⭐️ \(review.rating)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            Text(translatedAppReviews[review.id] ?? review.text)
                                                .font(.body)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.08))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Google Reviews
                            if !reviews.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Google Reviews")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(review.authorName)
                                                .font(.headline)

                                            Text("⭐️ \(review.rating, specifier: "%.1f")")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            Text(translatedReviews[index] ?? review.text)
                                                .font(.body)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.12))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            if reviews.isEmpty && reviewManager.reviews.isEmpty {
                                Text("No reviews available.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private var menuTabView: some View {
        MenuTabView(
            detectedRestaurantName: restaurantName,
            rawDetectedRestaurantName: rawRestaurantName,
            menuDataManager: menuDataManager
        )
    }

    @MainActor
    private func loadReviews() async {
        guard !placeID.isEmpty else { return }

        isLoadingReviews = true
        defer { isLoadingReviews = false }

        do {
            let fetchedReviews = try await fetchReviews(placeID: placeID)
            reviews = fetchedReviews
            await translateReviews(fetchedReviews)
        } catch {
            print("Load reviews error: \(error.localizedDescription)")
            reviews = []
        }
    }

    private func fetchReviews(placeID: String) async throws -> [PlaceReview] {
        let apiKey = "AIzaSyCZK0O8qcnIYKhUv4Ij21BMmQAfGgwz_e4"

        let urlStr = """
        https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeID)&fields=reviews&language=en&key=\(apiKey)
        """

        guard let url = URL(string: urlStr) else {
            return []
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let reviewsArray = result["reviews"] as? [[String: Any]] else {
            return []
        }

        return reviewsArray.map {
            PlaceReview(
                authorName: $0["author_name"] as? String ?? "Anonymous",
                rating: $0["rating"] as? Double ?? 0.0,
                text: $0["text"] as? String ?? ""
            )
        }
    }

    @MainActor
    private func translateReviews(_ reviews: [PlaceReview]) async {
        translatedReviews = [:]
        isTranslatingReviews = true

        defer {
            isTranslatingReviews = false
        }

        guard !reviews.isEmpty else { return }

        if session.preferredLanguage == "en" {
            for (index, review) in reviews.enumerated() {
                translatedReviews[index] = review.text
            }
            return
        }

        let originalTexts = reviews.map {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            let translatedTexts = try await translator.translateTexts(
                originalTexts,
                to: session.preferredLanguage
            )

            for (index, translated) in translatedTexts.enumerated() {
                translatedReviews[index] = translated
            }
        } catch {
            print("Batch review translation error: \(error.localizedDescription)")
            print("Falling back to one-by-one review translation...")

            for (index, review) in reviews.enumerated() {
                let cleanedText = review.text.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !cleanedText.isEmpty else {
                    translatedReviews[index] = review.text
                    continue
                }

                do {
                    let translated = try await translator.translateText(
                        cleanedText,
                        to: session.preferredLanguage
                    )
                    translatedReviews[index] = translated
                } catch {
                    translatedReviews[index] = review.text
                    print("Single review translation error at index \(index): \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    private func translateAppReviews(_ reviews: [AppReview]) async {
        translatedAppReviews = [:]
        isTranslatingAppReviews = true

        defer {
            isTranslatingAppReviews = false
        }

        guard !reviews.isEmpty else { return }

        if session.preferredLanguage == "en" {
            for review in reviews {
                translatedAppReviews[review.id] = review.text
            }
            return
        }

        let originalTexts = reviews.map {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            let translatedTexts = try await translator.translateTexts(
                originalTexts,
                to: session.preferredLanguage
            )

            for (index, translated) in translatedTexts.enumerated() {
                translatedAppReviews[reviews[index].id] = translated
            }
        } catch {
            print("Batch app review translation error: \(error.localizedDescription)")

            for review in reviews {
                let cleanedText = review.text.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !cleanedText.isEmpty else {
                    translatedAppReviews[review.id] = review.text
                    continue
                }

                do {
                    let translated = try await translator.translateText(
                        cleanedText,
                        to: session.preferredLanguage
                    )
                    translatedAppReviews[review.id] = translated
                } catch {
                    translatedAppReviews[review.id] = review.text
                    print("Single app review translation error for review \(review.id): \(error.localizedDescription)")
                }
            }
        }
    }
}
