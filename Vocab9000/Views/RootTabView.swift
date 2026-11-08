import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var catalog = CatalogStore.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CatalogView()
                .tabItem { Label(L10n.t("tab.catalog"), systemImage: "books.vertical") }
                .tag(0)

            DeckListView()
                .tabItem { Label(L10n.t("tab.decks"), systemImage: "rectangle.stack") }
                .tag(1)

            ContinueStudyView()
                .tabItem { Label(L10n.t("tab.study"), systemImage: "rectangle.on.rectangle.angled") }
                .tag(2)

            StatsView()
                .tabItem { Label(L10n.t("tab.stats"), systemImage: "chart.bar.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label(L10n.t("tab.settings"), systemImage: "gearshape") }
                .tag(4)
        }
        .tint(AppTheme.brand)
        .environmentObject(catalog)
        .task {
            catalog.loadIfNeeded()
            SeedService.seedIfNeeded(context: context, catalog: catalog)
            SeedService.migrateSRSIfNeeded(context: context)
            publishSharedState()
        }
        .onReceive(NotificationCenter.default.publisher(for: DeepLinkRouter.studyTabNotification)) { _ in
            selectedTab = 2
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == 2 || tab == 3 || tab == 4 {
                publishSharedState()
            }
        }
    }

    private func publishSharedState() {
        WidgetDataStore.publish(catalog: catalog, context: context)
        let due = StatsService.snapshot(catalog: catalog, context: context).dueToday
        NotificationService.syncFromSettings(dueToday: due)
    }
}
