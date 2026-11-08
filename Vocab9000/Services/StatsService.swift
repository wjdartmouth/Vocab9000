import Foundation
import SwiftData

struct LetterProgress: Identifiable {
    var id: String { letter }
    let letter: String
    let learned: Int
    let total: Int
    var ratio: Double { total == 0 ? 0 : Double(learned) / Double(total) }
}

struct DeckProgress: Identifiable {
    var id: UUID
    let title: String
    let learned: Int
    let total: Int
    let due: Int
    var ratio: Double { total == 0 ? 0 : Double(learned) / Double(total) }
}

struct StudyStatsSnapshot {
    let catalogTotal: Int
    let learnedCount: Int
    let dueToday: Int
    let reviewedToday: Int
    let inProgress: Int
    let lastStudied: Date?
    let streakDays: Int
    let byLetter: [LetterProgress]
    let byDeck: [DeckProgress]
}

enum StatsService {
    @MainActor
    static func snapshot(
        catalog: CatalogStore,
        context: ModelContext
    ) -> StudyStatsSnapshot {
        catalog.loadIfNeeded()
        let progress = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        let cards = (try? context.fetch(FetchDescriptor<FlashCard>())) ?? []
        let decks = (try? context.fetch(FetchDescriptor<Deck>())) ?? []

        let progressByKey = Dictionary(uniqueKeysWithValues: progress.map { ($0.catalogKey, $0) })
        let now = Date()
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)

        let learnedCatalog = progress.filter(\.isLearned).count
        // User-only cards without catalog key that are learned
        let learnedUserOnly = cards.filter { $0.catalogKey == nil && $0.isLearned }.count
        let learnedCount = learnedCatalog + learnedUserOnly

        let dueProgress = progress.filter { row in
            guard let next = row.nextReviewDate else {
                return row.isLearned && row.lastReviewed != nil
            }
            return next <= now
        }.count
        let dueCards = cards.filter { card in
            if let key = card.catalogKey, progressByKey[key] != nil {
                return false // counted via progress
            }
            guard let next = card.nextReviewDate else { return false }
            return next <= now
        }.count
        let dueToday = dueProgress + dueCards

        let reviewedToday = progress.filter { row in
            guard let last = row.lastReviewed else { return false }
            return last >= startOfToday
        }.count + cards.filter { card in
            guard card.catalogKey == nil, let last = card.lastReviewed else { return false }
            return last >= startOfToday
        }.count

        let inProgress = progress.filter { !$0.isNew && !$0.isLearned }.count

        let lastDates: [Date] = progress.compactMap(\.lastReviewed) + cards.compactMap(\.lastReviewed)
        let lastStudied = lastDates.max()

        let streakDays = computeStreak(dates: lastDates, calendar: cal, now: now)

        // Letter progress from catalog
        var letterTotals: [String: Int] = [:]
        var letterLearned: [String: Int] = [:]
        for entry in catalog.entries {
            let L = entry.letter
            letterTotals[L, default: 0] += 1
            if progressByKey[entry.id]?.isLearned == true {
                letterLearned[L, default: 0] += 1
            }
        }
        let byLetter = letterTotals.keys.sorted().map { L in
            LetterProgress(
                letter: L,
                learned: letterLearned[L] ?? 0,
                total: letterTotals[L] ?? 0
            )
        }

        let byDeck: [DeckProgress] = decks.map { deck in
            if deck.isBuiltIn {
                let stats = SeedService.builtInStats(for: deck, catalog: catalog, context: context)
                let due = SeedService.dueCount(for: deck, catalog: catalog, context: context)
                return DeckProgress(
                    id: deck.id,
                    title: deck.title,
                    learned: stats.learned,
                    total: stats.total,
                    due: due
                )
            }
            return DeckProgress(
                id: deck.id,
                title: deck.title,
                learned: deck.learnedCount,
                total: deck.cards.count,
                due: deck.cards.filter(\.isDue).count
            )
        }
        .sorted { $0.ratio > $1.ratio }

        return StudyStatsSnapshot(
            catalogTotal: catalog.entries.count,
            learnedCount: learnedCount,
            dueToday: dueToday,
            reviewedToday: reviewedToday,
            inProgress: inProgress,
            lastStudied: lastStudied,
            streakDays: streakDays,
            byLetter: byLetter,
            byDeck: byDeck
        )
    }

    /// Consecutive calendar days (ending today or yesterday) with ≥1 review.
    static func computeStreak(dates: [Date], calendar: Calendar = .current, now: Date = Date()) -> Int {
        let days = Set(dates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: now)
        // Allow streak to still count if last study was yesterday (not yet studied today)
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
