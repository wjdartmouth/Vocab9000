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
            .navigationTitle("統計")
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(
                title: "覚えた語",
                value: "\(stats.learnedCount)",
                subtitle: "/ \(stats.catalogTotal)",
                icon: "checkmark.circle.fill",
                color: AppTheme.learned
            )
            metricTile(
                title: "今日の期限",
                value: "\(stats.dueToday)",
                subtitle: "復習待ち",
                icon: "clock.badge.exclamationmark",
                color: AppTheme.again
            )
            metricTile(
                title: "今日レビュー",
                value: "\(stats.reviewedToday)",
                subtitle: "回・枚",
                icon: "flame.fill",
                color: .orange
            )
            metricTile(
                title: "学習中",
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
            Text("連続学習")
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(stats.streakDays)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.brand)
                Text("日")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: stats.streakDays > 0 ? "flame.fill" : "flame")
                    .font(.largeTitle)
                    .foregroundStyle(stats.streakDays > 0 ? .orange : .secondary)
            }
            if let last = stats.lastStudied {
                Text("最終学習: \(last, formatter: Self.dateFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("まだ学習記録がありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(
                value: Double(stats.learnedCount),
                total: Double(max(stats.catalogTotal, 1))
            )
            .tint(AppTheme.brand)
            Text(String(format: "カタログ進捗 %.1f%%", stats.catalogTotal == 0 ? 0 : 100 * Double(stats.learnedCount) / Double(stats.catalogTotal)))
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
            Text("文字別の習得")
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

            Text("各バーは A–Z（など）ごとの覚えた語の割合です")
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
            Text("文字別の内訳")
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
            Text("デッキ別")
                .font(.headline)
            if stats.byDeck.isEmpty {
                Text("デッキがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats.byDeck) { deck in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(deck.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            if deck.due > 0 {
                                Text("期限 \(deck.due)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.again)
                            }
                        }
                        ProgressView(value: deck.ratio)
                            .tint(AppTheme.brand)
                        Text("\(deck.learned)/\(deck.total) 覚えた")
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
