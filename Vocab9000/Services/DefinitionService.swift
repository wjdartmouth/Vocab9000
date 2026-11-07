import Foundation
import SwiftData

struct FreeDictionaryResponse: Decodable {
    struct Meaning: Decodable {
        let partOfSpeech: String?
        let definitions: [Definition]
    }
    struct Definition: Decodable {
        let definition: String
        let example: String?
    }
    struct Phonetic: Decodable {
        let text: String?
    }
    let word: String?
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]?
}

@MainActor
final class DefinitionService {
    static let shared = DefinitionService()
    private init() {}

    func cached(word: String, context: ModelContext) -> DefinitionCache? {
        let key = word.lowercased()
        var descriptor = FetchDescriptor<DefinitionCache>(
            predicate: #Predicate { $0.word == key }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Returns cached or freshly fetched definition text. Caches into SwiftData.
    func definition(for word: String, context: ModelContext) async -> (text: String, phonetic: String?) {
        if let hit = cached(word: word, context: context) {
            return (hit.definition, hit.phonetic)
        }
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)") else {
            return ("", nil)
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return ("", nil)
            }
            let decoded = try JSONDecoder().decode([FreeDictionaryResponse].self, from: data)
            guard let first = decoded.first else { return ("", nil) }
            let defs: [String] = (first.meanings ?? []).flatMap { meaning in
                meaning.definitions.prefix(2).map { d in
                    let pos = meaning.partOfSpeech.map { "(\($0)) " } ?? ""
                    return pos + d.definition
                }
            }
            let text = defs.prefix(3).joined(separator: "\n\n")
            let phonetic = first.phonetic
                ?? first.phonetics?.compactMap(\.text).first
            if !text.isEmpty {
                let cache = DefinitionCache(word: word, definition: text, phonetic: phonetic)
                context.insert(cache)
                try? context.save()
            }
            return (text, phonetic)
        } catch {
            return ("", nil)
        }
    }
}
