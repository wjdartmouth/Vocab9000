import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var title: String
    var languageCode: String
    var createdAt: Date
    var isBuiltIn: Bool
    /// Optional filter for virtual built-in letter-range decks, e.g. "A-C"
    var letterRange: String?
    @Relationship(deleteRule: .cascade, inverse: \FlashCard.deck)
    var cards: [FlashCard]

    init(
        title: String,
        languageCode: String = "en",
        isBuiltIn: Bool = false,
        letterRange: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.languageCode = languageCode
        self.createdAt = Date()
        self.isBuiltIn = isBuiltIn
        self.letterRange = letterRange
        self.cards = []
    }

    var learnedCount: Int { cards.filter(\.isLearned).count }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(learnedCount) / Double(cards.count)
    }
}
