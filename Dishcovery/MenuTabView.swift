import SwiftUI

struct MenuSectionGroup: Identifiable {
    let id = UUID()
    let sectionName: String
    let items: [MenuItem]
}

struct MenuTabView: View {
    let detectedRestaurantName: String
    let rawDetectedRestaurantName: String
    @ObservedObject var menuDataManager: MenuDataManager

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var menuTranslationStore: MenuTranslationStore

    private let translator = TranslationManager.shared

    @State private var isTranslatingMenu = false
    @State private var matchedItemsState: [MenuItem] = []
    @State private var groupedMenuState: [MenuSectionGroup] = []
    @State private var isLoadingMenu = true

    var body: some View {
        NavigationView {
            List {
                if detectedRestaurantName.isEmpty {
                    Text("No restaurant detected yet.")
                        .foregroundColor(.gray)

                } else if isLoadingMenu {
                    ProgressView("Loading menu...")

                } else if matchedItemsState.isEmpty {
                    Text("No menu found for \(detectedRestaurantName)")
                        .foregroundColor(.gray)

                } else {
                    if isTranslatingMenu {
                        ProgressView("Translating menu...")
                    }

                    ForEach(groupedMenuState) { section in
                        Section(
                            header: Text(
                                menuTranslationStore.translatedSections[section.sectionName]
                                ?? section.sectionName
                            )
                        ) {
                            ForEach(section.items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(
                                            menuTranslationStore.translatedItemNames[item.id]
                                            ?? item.itemName
                                        )
                                        .font(.headline)

                                        Spacer()

                                        Text(item.priceText)
                                            .foregroundColor(.secondary)
                                    }

                                    if let description = item.description,
                                       !description.isEmpty {
                                        Text(
                                            menuTranslationStore.translatedDescriptions[item.id]
                                            ?? description
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Menu")
        }
        .task(id: restaurantKey) {
            loadMenuData()
        }
        .task(id: menuTranslationKey) {
            await translateMenu()
        }
    }

    private var restaurantKey: String {
        "\(detectedRestaurantName)|\(rawDetectedRestaurantName)"
    }

    private var menuTranslationKey: String {
        "\(session.preferredLanguage)|\(detectedRestaurantName)|\(rawDetectedRestaurantName)|\(matchedItemsState.count)"
    }

    @MainActor
    private func loadMenuData() {
        isLoadingMenu = true

        let rawItems = menuDataManager.menuItems(for: [
            detectedRestaurantName,
            rawDetectedRestaurantName
        ])
        .filter { !$0.sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let items = filterPreferredLanguageMenuItems(from: rawItems)

        matchedItemsState = items

        let grouped = Dictionary(grouping: items) { $0.sectionName }

        groupedMenuState = grouped
            .map { MenuSectionGroup(sectionName: $0.key, items: $0.value) }
            .sorted { $0.sectionName < $1.sectionName }

        isLoadingMenu = false
    }

    private func filterPreferredLanguageMenuItems(from items: [MenuItem]) -> [MenuItem] {
        guard !items.isEmpty else { return [] }

        let arabicItems = items.filter { isArabicMenuItem($0) }
        let nonArabicItems = items.filter { !isArabicMenuItem($0) }

        let preferredItems: [MenuItem]

        if session.preferredLanguage == "ar" {
            preferredItems = !arabicItems.isEmpty ? arabicItems : items
        } else {
            preferredItems = !nonArabicItems.isEmpty ? nonArabicItems : items
        }

        return deduplicateMenuItems(preferredItems)
    }

    private func isArabicMenuItem(_ item: MenuItem) -> Bool {
        let combinedText =
            item.restaurantName + " " +
            item.sectionName + " " +
            item.itemName + " " +
            (item.description ?? "")

        return containsArabic(combinedText)
    }

    private func containsArabic(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x0600 && scalar.value <= 0x06FF {
                return true
            }
        }
        return false
    }

    private func deduplicateMenuItems(_ items: [MenuItem]) -> [MenuItem] {
        var seen = Set<String>()
        var result: [MenuItem] = []

        for item in items {
            let key = [
                normalizeMenuText(item.sectionName),
                normalizeMenuText(item.itemName),
                normalizeMenuText(item.description ?? ""),
                normalizeMenuText(item.priceText)
            ].joined(separator: "|")

            if !seen.contains(key) {
                seen.insert(key)
                result.append(item)
            }
        }

        return result
    }

    private func normalizeMenuText(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func translateMenu() async {
        guard !matchedItemsState.isEmpty else { return }

        menuTranslationStore.ensureContext(menuTranslationKey)

        isTranslatingMenu = true
        defer { isTranslatingMenu = false }

        let uniqueSectionNames = Array(Set(groupedMenuState.map { $0.sectionName })).sorted()

        let missingSectionNames = uniqueSectionNames.filter {
            menuTranslationStore.translatedSections[$0] == nil
        }

        if !missingSectionNames.isEmpty {
            do {
                let translatedSectionResults = try await translator.translateTexts(
                    missingSectionNames,
                    to: session.preferredLanguage
                )

                for (original, translated) in zip(missingSectionNames, translatedSectionResults) {
                    menuTranslationStore.translatedSections[original] = translated
                }
            } catch {
                for sectionName in missingSectionNames {
                    menuTranslationStore.translatedSections[sectionName] = sectionName
                }
                print("Batch section translation error: \(error.localizedDescription)")
            }
        }

        let itemsMissingNames = matchedItemsState.filter {
            menuTranslationStore.translatedItemNames[$0.id] == nil
        }

        if !itemsMissingNames.isEmpty {
            let itemNames = itemsMissingNames.map { $0.itemName }

            do {
                let translatedNameResults = try await translator.translateTexts(
                    itemNames,
                    to: session.preferredLanguage
                )

                for (item, translated) in zip(itemsMissingNames, translatedNameResults) {
                    menuTranslationStore.translatedItemNames[item.id] = translated
                }
            } catch {
                for item in itemsMissingNames {
                    menuTranslationStore.translatedItemNames[item.id] = item.itemName
                }
                print("Batch item name translation error: \(error.localizedDescription)")
            }
        }

        let itemsWithDescriptionsMissingTranslation = matchedItemsState.filter {
            guard let description = $0.description else { return false }
            return !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   menuTranslationStore.translatedDescriptions[$0.id] == nil
        }

        if !itemsWithDescriptionsMissingTranslation.isEmpty {
            let descriptions = itemsWithDescriptionsMissingTranslation.compactMap { $0.description }

            do {
                let translatedDescriptionResults = try await translator.translateTexts(
                    descriptions,
                    to: session.preferredLanguage
                )

                for (item, translated) in zip(itemsWithDescriptionsMissingTranslation, translatedDescriptionResults) {
                    menuTranslationStore.translatedDescriptions[item.id] = translated
                }
            } catch {
                for item in itemsWithDescriptionsMissingTranslation {
                    menuTranslationStore.translatedDescriptions[item.id] = item.description ?? ""
                }
                print("Batch description translation error: \(error.localizedDescription)")
            }
        }
    }
}
