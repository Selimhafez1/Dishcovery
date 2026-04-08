//
//  AppReview.swift
//  Dishcovery
//
//  Created by Selim Hafez on 24/03/2026.
//


import Foundation

struct AppReview: Identifiable, Codable {
    let id: String
    let restaurantID: String
    let userName: String
    let text: String
    let rating: Int
    let createdAt: Date
}
