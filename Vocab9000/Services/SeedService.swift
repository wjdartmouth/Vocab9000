import Foundation
import SwiftData

enum SeedService {
    private static let seededKey = "vocab9000.seeded.v1"

    @MainActor
    static func seedIfNeeded(context: ModelContext, catalog: CatalogStore) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        catalog.loadIfNeeded()

        let ranges: [(String, Character, Character)] = [
            ("Longman 9000 — A–C", "A", "C"),
            ("Longman 9000 — D–F", "D", "F"),
            ("Longman 9000 — G–I", "G", "I"),
            ("Longman 9000 — J–L", "J", "L"),
            ("Longman 9000 — M–O", "M", "O"),
            ("Longman 9000 — P–R", "P", "R"),
            ("Longman 9000 — S–U", "S", "U"),
            ("Longman 9000 — V–Z", "V", "Z")
        ]

        // Full catalog as lightweight built-in deck metadata (cards filled lazily / virtually)
        let allDeck = Deck(
            title: "Longman 9000 — All",
            languageCode: "en",
            isBuiltIn: true,
            letterRange: "A-Z"
        )
        context.insert(allDeck)

        for (title, start, end) in ranges {
            let deck = Deck(
                title: title,
                languageCode: "en",
                isBuiltIn: true,
                letterRange: "\(start)-\(end)"
            )
            context.insert(deck)
        }

        // Sample user-friendly starter: first 50 words as a concrete card deck
        let starter = Deck(title: "はじめての50語", languageCode: "en", isBuiltIn: false)
        context.insert(starter)
        for entry in catalog.entries.prefix(50) {
            let card = FlashCard(
                front: entry.word,
                back: entry.fallbackBack,
                pos: entry.pos,
                catalogKey: entry.id
            )
            card.deck = starter
            context.insert(card)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }


    @MainActor
    static func catalogEntries(for deck: Deck, catalog: CatalogStore) -> [CatalogEntry] {
        guard deck.isBuiltIn, let range = deck.letterRange else { return [] }
        if range == "A-Z" { return catalog.entries }
        let parts = range.split(separator: "-")
        guard parts.count == 2, let s = parts[0].first, let e = parts[1].first else { return [] }
        return catalog.entries(letterRange: s, end: e)
    }

    @MainActor
    static func builtInStats(for deck: Deck, catalog: CatalogStore, context: ModelContext) -> (learned: Int, total: Int) {
        let entries = catalogEntries(for: deck, catalog: catalog)
        let total = entries.count
        guard total > 0 else { return (0, 0) }
        let progress = fetchProgressMap(context: context)
        let learned = entries.reduce(0) { $0 + ((progress[$1.id] ?? false) ? 1 : 0) }
        return (learned, total)
    }

    /// Resolve study cards for a deck — built-in letter ranges pull from catalog
    @MainActor
    static func studyItems(for deck: Deck, catalog: CatalogStore, context: ModelContext) -> [StudyItem] {
        if deck.isBuiltIn, deck.letterRange != nil {
            let entries = catalogEntries(for: deck, catalog: catalog)
            let progress = fetchProgressMap(context: context)
            return entries.map { entry in
                StudyItem(
                    id: entry.id,
                    front: entry.word,
                    back: entry.fallbackBack,
                    pos: entry.pos,
                    catalogKey: entry.id,
                    isLearned: progress[entry.id] ?? false,
                    flashCard: nil
                )
            }
        }
        return deck.cards.map { card in
            StudyItem(
                id: card.id.uuidString,
                front: card.front,
                back: card.back,
                pos: card.pos,
                catalogKey: card.catalogKey,
                isLearned: card.isLearned,
                flashCard: card
            )
        }
    }

    @MainActor
    private static func fetchProgressMap(context: ModelContext) -> [String: Bool] {
        let all = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        return Dictionary(uniqueKeysWithValues: all.map { ($0.catalogKey, $0.isLearned) })
    }

    @MainActor
    static func setLearned(catalogKey: String, word: String, learned: Bool, context: ModelContext) {
        var descriptor = FetchDescriptor<ProgressRecord>(
            predicate: #Predicate { $0.catalogKey == catalogKey }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.isLearned = learned
            existing.updatedAt = Date()
        } else {
            context.insert(ProgressRecord(catalogKey: catalogKey, word: word, isLearned: learned))
        }
        try? context.save()
    }
}

struct StudyItem: Identifiable {
    let id: String
    let front: String
    let back: String
    let pos: String?
    let catalogKey: String?
    var isLearned: Bool
    /// Present when backed by a real FlashCard row
    var flashCard: FlashCard?

}
