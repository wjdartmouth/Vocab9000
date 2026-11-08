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
        .configurationDisplayName(String(localized: "widget.display_name"))
        .description(String(localized: "widget.description"))
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
                    Text(String(localized: "widget.due_label"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label(
                        String(format: String(localized: "widget.streak"), entry.snapshot.streakDays),
                        systemImage: "flame.fill"
                    )
                    Label(
                        String(format: String(localized: "widget.learned"), entry.snapshot.learnedCount),
                        systemImage: "checkmark.circle"
                    )
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(4)
        }
        .accessibilityLabel(
            String(
                format: String(localized: "widget.a11y"),
                entry.snapshot.dueToday,
                entry.snapshot.streakDays,
                entry.snapshot.learnedCount
            )
        )
    }
}
