import Foundation

final class MenuDataManager: ObservableObject {
    @Published var allMenuItems: [MenuItem] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        guard let url = Bundle.main.url(forResource: "final_menu_items_cairo", withExtension: "csv") else {
            print("final_menu_items_cairo.csv not found in bundle")
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard !rows.isEmpty else { return }

            let header = rows[0].components(separatedBy: ",")

            guard let restaurantIndex = header.firstIndex(of: "restaurant_name"),
                  let sectionIndex = header.firstIndex(of: "section_name"),
                  let itemIndex = header.firstIndex(of: "item_name"),
                  let descriptionIndex = header.firstIndex(of: "description"),
                  let priceIndex = header.firstIndex(of: "price_text") else {
                print("Required CSV columns not found")
                return
            }

            var loadedItems: [MenuItem] = []

            for row in rows.dropFirst() {
                let columns = Self.parseCSVRow(row)

                if columns.count > max(restaurantIndex, sectionIndex, itemIndex, descriptionIndex, priceIndex) {
                    let restaurantName = columns[restaurantIndex]
                    let sectionName = columns[sectionIndex]
                    let itemName = columns[itemIndex]
                    let description = columns[descriptionIndex].isEmpty ? nil : columns[descriptionIndex]
                    let priceText = columns[priceIndex]

                    let item = MenuItem(
                        restaurantName: restaurantName,
                        sectionName: sectionName,
                        itemName: itemName,
                        description: description,
                        priceText: priceText
                    )

                    loadedItems.append(item)
                }
            }

            self.allMenuItems = loadedItems
            print("Loaded \(loadedItems.count) menu items")

        } catch {
            print("Failed to load CSV: \(error)")
        }
    }

    func menuItems(for possibleNames: [String]) -> [MenuItem] {
        let expandedNames = expandedCandidateNames(from: possibleNames)

        let cleanedInputs = expandedNames
            .map { Self.normalizeName($0) }
            .filter { !$0.isEmpty }

        return allMenuItems.filter { item in
            let normalizedRestaurant = Self.normalizeName(item.restaurantName)

            for input in cleanedInputs {
                if normalizedRestaurant.contains(input) || input.contains(normalizedRestaurant) {
                    return true
                }
            }

            return false
        }
    }

    private func expandedCandidateNames(from possibleNames: [String]) -> [String] {
        var results: [String] = []

        let trimmedNames = possibleNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for name in trimmedNames {
            results.append(name)

            if Self.containsArabic(name) {
                let transliterations = Self.transliterateArabicToLatin(name)
                results.append(contentsOf: transliterations)
            }
        }

        // Combine Latin + Arabic fragments into fuller candidates
        let latinNames = trimmedNames.filter { !Self.containsArabic($0) }
        let arabicNames = trimmedNames.filter { Self.containsArabic($0) }

        for latin in latinNames {
            for arabic in arabicNames {
                let combined = "\(latin) \(arabic)"
                results.append(combined)

                let transliterations = Self.transliterateArabicToLatin(arabic)
                for transliterated in transliterations {
                    results.append("\(latin) \(transliterated)")
                }
            }
        }

        return Array(Set(results))
    }

    static func containsArabic(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x0600 && scalar.value <= 0x06FF {
                return true
            }
        }
        return false
    }

    private static let arabicToLatinMap: [Character: [String]] = [
        "ا": ["a", "e"],
        "أ": ["a", "e"],
        "إ": ["i", "e"],
        "آ": ["a"],
        "ب": ["b"],
        "ت": ["t"],
        "ث": ["th"],
        "ج": ["j"],
        "ح": ["h"],
        "خ": ["kh"],
        "د": ["d"],
        "ذ": ["z"],
        "ر": ["r"],
        "ز": ["z"],
        "س": ["s"],
        "ش": ["sh"],
        "ص": ["s"],
        "ض": ["d"],
        "ط": ["t"],
        "ظ": ["z"],
        "ع": ["a"],
        "غ": ["gh"],
        "ف": ["f"],
        "ق": ["k"],
        "ك": ["k"],
        "ل": ["l"],
        "م": ["m"],
        "ن": ["n"],
        "ه": ["h"],
        "و": ["o"],
        "ي": ["i"],
        "ى": ["a"],
        "ة": ["a"],
        "ؤ": ["o"],
        "ئ": ["i"]
    ]

    static func transliterateArabicToLatin(_ text: String) -> [String] {
        var results: [String] = [""]

        for char in text {
            let options = arabicToLatinMap[char] ?? [String(char)]
            var newResults: [String] = []

            for prefix in results {
                for option in options {
                    newResults.append(prefix + option)
                }
            }

            results = newResults
        }

        return results
    }

    static func normalizeName(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "restaurants", with: "")
            .replacingOccurrences(of: "restaurant", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        result.append(current)
        return result
    }
}
