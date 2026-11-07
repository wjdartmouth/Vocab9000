import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    static let shared = CatalogStore()

    @Published private(set) var entries: [CatalogEntry] = []
    @Published private(set) var isLoaded = false

    private var byLetter: [String: [CatalogEntry]] = [:]

    private init() {}

    func loadIfNeeded() {
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "longman9000", withExtension: "json") else {
            print("CatalogStore: longman9000.json not found in bundle")
            isLoaded = true
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([CatalogEntry].self, from: data)
            entries = decoded
            byLetter = Dictionary(grouping: decoded, by: \.letter)
            isLoaded = true
        } catch {
            print("CatalogStore load error: \(error)")
            isLoaded = true
        }
    }

    var letters: [String] {
        byLetter.keys.sorted()
    }

    func entries(forLetter letter: String) -> [CatalogEntry] {
        byLetter[letter] ?? []
    }

    func entries(matching query: String) -> [CatalogEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { $0.word.lowercased().hasPrefix(q) || $0.word.lowercased().contains(q) }
    }

    func entries(posContains token: String) -> [CatalogEntry] {
        let t = token.lowercased()
        return entries.filter { ($0.pos ?? "").lowercased().contains(t) }
    }

    func entry(forKey key: String) -> CatalogEntry? {
        entries.first { $0.id == key }
    }

    /// Letters inclusive range like "A"..."C"
    func entries(letterRange start: Character, end: Character) -> [CatalogEntry] {
        entries.filter { entry in
            guard let c = entry.letter.first, c.isLetter else { return false }
            return c >= start && c <= end
        }
    }
}
