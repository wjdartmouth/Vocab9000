import SwiftUI
import SwiftData
import UserNotifications

@main
struct Vocab9000App: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onOpenURL { url in
                    DeepLinkRouter.handle(url)
                }
        }
        .modelContainer(for: [
            Deck.self,
            FlashCard.self,
            ProgressRecord.self,
            DefinitionCache.self
        ])
    }
}

enum DeepLinkRouter {
    static let studyTabNotification = Notification.Name("vocab9000.openStudyTab")

    static func openStudy() {
        NotificationCenter.default.post(name: studyTabNotification, object: nil)
    }

    static func handle(_ url: URL) {
        guard url.scheme == "vocab9000" else { return }
        if url.host == "study" || url.path == "/study" || url.path.hasSuffix("study") {
            openStudy()
        }
    }
}
