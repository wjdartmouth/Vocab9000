import SwiftUI
import SwiftData

struct CatalogView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.modelContext) private var context
    @Query private var progress: [ProgressRecord]

    @State private var search = ""
    @State private var selectedLetter: String? = nil
    @State private var posFilter: String = "すべて"

    private let posOptions = ["すべて", "noun", "verb", "adjective", "adverb", "preposition", "pronoun", "conjunction"]

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
        if posFilter != "すべて" {
            list = list.filter { ($0.pos ?? "").lowercased().contains(posFilter) }
        }
        return list
    }

    private var displayList: [CatalogEntry] {
        let limitAll = search.isEmpty && selectedLetter == nil && posFilter == "すべて"
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
                        if search.isEmpty && selectedLetter == nil && posFilter == "すべて" && filtered.count > 200 {
                            Text("文字・品詞・検索で絞り込むと全 \(catalog.entries.count) 語を表示できます")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
                .background(AppTheme.pageBg)
            }
            .navigationTitle("Longman 9000")
            .searchable(text: $search, prompt: "単語を検索")
            .overlay {
                if !catalog.isLoaded {
                    ProgressView("読み込み中…")
                } else if displayList.isEmpty {
                    ContentUnavailableView("見つかりません", systemImage: "magnifyingglass")
                }
            }
        }
    }

    private var letterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("すべて", selected: selectedLetter == nil) { selectedLetter = nil }
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
                    chip(option, selected: posFilter == option) { posFilter = option }
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
                Text(entry.displayPOS)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
