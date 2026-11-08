import WidgetKit
import SwiftUI

struct DueStreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct DueStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> DueStreakEntry {
        DueStreakEntry(
            date: Date(),
            snapshot: WidgetSnapshot(dueToday: 12, streakDays: 3, learnedCount: 120, updatedAt: Date())
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DueStreakEntry) -> Void) {
        completion(DueStreakEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DueStreakEntry>) -> Void) {
        let snap = WidgetSnapshotStore.load()
        let entry = DueStreakEntry(date: Date(), snapshot: snap)
        // Refresh periodically; app also calls reloadAllTimelines after study.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct DueStreakWidget: Widget {
    let kind = "DueStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DueStreakProvider()) { entry in
            DueStreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Vocab9000 学習")
        .description("今日の復習枚数と連続学習日数を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DueStreakWidgetView: View {
    let entry: DueStreakEntry

    var body: some View {
        Link(destination: AppGroup.studyDeepLink) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "rectangle.on.rectangle.angled")
                    Text("Vocab9000")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.indigo)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.dueToday)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("期限")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(entry.snapshot.streakDays) 日連続", systemImage: "flame.fill")
                    Label("\(entry.snapshot.learnedCount) 語", systemImage: "checkmark.circle")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(4)
        }
        .accessibilityLabel(entry.snapshot.accessibilitySummary)
    }
}
