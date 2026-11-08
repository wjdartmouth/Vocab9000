import Foundation
import UserNotifications

/// Handles notification taps → same deep link path as the widget (`vocab9000://study`).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        if let link = info["deepLink"] as? String, let url = URL(string: link) {
            await MainActor.run { DeepLinkRouter.handle(url) }
            return
        }
        await MainActor.run { DeepLinkRouter.openStudy() }
    }
}
