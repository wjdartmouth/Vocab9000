import Foundation
import SwiftData

enum SeedService {
    private static let seededKey = "vocab9000.seeded.v1"
    private static let srsMigratedKey = "vocab9000.srs.migrated.v1"

    @MainActor
    static func seedIfNeeded(context: ModelContext, catalog: CatalogStore) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else {
            migrateSRSIfNeeded(context: context)
            return
        }
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

        let starter = Deck(title: "__seed.starter50__", languageCode: "en", isBuiltIn: false)
        context.insert(starter)
        for entry in catalog.entries.prefix(50) {
            let card = FlashCard(
                front: entry.word,
                back: entry.primaryBack(locale: .current),
                pos: entry.pos,
                catalogKey: entry.id
            )
            card.deck = starter
            context.insert(card)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
        UserDefaults.standard.set(true, forKey: srsMigratedKey)
    }

    /// One-shot: map legacy isLearned flags into SM-2 fields.
    @MainActor
    static func migrateSRSIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: srsMigratedKey) else { return }

        let progress = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        for row in progress where row.isLearned && row.lastReviewed == nil && row.repetitions == 0 {
            var state = SRSState(
                easeFactor: row.easeFactor == 0 ? 2.5 : row.easeFactor,
                intervalDays: row.intervalDays,
                repetitions: row.repetitions,
                nextReviewDate: row.nextReviewDate,
                lastReviewed: row.lastReviewed,
                isLearned: row.isLearned
            )
            SRSService.migrateIfNeeded(&state, legacyLearned: true)
            apply(state, to: row)
        }

        let cards = (try? context.fetch(FetchDescriptor<FlashCard>())) ?? []
        for card in cards where card.isLearned && card.lastReviewed == nil && card.repetitions == 0 {
            var state = SRSState(
                easeFactor: card.easeFactor == 0 ? 2.5 : card.easeFactor,
                intervalDays: card.intervalDays,
                repetitions: card.repetitions,
                nextReviewDate: card.nextReviewDate,
                lastReviewed: card.lastReviewed,
                isLearned: card.isLearned
            )
            SRSService.migrateIfNeeded(&state, legacyLearned: true)
            apply(state, to: card)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: srsMigratedKey)
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
        let progress = fetchProgressRecords(context: context)
        let learned = entries.reduce(0) { acc, entry in
            acc + ((progress[entry.id]?.isLearned ?? false) ? 1 : 0)
        }
        return (learned, total)
    }

    /// Fast due count — avoids materializing full StudyItem arrays for huge built-in decks.
    @MainActor
    static func dueCount(for deck: Deck, catalog: CatalogStore, context: ModelContext) -> Int {
        let now = Date()
        if deck.isBuiltIn, deck.letterRange != nil {
            let entries = catalogEntries(for: deck, catalog: catalog)
            let progress = fetchProgressRecords(context: context)
            return entries.reduce(0) { acc, entry in
                guard let row = progress[entry.id] else { return acc }
                let isNew = row.lastReviewed == nil && row.repetitions == 0 && row.intervalDays == 0
                if isNew { return acc }
                if let next = row.nextReviewDate {
                    return acc + (next <= now ? 1 : 0)
                }
                return acc + ((row.repetitions > 0 || row.isLearned) ? 1 : 0)
            }
        }
        return deck.cards.reduce(0) { acc, card in
            let isNew = card.isNew
            if isNew { return acc }
            if let next = card.nextReviewDate {
                return acc + (next <= now ? 1 : 0)
            }
            return acc + ((card.repetitions > 0 || card.isLearned) ? 1 : 0)
        }
    }

    @MainActor
    static func nextDueDate(for deck: Deck, catalog: CatalogStore, context: ModelContext) -> Date? {
        let now = Date()
        if deck.isBuiltIn, deck.letterRange != nil {
            let progress = fetchProgressRecords(context: context)
            let keys = Set(catalogEntries(for: deck, catalog: catalog).map(\.id))
            return progress.values
                .filter { keys.contains($0.catalogKey) }
                .compactMap(\.nextReviewDate)
                .filter { $0 > now }
                .min()
        }
        return deck.cards.compactMap(\.nextReviewDate).filter { $0 > now }.min()
    }

    /// Due cards first, then new; optionally cap for a session.
    @MainActor
    static func studyQueue(
        for deck: Deck,
        catalog: CatalogStore,
        context: ModelContext,
        capped: Bool = true
    ) -> [StudyItem] {
        let all = studyItems(for: deck, catalog: catalog, context: context)
        let now = Date()
        let due = all.filter { item in
            if item.isNew { return false }
            if let next = item.nextReviewDate { return next <= now }
            // Seen / migrated without date → treat as due
            return item.repetitions > 0 || item.isLearned
        }.sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }

        let dueIDs = Set(due.map(\.id))
        let news = all.filter { $0.isNew && !dueIDs.contains($0.id) }
        var queue = due + news
        if queue.isEmpty {
            queue = all.filter { !$0.isLearned } + all.filter(\.isLearned)
        }

        guard capped else { return queue }
        var result: [StudyItem] = []
        var newUsed = 0
        for item in queue {
            if item.isNew {
                if newUsed >= SRSService.newCardCap { continue }
                newUsed += 1
            }
            result.append(item)
            if result.count >= SRSService.sessionCap { break }
        }
        return result
    }

    @MainActor
    static func studyItems(for deck: Deck, catalog: CatalogStore, context: ModelContext) -> [StudyItem] {
        if deck.isBuiltIn, deck.letterRange != nil {
            let entries = catalogEntries(for: deck, catalog: catalog)
            let progress = fetchProgressRecords(context: context)
            return entries.map { entry in
                let row = progress[entry.id]
                var state = row.map {
                    SRSState(
                        easeFactor: $0.easeFactor == 0 ? 2.5 : $0.easeFactor,
                        intervalDays: $0.intervalDays,
                        repetitions: $0.repetitions,
                        nextReviewDate: $0.nextReviewDate,
                        lastReviewed: $0.lastReviewed,
                        isLearned: $0.isLearned
                    )
                } ?? .default
                if let row, row.isLearned {
                    SRSService.migrateIfNeeded(&state, legacyLearned: true)
                }
                let isNew = state.lastReviewed == nil && state.repetitions == 0 && state.intervalDays == 0
                let isDue: Bool = {
                    if isNew { return false }
                    guard let next = state.nextReviewDate else { return true }
                    return next <= Date()
                }()
                return StudyItem(
                    id: entry.id,
                    front: entry.word,
                    back: entry.primaryBack(locale: .current),
                    ja: entry.ja,
                    pos: entry.pos,
                    catalogKey: entry.id,
                    isLearned: state.isLearned,
                    isNew: isNew,
                    isDue: isDue || (isNew == false && state.nextReviewDate == nil),
                    nextReviewDate: state.nextReviewDate,
                    intervalDays: state.intervalDays,
                    easeFactor: state.easeFactor,
                    repetitions: state.repetitions,
                    flashCard: nil
                )
            }
        }
        return deck.cards.map { card in
            var state = SRSState(
                easeFactor: card.easeFactor == 0 ? 2.5 : card.easeFactor,
                intervalDays: card.intervalDays,
                repetitions: card.repetitions,
                nextReviewDate: card.nextReviewDate,
                lastReviewed: card.lastReviewed,
                isLearned: card.isLearned
            )
            if card.isLearned {
                SRSService.migrateIfNeeded(&state, legacyLearned: true)
            }
            let isNew = card.isNew
            let isDue = card.isDue || (!isNew && card.nextReviewDate == nil && !card.isLearned)
            return StudyItem(
                id: card.id.uuidString,
                front: card.front,
                back: card.back,
                ja: nil,
                pos: card.pos,
                catalogKey: card.catalogKey,
                isLearned: state.isLearned,
                isNew: isNew,
                isDue: isDue,
                nextReviewDate: state.nextReviewDate,
                intervalDays: state.intervalDays,
                easeFactor: state.easeFactor,
                repetitions: state.repetitions,
                flashCard: card
            )
        }
    }

    @MainActor
    private static func fetchProgressRecords(context: ModelContext) -> [String: ProgressRecord] {
        let all = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        return Dictionary(uniqueKeysWithValues: all.map { ($0.catalogKey, $0) })
    }

    @MainActor
    static func setLearned(catalogKey: String, word: String, learned: Bool, context: ModelContext) {
        applyGrade(
            catalogKey: catalogKey,
            word: word,
            grade: learned ? .good : .again,
            flashCard: nil,
            context: context
        )
    }

    @MainActor
    static func applyGrade(
        catalogKey: String?,
        word: String,
        grade: SRSGrade,
        flashCard: FlashCard?,
        context: ModelContext
    ) {
        if let flashCard {
            var state = SRSState(
                easeFactor: flashCard.easeFactor == 0 ? 2.5 : flashCard.easeFactor,
                intervalDays: flashCard.intervalDays,
                repetitions: flashCard.repetitions,
                nextReviewDate: flashCard.nextReviewDate,
                lastReviewed: flashCard.lastReviewed,
                isLearned: flashCard.isLearned
            )
            state = SRSService.schedule(state: state, grade: grade)
            apply(state, to: flashCard)
        }

        if let catalogKey {
            var descriptor = FetchDescriptor<ProgressRecord>(
                predicate: #Predicate { $0.catalogKey == catalogKey }
            )
            descriptor.fetchLimit = 1
            let row: ProgressRecord
            if let existing = try? context.fetch(descriptor).first {
                row = existing
            } else {
                let created = ProgressRecord(catalogKey: catalogKey, word: word)
                context.insert(created)
                row = created
            }
            var state = SRSState(
                easeFactor: row.easeFactor == 0 ? 2.5 : row.easeFactor,
                intervalDays: row.intervalDays,
                repetitions: row.repetitions,
                nextReviewDate: row.nextReviewDate,
                lastReviewed: row.lastReviewed,
                isLearned: row.isLearned
            )
            state = SRSService.schedule(state: state, grade: grade)
            apply(state, to: row)
        }
        try? context.save()
    }

    private static func apply(_ state: SRSState, to row: ProgressRecord) {
        row.easeFactor = state.easeFactor
        row.intervalDays = state.intervalDays
        row.repetitions = state.repetitions
        row.nextReviewDate = state.nextReviewDate
        row.lastReviewed = state.lastReviewed
        row.isLearned = state.isLearned
        row.updatedAt = Date()
    }

    private static func apply(_ state: SRSState, to card: FlashCard) {
        card.easeFactor = state.easeFactor
        card.intervalDays = state.intervalDays
        card.repetitions = state.repetitions
        card.nextReviewDate = state.nextReviewDate
        card.lastReviewed = state.lastReviewed
        card.isLearned = state.isLearned
        card.updatedAt = Date()
    }
}

struct StudyItem: Identifiable {
    let id: String
    let front: String
    let back: String
    let ja: String?
    let pos: String?
    let catalogKey: String?
    var isLearned: Bool
    var isNew: Bool
    var isDue: Bool
    var nextReviewDate: Date?
    var intervalDays: Double
    var easeFactor: Double
    var repetitions: Int
    var flashCard: FlashCard?
}
