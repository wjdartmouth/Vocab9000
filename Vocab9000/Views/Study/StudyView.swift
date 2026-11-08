import SwiftUI
import SwiftData

struct StudySessionView: View {
    let deck: Deck
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.modelContext) private var context

    @State private var items: [StudyItem] = []
    @State private var index = 0
    @State private var showBack = false
    @State private var sessionGraded = 0
    @State private var dueAtStart = 0
    @State private var dragOffset: CGSize = .zero
    @State private var flyOut: CGFloat = 0
    @State private var liveBack: String = ""
    @State private var lastIntervalHint: String?

    private var current: StudyItem? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            if let card = current {
                cardFace(card)
                Text("\(index + 1) / \(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if showBack {
                    gradeRow(for: card)
                } else {
                    HStack(spacing: 14) {
                        Button {
                            flip()
                        } label: {
                            Label("めくる", systemImage: "rectangle.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.brand)

                        Button {
                            SpeechService.shared.speak(card.front, languageCode: deck.languageCode)
                        } label: {
                            Label("読み上げ", systemImage: "speaker.wave.2.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    Text("タップまたはスワイプでも操作できます")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                ContentUnavailableView(
                    items.isEmpty ? "今日の復習はありません" : "セッション完了",
                    systemImage: "checkmark.circle.fill",
                    description: Text(sessionSummary)
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

    private var header: some View {
        VStack(spacing: 8) {
            ProgressView(
                value: Double(min(index, items.count)),
                total: Double(max(items.count, 1))
            )
            .tint(AppTheme.brand)
            .animation(.easeInOut, value: index)
            .padding(.horizontal)

            HStack {
                Label("期限 \(dueAtStart)", systemImage: "clock.badge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(dueAtStart > 0 ? AppTheme.again : .secondary)
                Spacer()
                if let hint = lastIntervalHint {
                    Text("前回 → \(hint)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }

    private var sessionSummary: String {
        if items.isEmpty {
            if let next = SeedService.nextDueDate(for: deck, catalog: catalog, context: context) {
                return "次の復習: \(next, formatter: Self.dueFormatter)"
            }
            return "新しいカードをデッキから追加するか、カタログで学習を開始してください"
        }
        return "今回レビュー: \(sessionGraded)語"
    }

    private static let dueFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func cardFace(_ card: StudyItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)

            VStack(spacing: 12) {
                statusChip(for: card)
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
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(.horizontal)
        .offset(x: dragOffset.width + flyOut)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    if abs(value.translation.width) > 120 {
                        // Left = Again, Right = Good (quick gestures)
                        grade(value.translation.width > 0 ? .good : .again)
                    } else {
                        withAnimation(.spring()) { dragOffset = .zero }
                    }
                }
        )
        .onTapGesture { flip() }
        .id(card.id)
    }

    private func statusChip(for card: StudyItem) -> some View {
        Group {
            if card.isNew {
                Text("新規")
            } else if card.isDue {
                Text("復習")
            } else {
                Text("学習中")
            }
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(AppTheme.brand.opacity(0.15)))
        .foregroundStyle(AppTheme.brand)
    }

    private func gradeRow(for card: StudyItem) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                gradeButton(.again, previewDays: 0)
                gradeButton(.hard, previewDays: max(1, card.intervalDays * 1.2))
                gradeButton(.good, previewDays: card.repetitions == 0 ? 1 : max(1, card.intervalDays * max(card.easeFactor, 2.5)))
                gradeButton(.easy, previewDays: card.repetitions == 0 ? 4 : max(1, card.intervalDays * max(card.easeFactor, 2.5) * 1.3))
            }
            .padding(.horizontal, 12)

            Button {
                SpeechService.shared.speak(card.front, languageCode: deck.languageCode)
            } label: {
                Label("読み上げ", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
        }
    }

    private func gradeButton(_ grade: SRSGrade, previewDays: Double) -> some View {
        let hint = SRSService.formatIntervalHint(days: previewDays, grade: grade)
        return Button {
            self.grade(grade)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: grade.systemImage)
                Text(grade.label)
                    .font(.caption2.weight(.semibold))
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint(for: grade))
    }

    private func tint(for grade: SRSGrade) -> Color {
        switch grade {
        case .again: return AppTheme.again
        case .hard: return .yellow
        case .good: return AppTheme.learned
        case .easy: return .blue
        }
    }

    private func reload() {
        let queue = SeedService.studyQueue(for: deck, catalog: catalog, context: context, capped: true)
        dueAtStart = queue.filter(\.isDue).count
        items = queue
        index = 0
        showBack = false
        liveBack = ""
        sessionGraded = 0
        lastIntervalHint = nil
    }

    private func japaneseBack(for card: StudyItem) -> String {
        if let ja = card.ja, !ja.isEmpty { return ja }
        if let fc = card.flashCard, !fc.back.isEmpty { return fc.back }
        return card.back
    }

    private func englishExtra(for card: StudyItem) -> String? {
        let text = liveBack.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text == japaneseBack(for: card) { return nil }
        return text
    }

    private func flip() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showBack.toggle()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func grade(_ grade: SRSGrade) {
        guard let card = current else { return }
        let dir: CGFloat = (grade == .again || grade == .hard) ? -1 : 1
        withAnimation(.easeIn(duration: 0.25)) {
            flyOut = dir * 500
            dragOffset = .zero
        }
        let preview = SRSService.schedule(
            state: SRSState(
                easeFactor: card.easeFactor,
                intervalDays: card.intervalDays,
                repetitions: card.repetitions,
                nextReviewDate: card.nextReviewDate,
                lastReviewed: nil,
                isLearned: card.isLearned
            ),
            grade: grade
        )
        lastIntervalHint = grade == .again
            ? "<10分"
            : "\(max(1, Int(preview.intervalDays.rounded())))日"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            SeedService.applyGrade(
                catalogKey: card.catalogKey,
                word: card.front,
                grade: grade,
                flashCard: card.flashCard,
                context: context
            )
            sessionGraded += 1
            showBack = false
            liveBack = ""
            flyOut = 0
            if index < items.count - 1 {
                index += 1
            } else {
                index = items.count
            }
            UINotificationFeedbackGenerator()
                .notificationOccurred(grade == .again ? .warning : .success)
        }
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
}

/// Study tab hub: due counts + continue into a deck session
struct ContinueStudyView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var catalog: CatalogStore
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    private static let dueFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    ForEach(studyTargets) { target in
                        NavigationLink {
                            StudySessionView(deck: target.deck)
                        } label: {
                            DeckRowCard(
                                title: target.deck.title,
                                subtitle: subtitle(for: target),
                                progress: target.total == 0 ? 0 : Double(target.learned) / Double(target.total),
                                learned: target.learned,
                                total: target.total,
                                badge: target.due > 0 ? "期限\(target.due)" : (target.deck.isBuiltIn ? "L9000" : "MY")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(AppTheme.pageBg)
            .navigationTitle("学習")
            .overlay {
                if studyTargets.isEmpty {
                    ContentUnavailableView(
                        "学習できるデッキがありません",
                        systemImage: "book",
                        description: Text("カタログまたはデッキから学習を開始してください")
                    )
                }
            }
        }
    }

    private var summaryCard: some View {
        let due = studyTargets.reduce(0) { $0 + $1.due }
        let nextDates = studyTargets.compactMap(\.nextDue)
        let next = nextDates.min()
        return VStack(alignment: .leading, spacing: 8) {
            Text("今日の復習")
                .font(.headline)
            Text("\(due) 枚が期限切れ")
                .font(.title2.bold())
                .foregroundStyle(due > 0 ? AppTheme.again : AppTheme.learned)
            if let next {
                Text("次の予定: \(next, formatter: Self.dueFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if due == 0 {
                Text("予定された復習はすべて完了です")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("SM-2 間隔反復 · もう一度 / 難しい / 普通 / 簡単")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private struct StudyTarget: Identifiable {
        var id: UUID { deck.id }
        let deck: Deck
        let due: Int
        let learned: Int
        let total: Int
        let nextDue: Date?
    }

    private var studyTargets: [StudyTarget] {
        decks.map { deck in
            let due = SeedService.dueCount(for: deck, catalog: catalog, context: context)
            let stats: (Int, Int)
            if deck.isBuiltIn {
                let s = SeedService.builtInStats(for: deck, catalog: catalog, context: context)
                stats = (s.learned, s.total)
            } else {
                stats = (deck.learnedCount, deck.cards.count)
            }
            let next = SeedService.nextDueDate(for: deck, catalog: catalog, context: context)
            return StudyTarget(deck: deck, due: due, learned: stats.0, total: stats.1, nextDue: next)
        }
        .sorted { a, b in
            if a.due != b.due { return a.due > b.due }
            return a.deck.title < b.deck.title
        }
    }

    private func subtitle(for target: StudyTarget) -> String {
        if target.due > 0 {
            return "復習 \(target.due) 枚 · 新規もセッションに混在可"
        }
        if let next = target.nextDue {
            return "次の復習 \(next, formatter: Self.dueFormatter)"
        }
        return target.deck.isBuiltIn ? "仮想デッキ · 期限なし" : AppTheme.languageLabel(target.deck.languageCode)
    }
}
