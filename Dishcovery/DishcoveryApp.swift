//
//  DishcoveryApp.swift
//  Dishcovery
//
//  Created by Selim Hafez on 23/10/2025.
//

import SwiftUI
import FirebaseCore

@main
struct DishcoveryApp: App {
    @StateObject private var session = SessionManager()
    @StateObject private var menuTranslationStore = MenuTranslationStore()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var menuDataManager = MenuDataManager()


    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(menuTranslationStore)
                .environmentObject(favoritesManager)
                .environment(\.locale, Locale(identifier: session.preferredLanguage))
                .environmentObject(menuDataManager)

        }
    }
}
