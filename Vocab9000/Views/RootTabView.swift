import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var catalog = CatalogStore.shared

    var body: some View {
        TabView {
            CatalogView()
                .tabItem { Label("カタログ", systemImage: "books.vertical") }

            DeckListView()
                .tabItem { Label("デッキ", systemImage: "rectangle.stack") }

            ContinueStudyView()
                .tabItem { Label("学習", systemImage: "rectangle.on.rectangle.angled") }
        }
        .tint(AppTheme.brand)
        .environmentObject(catalog)
        .task {
            catalog.loadIfNeeded()
            SeedService.seedIfNeeded(context: context, catalog: catalog)
        }
    }
}
