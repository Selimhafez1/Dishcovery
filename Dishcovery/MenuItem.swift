//
//  MenuItem.swift
//  Dishcovery
//
//  Created by Selim Hafez on 22/03/2026.
//


import Foundation

struct MenuItem: Identifiable {
    let id = UUID()
    let restaurantName: String
    let sectionName: String
    let itemName: String
    let description: String?
    let priceText: String
}