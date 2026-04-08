import SwiftUI

struct LogoScanView: View {
    enum ResultTab: String, CaseIterable {
        case photo = "Photo"
        case reviews = "Reviews"
        case menu = "Menu"
    }

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var favoritesManager: FavoritesManager

    @State private var translatedReviews: [Int: String] = [:]
    private let translator = TranslationManager.shared
    @State private var isTranslatingReviews = false
    @State private var translatedDetectedText: String = ""
    @State private var isTranslatingDetectedText = false
    @State private var favoriteMessage: String = ""

    @State private var newReviewText = ""
    @State private var isSubmittingReview = false
    @StateObject private var reviewManager = ReviewManager()

    @State private var showCamera: Bool = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedTab: ResultTab = .photo
    @StateObject private var cameraModel = CameraViewModel()
    @StateObject private var menuDataManager = MenuDataManager()
    @State private var translatedAppReviews: [String: String] = [:]
    @State private var isTranslatingAppReviews = false

    private let autoStartCamera: Bool

    init(autoStartCamera: Bool = false) {
        self.autoStartCamera = autoStartCamera
    }

    var body: some View {
        VStack(spacing: 20) {

            if !showCamera {
                Button("Scan Logo with Camera") {
                    showCamera = true
                }
                .padding()
                .background(Color.orange)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            if !cameraModel.detectedText.isEmpty {
                VStack(spacing: 8) {
                    if isTranslatingDetectedText {
                        ProgressView("Translating detected text...")
                    }

                    Text(translatedDetectedText.isEmpty ? cameraModel.detectedText : translatedDetectedText)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            if !cameraModel.detectedRestaurantName.isEmpty && !cameraModel.placeID.isEmpty {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cameraModel.detectedRestaurantName)
                            .font(.headline)

                        if !cameraModel.rawDetectedRestaurantName.isEmpty &&
                            cameraModel.rawDetectedRestaurantName != cameraModel.detectedRestaurantName {
                            Text(cameraModel.rawDetectedRestaurantName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        if favoritesManager.isFavorite(placeID: cameraModel.placeID) {
                            if let existing = favoritesManager.favorites.first(where: { $0.placeID == cameraModel.placeID }) {
                                favoritesManager.removeFavorite(id: existing.id)
                                favoriteMessage = "Removed from Favorites"
                            }
                        } else {
                            favoritesManager.addFavorite(
                                restaurantName: cameraModel.detectedRestaurantName,
                                rawRestaurantName: cameraModel.rawDetectedRestaurantName,
                                placeID: cameraModel.placeID
                            ) { error in
                                if let error = error {
                                    favoriteMessage = error
                                } else {
                                    favoriteMessage = "Added to Favorites"
                                }
                            }
                        }
                    } label: {
                        Image(systemName: favoritesManager.isFavorite(placeID: cameraModel.placeID) ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal)

                if !favoriteMessage.isEmpty {
                    Text(favoriteMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
            }

            if capturedImage != nil || !cameraModel.reviews.isEmpty || !cameraModel.placeID.isEmpty {
                Picker("Result Tab", selection: $selectedTab) {
                    ForEach(ResultTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch selectedTab {
                    case .photo:
                        photoTabView
                    case .reviews:
                        reviewsTabView
                    case .menu:
                        menuTabView
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            favoritesManager.fetchFavorites()

            if autoStartCamera && !showCamera {
                DispatchQueue.main.async {
                    showCamera = true
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(selectedImage: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newImage in
            if let img = newImage {
                cameraModel.reviews = []
                cameraModel.detectedRestaurantName = ""
                cameraModel.rawDetectedRestaurantName = ""
                cameraModel.placeID = ""
                translatedReviews = [:]
                translatedDetectedText = ""
                favoriteMessage = ""
                newReviewText = ""
                selectedTab = .photo
                cameraModel.sendImageToVisionAPI(img)
            }
        }
        .task(id: cameraModel.reviews.count) {
            await translateReviews(cameraModel.reviews)
        }
        .task(id: cameraModel.detectedText) {
            await translateDetectedText(cameraModel.detectedText)
        }
        .task(id: cameraModel.placeID) {
            if !cameraModel.placeID.isEmpty {
                reviewManager.fetchReviews(for: cameraModel.placeID)
            }
        }
        .task(id: reviewManager.reviews.count) {
            await translateAppReviews(reviewManager.reviews)
        }
    }

    private var photoTabView: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                Text("No photo available.")
                    .foregroundColor(.gray)
            }
        }
    }

    private var reviewsTabView: some View {
        Group {
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
                            guard !trimmed.isEmpty, !cameraModel.placeID.isEmpty else { return }

                            Task {
                                isSubmittingReview = true
                                defer { isSubmittingReview = false }

                                do {
                                    let predictedRating = try await ReviewPredictionService.shared.predictRating(for: trimmed)

                                    reviewManager.addReview(
                                        restaurantID: cameraModel.placeID,
                                        userName: "\(session.firstName) \(session.lastName)".trimmingCharacters(in: .whitespaces),
                                        text: trimmed,
                                        rating: predictedRating
                                    )

                                    newReviewText = ""
                                } catch {
                                    print("Rating prediction failed: \(error.localizedDescription)")
                                }
                            }
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
                    if !cameraModel.reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Google Reviews")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(Array(cameraModel.reviews.enumerated()), id: \.offset) { index, review in
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

                    if cameraModel.reviews.isEmpty && reviewManager.reviews.isEmpty {
                        Text("No reviews available.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var menuTabView: some View {
        MenuTabView(
            detectedRestaurantName: cameraModel.detectedRestaurantName,
            rawDetectedRestaurantName: cameraModel.rawDetectedRestaurantName,
            menuDataManager: menuDataManager
        )
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
    private func translateDetectedText(_ text: String) async {
        guard !text.isEmpty else {
            translatedDetectedText = ""
            return
        }

        isTranslatingDetectedText = true
        defer {
            isTranslatingDetectedText = false
        }

        if session.preferredLanguage == "en" {
            translatedDetectedText = text
            return
        }

        do {
            translatedDetectedText = try await translator.translateText(
                text,
                to: session.preferredLanguage
            )
        } catch {
            translatedDetectedText = text
            print("Detected text translation error: \(error.localizedDescription)")
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
