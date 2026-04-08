import Foundation
import FirebaseFunctions
import FirebaseAuth

@MainActor
final class TranslationManager: ObservableObject {
    static let shared = TranslationManager()

    private let functions = Functions.functions(region: "us-central1")
    private var memoryCache: [String: String] = [:]
    private let cachePrefix = "translation_cache_v2_"

    private init() {}

    private func cacheKey(for text: String, language: String) -> String {
        "\(language)|\(text)"
    }

    private func cachedTranslation(for text: String, language: String) -> String? {
        let key = cacheKey(for: text, language: language)

        if let memoryValue = memoryCache[key] {
            return memoryValue
        }

        if let savedValue = UserDefaults.standard.string(forKey: cachePrefix + key) {
            memoryCache[key] = savedValue
            return savedValue
        }

        return nil
    }

    private func saveTranslation(_ translated: String, for text: String, language: String) {
        let key = cacheKey(for: text, language: language)
        memoryCache[key] = translated
        UserDefaults.standard.set(translated, forKey: cachePrefix + key)
    }

    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedText.isEmpty {
            return text
        }

        if let cached = cachedTranslation(for: cleanedText, language: targetLanguage) {
            return cached
        }

        let results = try await translateTexts([cleanedText], to: targetLanguage)
        let translated = results.first ?? text

        saveTranslation(translated, for: cleanedText, language: targetLanguage)
        return translated
    }

    func translateTexts(_ texts: [String], to targetLanguage: String) async throws -> [String] {
        let cleanedTexts = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var results = Array(repeating: "", count: cleanedTexts.count)

        var uncachedTexts: [String] = []
        var uncachedIndexes: [Int] = []

        for (index, text) in cleanedTexts.enumerated() {
            if text.isEmpty {
                results[index] = texts[index]
            } else if let cached = cachedTranslation(for: text, language: targetLanguage) {
                results[index] = cached
            } else {
                uncachedTexts.append(text)
                uncachedIndexes.append(index)
            }
        }

        if uncachedTexts.isEmpty {
            return results
        }

        let data: [String: Any] = [
            "texts": uncachedTexts,
            "targetLanguage": targetLanguage
        ]

        let result = try await functions
            .httpsCallable("translateText")
            .call(data)

        if let dict = result.data as? [String: Any],
           let translatedTexts = dict["translatedTexts"] as? [String] {
            for (offset, translated) in translatedTexts.enumerated() {
                let originalIndex = uncachedIndexes[offset]
                let originalText = cleanedTexts[originalIndex]

                results[originalIndex] = translated
                saveTranslation(translated, for: originalText, language: targetLanguage)
            }

            return results
        }

        return texts
    }
}
