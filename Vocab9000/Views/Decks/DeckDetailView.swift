import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Bindable var deck: Deck
    @Environment(\.modelContext) private var context
    @State private var editing: FlashCard?
    @State private var showNew = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text(L10n.t("deck.progress"))
                    Spacer()
                    Text("\(deck.learnedCount)/\(deck.cards.count)")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: deck.progress)
                    .tint(AppTheme.brand)
                NavigationLink(L10n.t("deck.start_study")) {
                    StudySessionView(deck: deck)
                }
            }

            Section(L10n.t("deck.cards")) {
                ForEach(deck.cards) { card in
                    Button {
                        editing = card
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.front).foregroundStyle(.primary)
                                Text(card.back)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if card.isLearned {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.learned)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { context.delete(deck.cards[i]) }
                }
            }
        }
        .navigationTitle(AppTheme.localizedDeckTitle(deck.title))
        .toolbar {
            Button { showNew = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showNew) {
            CardEditorView(deck: deck, card: nil)
        }
        .sheet(item: $editing) { card in
            CardEditorView(deck: deck, card: card)
        }
    }
}

struct BuiltInDeckDetailView: View {
    let deck: Deck
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.modelContext) private var context
    @Query private var progress: [ProgressRecord]

    private var entries: [CatalogEntry] {
        SeedService.catalogEntries(for: deck, catalog: catalog)
    }

    private var learnedKeys: Set<String> {
        Set(progress.filter(\.isLearned).map(\.catalogKey))
    }

    var body: some View {
        let learned = entries.reduce(0) { $0 + (learnedKeys.contains($1.id) ? 1 : 0) }
        List {
            Section {
                HStack {
                    Text(L10n.t("deck.progress"))
                    Spacer()
                    Text("\(learned)/\(entries.count)")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(learned), total: Double(max(entries.count, 1)))
                    .tint(AppTheme.brand)
                NavigationLink(L10n.t("deck.start_study")) {
                    StudySessionView(deck: deck)
                }
            } footer: {
                Text(L10n.t("deck.builtin_footer"))
            }

            Section(L10n.t("deck.preview")) {
                ForEach(entries.prefix(100)) { entry in
                    HStack {
                        Text(entry.word)
                        Spacer()
                        if learnedKeys.contains(entry.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.learned)
                        }
                    }
                }
            }
        }
        .navigationTitle(AppTheme.localizedDeckTitle(deck.title))
    }
}
