import Foundation

enum AppGroup {
    /// Enable App Groups for `group.com.jianwang.Vocab9000` on both app + widget targets in Xcode.
    static let id = "group.com.jianwang.Vocab9000"
    static let snapshotKey = "widget.snapshot.v1"
    static let studyDeepLink = URL(string: "vocab9000://study")!

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

struct WidgetSnapshot: Codable, Equatable {
    var dueToday: Int
    var streakDays: Int
    var learnedCount: Int
    var updatedAt: Date

    static let empty = WidgetSnapshot(dueToday: 0, streakDays: 0, learnedCount: 0, updatedAt: .distantPast)

    var accessibilitySummary: String {
        // Localized in widget UI; this is a fallback for VoiceOver before render.
        "due \(dueToday), streak \(streakDays), learned \(learnedCount)"
    }
}

enum WidgetSnapshotStore {
    static func load() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.snapshotKey),
              let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return decoded
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.snapshotKey)
        AppGroup.defaults.synchronize()
    }
}
