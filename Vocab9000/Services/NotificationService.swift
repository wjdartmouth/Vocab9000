import Foundation
import UserNotifications

enum NotificationService {
    static let reminderId = "vocab9000.daily.reminder"
    private static let enabledKey = "settings.notifications.enabled"
    private static let hourKey = "settings.notifications.hour"
    private static let minuteKey = "settings.notifications.minute"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var reminderHour: Int {
        get {
            let v = UserDefaults.standard.object(forKey: hourKey) as? Int
            return v ?? 20
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var reminderMinute: Int {
        get {
            let v = UserDefaults.standard.object(forKey: minuteKey) as? Int
            return v ?? 0
        }
        set { UserDefaults.standard.set(newValue, forKey: minuteKey) }
    }

    static var reminderDateComponents: DateComponents {
        var c = DateComponents()
        c.hour = reminderHour
        c.minute = reminderMinute
        return c
    }

    @MainActor
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule or cancel the daily reminder. Body mentions due count when > 0.
    static func refreshSchedule(dueToday: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])

        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.t("notif.title")
        if dueToday > 0 {
            content.body = L10n.format("notif.body_due", dueToday)
        } else {
            content.body = L10n.t("notif.body_generic")
        }
        content.sound = .default
        content.userInfo = ["deepLink": "vocab9000://study"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: reminderDateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: reminderId,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func syncFromSettings(dueToday: Int) {
        refreshSchedule(dueToday: dueToday)
    }
}
