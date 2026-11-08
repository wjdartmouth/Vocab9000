import SwiftUI
import SwiftData

struct CatalogView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.modelContext) private var context
    @Query private var progress: [ProgressRecord]

    @State private var search = ""
    @State private var selectedLetter: String? = nil
    @State private var posFilter: String = "all"

    private let posOptions = ["all", "noun", "verb", "adjective", "adverb", "preposition", "pronoun", "conjunction"]

    private var learnedKeys: Set<String> {
        Set(progress.filter(\.isLearned).map(\.catalogKey))
    }

    private var filtered: [CatalogEntry] {
        var list: [CatalogEntry]
        if !search.isEmpty {
            list = catalog.entries(matching: search)
        } else if let letter = selectedLetter {
            list = catalog.entries(forLetter: letter)
        } else {
            list = catalog.entries
        }
        if posFilter != "all" {
            list = list.filter { ($0.pos ?? "").lowercased().contains(posFilter) }
        }
        return list
    }

    private var displayList: [CatalogEntry] {
        let limitAll = search.isEmpty && selectedLetter == nil && posFilter == "all"
        return limitAll ? Array(filtered.prefix(200)) : filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                letterBar
                posBar
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(displayList) { entry in
                            NavigationLink {
                                WordDetailView(entry: entry)
                            } label: {
                                wordRow(entry)
                            }
                            .buttonStyle(.plain)
                        }
                        if search.isEmpty && selectedLetter == nil && posFilter == "all" && filtered.count > 200 {
                            Text(L10n.format("catalog.limit_hint", catalog.entries.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
                .background(AppTheme.pageBg)
            }
            .navigationTitle(L10n.t("catalog.title"))
            .searchable(text: $search, prompt: L10n.t("catalog.search"))
            .overlay {
                if !catalog.isLoaded {
                    ProgressView(L10n.t("catalog.loading"))
                } else if displayList.isEmpty {
                    ContentUnavailableView(L10n.t("catalog.not_found"), systemImage: "magnifyingglass")
                }
            }
        }
    }

    private var letterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(L10n.t("catalog.all"), selected: selectedLetter == nil) { selectedLetter = nil }
                ForEach(catalog.letters, id: \.self) { letter in
                    chip(letter, selected: selectedLetter == letter) {
                        selectedLetter = letter
                        search = ""
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var posBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(posOptions, id: \.self) { option in
                    chip(option == "all" ? L10n.t("catalog.all") : option, selected: posFilter == option) {
                        posFilter = option
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(selected ? AppTheme.brand : AppTheme.cardFill))
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func wordRow(_ entry: CatalogEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(entry.primaryBack(locale: .current) == entry.fallbackBack ? entry.displayPOS : entry.primaryBack(locale: .current))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if learnedKeys.contains(entry.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.learned)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }
}
