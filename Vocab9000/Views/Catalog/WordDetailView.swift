import SwiftUI
import SwiftData

struct WordDetailView: View {
    let entry: CatalogEntry
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]
    @Query private var progress: [ProgressRecord]

    @State private var definitionText = ""
    @State private var phonetic: String?
    @State private var loading = false
    @State private var showAdd = false
    @State private var toast: String?

    private var isLearned: Bool {
        progress.first { $0.catalogKey == entry.id }?.isLearned ?? false
    }

    private var userDecks: [Deck] { decks.filter { !$0.isBuiltIn } }

    private var preferredGloss: String { entry.primaryBack(locale: .current) }

    private var glossSourceNote: String {
        let id = Locale.current.identifier.lowercased()
        if id.hasPrefix("zh") {
            return "CC-CEDICT (CC BY-SA 4.0) / editor"
        }
        return "EJDict-hand (CC0)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.word)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    if let phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.displayPOS)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.brand)
                    if let sense = entry.sense {
                        Text("sense \(sense)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        SpeechService.shared.speak(entry.word, languageCode: "en")
                    } label: {
                        Label(L10n.t("study.speak"), systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.brand)

                    Button {
                        SeedService.setLearned(
                            catalogKey: entry.id,
                            word: entry.word,
                            learned: !isLearned,
                            context: context
                        )
                    } label: {
                        Label(
                            isLearned ? L10n.t("srs.again") : L10n.t("stats.learned"),
                            systemImage: isLearned ? "arrow.counterclockwise" : "checkmark"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(isLearned ? AppTheme.again : AppTheme.learned)
                }

                glossCard

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("catalog.en_def"))
                        .font(.headline)
                    if loading {
                        ProgressView()
                    } else if definitionText.isEmpty {
                        Text("—")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(definitionText)
                        Text("Free Dictionary API")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.cardFill)
                )

                Button {
                    showAdd = true
                } label: {
                    Label(L10n.t("catalog.add_deck"), systemImage: "plus.rectangle.on.folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(AppTheme.pageBg)
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDefinition() }
        .sheet(isPresented: $showAdd) { addSheet }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .padding()
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
    }

    private var glossCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Locale.current.identifier.lowercased().hasPrefix("zh")
                 ? L10n.t("catalog.zh_label")
                 : L10n.t("catalog.ja_label"))
                .font(.headline)
            if preferredGloss != entry.fallbackBack {
                Text(preferredGloss)
                    .font(.title3.weight(.semibold))
                Text(glossSourceNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
            if let ja = entry.ja, !ja.isEmpty, preferredGloss != ja {
                Text(L10n.t("catalog.ja_label"))
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)
                Text(ja)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private var addSheet: some View {
        NavigationStack {
            List {
                if userDecks.isEmpty {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
                ForEach(userDecks) { deck in
                    Button(deck.title) {
                        add(to: deck)
                        showAdd = false
                        toast = deck.title
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                    }
                }
            }
            .navigationTitle(L10n.t("tab.decks"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { showAdd = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func add(to deck: Deck) {
        let card = FlashCard(
            front: entry.word,
            back: preferredGloss,
            pos: entry.pos,
            catalogKey: entry.id
        )
        card.deck = deck
        context.insert(card)
        try? context.save()
    }

    private func loadDefinition() async {
        if let hit = DefinitionService.shared.cached(word: entry.word, context: context) {
            definitionText = hit.definition
            phonetic = hit.phonetic
            return
        }
        loading = true
        let result = await DefinitionService.shared.definition(for: entry.word, context: context)
        definitionText = result.text
        phonetic = result.phonetic
        loading = false
    }
}
