//
//  MenuTranslationStore.swift
//  Dishcovery
//
//  Created by Selim Hafez on 23/03/2026.
//


import Foundation

final class MenuTranslationStore: ObservableObject {
    @Published var currentKey: String = ""
    @Published var translatedSections: [String: String] = [:]
    @Published var translatedItemNames: [UUID: String] = [:]
    @Published var translatedDescriptions: [UUID: String] = [:]

    func reset(for key: String) {
        currentKey = key
        translatedSections = [:]
        translatedItemNames = [:]
        translatedDescriptions = [:]
    }

    func ensureContext(_ key: String) {
        if currentKey != key {
            reset(for: key)
        }
    }
}