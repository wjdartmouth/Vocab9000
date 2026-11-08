import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var catalog: CatalogStore
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]
    @Query private var progress: [ProgressRecord]

    @State private var showNew = false
    @State private var newTitle = ""
    @State private var newLang = "en"

    private var builtIn: [Deck] { decks.filter(\.isBuiltIn) }
    private var mine: [Deck] { decks.filter { !$0.isBuiltIn } }

    private var globalLearned: Int { progress.filter(\.isLearned).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    summaryHeader

                    if !mine.isEmpty {
                        sectionTitle(L10n.t("decks.mine"))
                        ForEach(mine) { deck in
                            NavigationLink { DeckDetailView(deck: deck) } label: {
                                DeckRowCard(
                                    title: AppTheme.localizedDeckTitle(deck.title),
                                    subtitle: AppTheme.languageLabel(deck.languageCode),
                                    progress: deck.progress,
                                    learned: deck.learnedCount,
                                    total: deck.cards.count,
                                    badge: "MY"
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                NavigationLink { StudySessionView(deck: deck) } label: {
                                    Label(L10n.t("decks.study"), systemImage: "rectangle.on.rectangle.angled")
                                }
                                Button(role: .destructive) {
                                    withAnimation { context.delete(deck) }
                                } label: {
                                    Label(L10n.t("common.delete"), systemImage: "trash")
                                }
                            }
                        }
                    }

                    sectionTitle(L10n.t("decks.builtin"))
                    ForEach(builtIn) { deck in
                        NavigationLink { BuiltInDeckDetailView(deck: deck) } label: {
                            builtInRow(deck)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(AppTheme.pageBg)
            .navigationTitle(L10n.t("decks.title"))
            .toolbar {
                Button { showNew = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.brand)
                }
            }
            .sheet(isPresented: $showNew) { newDeckSheet }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("decks.catalog_progress"))
                .font(.headline)
            ProgressView(value: Double(globalLearned), total: Double(max(catalog.entries.count, 1)))
                .tint(AppTheme.brand)
            Text(L10n.format("decks.words_count", globalLearned, catalog.entries.count))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func builtInRow(_ deck: Deck) -> some View {
        let stats = SeedService.builtInStats(for: deck, catalog: catalog, context: context)
        let progress = stats.total == 0 ? 0.0 : Double(stats.learned) / Double(stats.total)
        return DeckRowCard(
            title: AppTheme.localizedDeckTitle(deck.title),
            subtitle: L10n.format("decks.virtual", stats.total),
            progress: progress,
            learned: stats.learned,
            total: stats.total,
            badge: "L9000"
        )
    }

    private var newDeckSheet: some View {
        NavigationStack {
            Form {
                TextField(L10n.t("decks.name"), text: $newTitle)
                Picker(L10n.t("decks.language"), selection: $newLang) {
                    ForEach(AppTheme.languages, id: \.code) { item in
                        Text(item.label).tag(item.code)
                    }
                }
            }
            .navigationTitle(L10n.t("decks.new"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { showNew = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.create")) {
                        let title = newTitle.trimmingCharacters(in: .whitespaces)
                        guard !title.isEmpty else { return }
                        withAnimation(.spring()) {
                            context.insert(Deck(title: title, languageCode: newLang))
                        }
                        newTitle = ""
                        showNew = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
