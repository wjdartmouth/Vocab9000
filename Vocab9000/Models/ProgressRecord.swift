import Foundation
import SwiftData

/// Per-catalog-word learning + SM-2 spaced repetition state
@Model
final class ProgressRecord {
    @Attribute(.unique) var catalogKey: String
    var word: String
    var isLearned: Bool
    var updatedAt: Date

    /// SM-2 ease factor (min 1.3); default 2.5
    var easeFactor: Double
    /// Current interval in days
    var intervalDays: Double
    /// Successful repetitions in a row
    var repetitions: Int
    /// When the card becomes due again
    var nextReviewDate: Date?
    var lastReviewed: Date?

    init(catalogKey: String, word: String, isLearned: Bool = false) {
        self.catalogKey = catalogKey
        self.word = word
        self.isLearned = isLearned
        self.updatedAt = Date()
        self.easeFactor = 2.5
        self.intervalDays = 0
        self.repetitions = 0
        self.nextReviewDate = isLearned ? Date() : nil
        self.lastReviewed = nil
    }

    var isDue: Bool {
        guard let next = nextReviewDate else { return false } // nil = never started / new handled separately
        return next <= Date()
    }

    var isNew: Bool { lastReviewed == nil && repetitions == 0 && intervalDays == 0 }
}
