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
    }
}
