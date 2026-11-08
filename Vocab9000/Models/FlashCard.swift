import Foundation
import SwiftData

@Model
final class FlashCard {
    var id: UUID
    var front: String
    var back: String
    var example: String?
    var pos: String?
    var catalogKey: String?
    var isLearned: Bool
    var updatedAt: Date
    var deck: Deck?

    // SM-2
    var easeFactor: Double
    var intervalDays: Double
    var repetitions: Int
    var nextReviewDate: Date?
    var lastReviewed: Date?

    init(
        front: String,
        back: String,
        example: String? = nil,
        pos: String? = nil,
        catalogKey: String? = nil,
        isLearned: Bool = false
    ) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.example = example
        self.pos = pos
        self.catalogKey = catalogKey
        self.isLearned = isLearned
        self.updatedAt = Date()
        self.easeFactor = 2.5
        self.intervalDays = 0
        self.repetitions = 0
        self.nextReviewDate = isLearned ? Date() : nil
        self.lastReviewed = nil
    }

    var isDue: Bool {
        guard let next = nextReviewDate else { return false }
        return next <= Date()
    }

    var isNew: Bool { lastReviewed == nil && repetitions == 0 && intervalDays == 0 }
}
