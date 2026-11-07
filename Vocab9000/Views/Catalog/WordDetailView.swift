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
                        Label("読み上げ", systemImage: "speaker.wave.2.fill")
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
                        Label(isLearned ? "未習得に" : "覚えた", systemImage: isLearned ? "arrow.counterclockwise" : "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(isLearned ? AppTheme.again : AppTheme.learned)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("日本語訳")
                        .font(.headline)
                    if let ja = entry.ja, !ja.isEmpty {
                        Text(ja)
                            .font(.title3.weight(.semibold))
                        Text("出典: EJDict-hand（CC0）")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("辞書に一致する訳がありません")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.cardFill)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("英語の定義")
                        .font(.headline)
                    if loading {
                        ProgressView()
                    } else if definitionText.isEmpty {
                        Text("オフラインまたは未取得です。学習時に Free Dictionary API から取得・キャッシュされます。")
                            .foregroundStyle(.secondary)
                        Text("※ Longman Dictionary の定義ではありません。")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(definitionText)
                        Text("出典: Free Dictionary API（Longman Dictionary ではありません）")
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
                    Label("マイデッキに追加", systemImage: "plus.rectangle.on.folder")
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            List {
                if userDecks.isEmpty {
                    Text("先に「デッキ」タブでマイデッキを作成してください")
                        .foregroundStyle(.secondary)
                }
                ForEach(userDecks) { deck in
                    Button(deck.title) {
                        add(to: deck)
                        showAdd = false
                        withAnimation { toast = "「\(deck.title)」に追加しました" }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { toast = nil }
                        }
                    }
                }
            }
            .navigationTitle("デッキを選択")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showAdd = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func add(to deck: Deck) {
        let back = entry.primaryBack
        let card = FlashCard(
            front: entry.word,
            back: back,
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
