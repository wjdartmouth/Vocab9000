import SwiftUI
import SwiftData

@main
struct Vocab9000App: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            Deck.self,
            FlashCard.self,
            ProgressRecord.self,
            DefinitionCache.self
        ])
    }
}
