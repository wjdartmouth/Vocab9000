import Foundation
import SwiftData
import WidgetKit

enum WidgetDataStore {
    @MainActor
    static func publish(catalog: CatalogStore, context: ModelContext) {
        let stats = StatsService.snapshot(catalog: catalog, context: context)
        let snap = WidgetSnapshot(
            dueToday: stats.dueToday,
            streakDays: stats.streakDays,
            learnedCount: stats.learnedCount,
            updatedAt: Date()
        )
        WidgetSnapshotStore.save(snap)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
