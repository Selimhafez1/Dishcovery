//
//  ReviewPredictionResponse.swift
//  Dishcovery
//
//  Created by Selim Hafez on 25/03/2026.
//


import Foundation

struct ReviewPredictionResponse: Decodable {
    let rating: Int
    let probabilities: [Double]
}

final class ReviewPredictionService {
    static let shared = ReviewPredictionService()

    private init() {}

    func predictRating(for text: String) async throws -> Int {
        guard let url = URL(string: "https://ratingapi-o5s4.onrender.com/predict") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(ReviewPredictionResponse.self, from: data)
        return decoded.rating
    }
}
