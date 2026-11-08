import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var catalog: CatalogStore
    @Query private var progressTick: [ProgressRecord]
    @Query private var cardTick: [FlashCard]

    private var stats: StudyStatsSnapshot {
        // Depend on query arrays so SwiftUI refreshes when data changes
        _ = progressTick.count
        _ = cardTick.count
        return StatsService.snapshot(catalog: catalog, context: context)
    }

    private static let dateFormatter: DateFormatter = {
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
                    overviewGrid
                    streakCard
                    letterChartCard
                    letterListCard
                    deckListCard
                }
                .padding()
            }
            .background(AppTheme.pageBg)
            .navigationTitle(L10n.t("stats.title"))
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(
                title: L10n.t("stats.learned"),
                value: "\(stats.learnedCount)",
                subtitle: "/ \(stats.catalogTotal)",
                icon: "checkmark.circle.fill",
                color: AppTheme.learned
            )
            metricTile(
                title: L10n.t("stats.due_today"),
                value: "\(stats.dueToday)",
                subtitle: "復習待ち",
                icon: "clock.badge.exclamationmark",
                color: AppTheme.again
            )
            metricTile(
                title: L10n.t("stats.reviewed_today"),
                value: "\(stats.reviewedToday)",
                subtitle: "回・枚",
                icon: "flame.fill",
                color: .orange
            )
            metricTile(
                title: L10n.t("stats.in_progress"),
                value: "\(stats.inProgress)",
                subtitle: "未定着",
                icon: "arrow.triangle.2.circlepath",
                color: AppTheme.brand
            )
        }
    }

    private func metricTile(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("stats.streak"))
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(stats.streakDays)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.brand)
                Text(L10n.t("stats.day"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: stats.streakDays > 0 ? "flame.fill" : "flame")
                    .font(.largeTitle)
                    .foregroundStyle(stats.streakDays > 0 ? .orange : .secondary)
            }
            if let last = stats.lastStudied {
                Text(L10n.format("stats.last", Self.dateFormatter.string(from: last)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.t("stats.never"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(
                value: Double(stats.learnedCount),
                total: Double(max(stats.catalogTotal, 1))
            )
            .tint(AppTheme.brand)
            Text(L10n.format("stats.catalog_progress", stats.catalogTotal == 0 ? 0.0 : 100 * Double(stats.learnedCount) / Double(stats.catalogTotal)))
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

    private var letterChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("stats.by_letter"))
                .font(.headline)
            Chart(stats.byLetter) { item in
                BarMark(
                    x: .value("文字", item.letter),
                    y: .value("習得率", item.ratio * 100)
                )
                .foregroundStyle(AppTheme.brand.gradient)
            }
            .chartYAxisLabel("%")
            .chartYScale(domain: 0...100)
            .frame(height: 200)

            Text(L10n.t("stats.by_letter_hint"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private var letterListCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("stats.by_letter_detail"))
                .font(.headline)
            ForEach(stats.byLetter.filter { $0.learned > 0 || $0.total > 0 }) { item in
                HStack {
                    Text(item.letter)
                        .font(.headline.monospaced())
                        .frame(width: 28, alignment: .leading)
                    ProgressView(value: item.ratio)
                        .tint(AppTheme.brand)
                    Text("\(item.learned)/\(item.total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 64, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private var deckListCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("stats.by_deck"))
                .font(.headline)
            if stats.byDeck.isEmpty {
                Text(L10n.t("stats.no_decks"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats.byDeck) { deck in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(AppTheme.localizedDeckTitle(deck.title))
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            if deck.due > 0 {
                                Text(L10n.format("stats.due_badge", deck.due))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.again)
                            }
                        }
                        ProgressView(value: deck.ratio)
                            .tint(AppTheme.brand)
                        Text(L10n.format("stats.learned_of", deck.learned, deck.total))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }
}
