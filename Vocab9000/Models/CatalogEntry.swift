import Foundation

/// Immutable catalog row loaded from bundled longman9000.json
struct CatalogEntry: Codable, Identifiable, Hashable {
    var id: String { "\(word.lowercased())|\(sense ?? "")|\(pos ?? "")" }
    let word: String
    let pos: String?
    let sense: String?
    /// Japanese gloss (EJDict-hand CC0 + editor)
    let ja: String?
    /// Simplified Chinese (from CC-CEDICT reverse match / editor)
    let zhHans: String?
    /// Traditional Chinese (from CC-CEDICT reverse match / editor)
    let zhHant: String?

    var displayPOS: String {
        guard let pos, !pos.isEmpty else { return "—" }
        return pos
    }

    var letter: String {
        let first = word.first.map { String($0).uppercased() } ?? "#"
        return first.first?.isLetter == true ? first : "#"
    }

    /// Locale-aware card back: zh-* prefer Chinese, else Japanese, else POS fallback.
    func primaryBack(locale: Locale = .current) -> String {
        let id = locale.identifier.lowercased()
        let langs = locale.language.languageCode?.identifier.lowercased() ?? ""
        if id.contains("hant") || id.contains("tw") || id.contains("hk") || id.contains("mo") {
            if let zhHant, !zhHant.isEmpty { return zhHant }
            if let zhHans, !zhHans.isEmpty { return zhHans }
        }
        if langs == "zh" || id.hasPrefix("zh") {
            if let zhHans, !zhHans.isEmpty { return zhHans }
            if let zhHant, !zhHant.isEmpty { return zhHant }
        }
        if let ja, !ja.isEmpty { return ja }
        return fallbackBack
    }

    var primaryBack: String { primaryBack(locale: .current) }

    var fallbackBack: String {
        var parts: [String] = []
        if let pos, !pos.isEmpty { parts.append(pos) }
        parts.append("Longman Communication 9000")
        if let sense { parts.append("sense \(sense)") }
        return parts.joined(separator: " · ")
    }
}
