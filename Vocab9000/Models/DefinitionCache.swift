import Foundation
import SwiftData

@Model
final class DefinitionCache {
    @Attribute(.unique) var word: String
    var definition: String
    var phonetic: String?
    var fetchedAt: Date

    init(word: String, definition: String, phonetic: String? = nil) {
        self.word = word.lowercased()
        self.definition = definition
        self.phonetic = phonetic
        self.fetchedAt = Date()
    }
}
