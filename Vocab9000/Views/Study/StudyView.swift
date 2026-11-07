import SwiftUI
import SwiftData

struct StudySessionView: View {
    let deck: Deck
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.modelContext) private var context

    @State private var items: [StudyItem] = []
    @State private var index = 0
    @State private var showBack = false
    @State private var sessionLearned = 0
    @State private var dragOffset: CGSize = .zero
    @State private var flyOut: CGFloat = 0
    @State private var liveBack: String = ""

    private var current: StudyItem? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(
                value: Double(min(index, items.count)),
                total: Double(max(items.count, 1))
            )
            .tint(AppTheme.brand)
            .animation(.easeInOut, value: index)
            .padding(.horizontal)

            if let card = current {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)

                    VStack(spacing: 12) {
                        if let pos = card.pos, !showBack {
                            Text(pos)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.brand)
                        }
                        if showBack {
                            Text(japaneseBack(for: card))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.4)
                                .padding(.horizontal, 8)
                            if let en = englishExtra(for: card) {
                                Text(en)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                            }
                        } else {
                            Text(card.front)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.4)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(28)
                    .rotation3DEffect(
                        .degrees(showBack ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.6
                    )
                    .scaleEffect(x: showBack ? -1 : 1)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
                .padding(.horizontal)
                .offset(x: dragOffset.width + flyOut)
                .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation }
                        .onEnded { value in
                            if abs(value.translation.width) > 120 {
                                flyAway(learned: value.translation.width > 0)
                            } else {
                                withAnimation(.spring()) { dragOffset = .zero }
                            }
                        }
                )
                .onTapGesture { flip() }
                .id(card.id)

                Text("\(index + 1) / \(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    studyButton("まだ", system: "arrow.counterclockwise", tint: AppTheme.again) {
                        flyAway(learned: false)
                    }
                    studyButton("読み上げ", system: "speaker.wave.2.fill", tint: AppTheme.brand) {
                        SpeechService.shared.speak(card.front, languageCode: deck.languageCode)
                    }
                    studyButton("覚えた", system: "checkmark", tint: AppTheme.learned) {
                        flyAway(learned: true)
                    }
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "完了 🎉",
                    systemImage: "checkmark.circle.fill",
                    description: Text("今回覚えた: \(sessionLearned)語")
                )
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
        .task(id: current?.id) {
            await prefetchDefinition()
        }
    }

    private func reload() {
        // Prefer unlearned first; cap session size for large built-in decks
        let all = SeedService.studyItems(for: deck, catalog: catalog, context: context)
        let unlearned = all.filter { !$0.isLearned }
        let pool = unlearned.isEmpty ? all : unlearned
        let sessionSize = deck.isBuiltIn ? 50 : pool.count
        items = Array(pool.prefix(sessionSize))
        index = 0
        showBack = false
        liveBack = ""
    }

    private func japaneseBack(for card: StudyItem) -> String {
        if let ja = card.ja, !ja.isEmpty { return ja }
        if let fc = card.flashCard, !fc.back.isEmpty { return fc.back }
        return card.back
    }

    /// Optional English gloss from Free Dictionary API (not Longman Dictionary).
    private func englishExtra(for card: StudyItem) -> String? {
        let text = liveBack.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        // Avoid duplicating Japanese if somehow cached same
        if text == japaneseBack(for: card) { return nil }
        return text
    }

    private func flip() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showBack.toggle()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func flyAway(learned: Bool) {
        guard let card = current else { return }
        let dir: CGFloat = learned ? 1 : -1
        withAnimation(.easeIn(duration: 0.25)) {
            flyOut = dir * 500
            dragOffset = .zero
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            applyLearned(card: card, learned: learned)
            if learned { sessionLearned += 1 }
            showBack = false
            liveBack = ""
            flyOut = 0
            if index < items.count - 1 {
                index += 1
            } else {
                index = items.count
            }
            UINotificationFeedbackGenerator()
                .notificationOccurred(learned ? .success : .warning)
        }
    }

    private func applyLearned(card: StudyItem, learned: Bool) {
        if let fc = card.flashCard {
            fc.isLearned = learned
            fc.updatedAt = Date()
        }
        if let key = card.catalogKey {
            SeedService.setLearned(
                catalogKey: key,
                word: card.front,
                learned: learned,
                context: context
            )
        }
        try? context.save()
    }

    private func prefetchDefinition() async {
        guard let card = current else { return }
        liveBack = ""
        if let hit = DefinitionService.shared.cached(word: card.front, context: context) {
            liveBack = hit.definition
            return
        }
        let result = await DefinitionService.shared.definition(for: card.front, context: context)
        if !result.text.isEmpty {
            liveBack = result.text
        }
    }

    private func studyButton(
        _ title: String,
        system: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

/// Study tab: continue from first deck with remaining unlearned cards / progress
struct ContinueStudyView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var catalog: CatalogStore
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    var body: some View {
        NavigationStack {
            if let deck = pickDeck() {
                StudySessionView(deck: deck)
            } else {
                ContentUnavailableView(
                    "学習できるデッキがありません",
                    systemImage: "book",
                    description: Text("カタログまたはデッキから学習を開始してください")
                )
            }
        }
    }

    private func pickDeck() -> Deck? {
        for deck in decks where !deck.isBuiltIn {
            if deck.cards.contains(where: { !$0.isLearned }) { return deck }
        }
        let ordered = decks.filter(\.isBuiltIn).sorted { a, b in
            let aAll = a.letterRange == "A-Z"
            let bAll = b.letterRange == "A-Z"
            if aAll != bAll { return !aAll && bAll }
            return a.title < b.title
        }
        for deck in ordered {
            let stats = SeedService.builtInStats(for: deck, catalog: catalog, context: context)
            if stats.learned < stats.total { return deck }
        }
        return decks.first
    }
}
