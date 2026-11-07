import Foundation
import SwiftData

/// Per-catalog-word learning state (works with virtual letter decks / catalog study)
@Model
final class ProgressRecord {
    @Attribute(.unique) var catalogKey: String
    var word: String
    var isLearned: Bool
    var updatedAt: Date

    init(catalogKey: String, word: String, isLearned: Bool = false) {
        self.catalogKey = catalogKey
        self.word = word
        self.isLearned = isLearned
        self.updatedAt = Date()
    }
}
