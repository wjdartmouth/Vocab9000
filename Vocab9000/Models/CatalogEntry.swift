import Foundation

/// Immutable catalog row loaded from bundled longman9000.json
struct CatalogEntry: Codable, Identifiable, Hashable {
    var id: String { "\(word.lowercased())|\(sense ?? "")|\(pos ?? "")" }
    let word: String
    let pos: String?
    let sense: String?
    /// Japanese gloss from EJDict-hand (CC0); optional for unmatched lemmas
    let ja: String?

    var displayPOS: String {
        guard let pos, !pos.isEmpty else { return "—" }
        return pos
    }

    var letter: String {
        let first = word.first.map { String($0).uppercased() } ?? "#"
        return first.first?.isLetter == true ? first : "#"
    }

    /// Prefer Japanese gloss on card backs; fall back to POS label.
    var primaryBack: String {
        if let ja, !ja.isEmpty { return ja }
        return fallbackBack
    }

    var fallbackBack: String {
        var parts: [String] = []
        if let pos, !pos.isEmpty { parts.append(pos) }
        parts.append("Longman Communication 9000")
        if let sense { parts.append("sense \(sense)") }
        return parts.joined(separator: " · ")
    }
}
