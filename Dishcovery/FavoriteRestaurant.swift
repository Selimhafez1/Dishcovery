//
//  FavoriteRestaurant.swift
//  Dishcovery
//
//  Created by Selim Hafez on 23/03/2026.
//


import Foundation

struct FavoriteRestaurant: Identifiable, Codable {
    let id: String
    let restaurantName: String
    let rawRestaurantName: String
    let placeID: String
    let createdAt: Date
}
