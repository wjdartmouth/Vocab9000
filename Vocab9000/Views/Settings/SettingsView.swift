import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var catalog: CatalogStore

    @State private var notificationsEnabled = NotificationService.isEnabled
    @State private var reminderTime: Date = Self.date(hour: NotificationService.reminderHour,
                                                       minute: NotificationService.reminderMinute)
    @State private var permissionDenied = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(L10n.t("settings.reminder_toggle"), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, on in
                            Task { await handleToggle(on) }
                        }

                    DatePicker(
                        L10n.t("settings.reminder_time"),
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!notificationsEnabled)
                    .onChange(of: reminderTime) { _, date in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                        NotificationService.reminderHour = parts.hour ?? 20
                        NotificationService.reminderMinute = parts.minute ?? 0
                        republishAndReschedule()
                        statusMessage = L10n.t("settings.time_updated")
                    }
                } header: {
                    Text(L10n.t("settings.notifications"))
                } footer: {
                    Text(L10n.t("settings.notifications_footer"))
                }

                if permissionDenied {
                    Section {
                        Text(L10n.t("settings.permission_denied"))
                            .foregroundStyle(.orange)
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            Link(L10n.t("settings.open_system"), destination: url)
                        }
                    }
                }

                Section(L10n.t("settings.widget")) {
                    Text(L10n.t("settings.widget_hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(L10n.t("settings.widget_refresh")) {
                        republishAndReschedule()
                        statusMessage = L10n.t("settings.widget_updated")
                    }
                }

                Section(L10n.t("settings.deeplink")) {
                    Text(L10n.t("settings.deeplink_study"))
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(AppTheme.brand)
                    }
                }
            }
            .navigationTitle(L10n.t("settings.title"))
            .onAppear {
                notificationsEnabled = NotificationService.isEnabled
                reminderTime = Self.date(
                    hour: NotificationService.reminderHour,
                    minute: NotificationService.reminderMinute
                )
            }
        }
    }

    private func handleToggle(_ on: Bool) async {
        if on {
            let ok = await NotificationService.requestPermission()
            if !ok {
                notificationsEnabled = false
                NotificationService.isEnabled = false
                permissionDenied = true
                statusMessage = L10n.t("settings.reminder_denied")
                return
            }
            permissionDenied = false
            NotificationService.isEnabled = true
            republishAndReschedule()
            statusMessage = L10n.t("settings.reminder_on")
        } else {
            NotificationService.isEnabled = false
            NotificationService.refreshSchedule(dueToday: 0)
            statusMessage = L10n.t("settings.reminder_off")
        }
    }

    private func republishAndReschedule() {
        WidgetDataStore.publish(catalog: catalog, context: context)
        let due = StatsService.snapshot(catalog: catalog, context: context).dueToday
        NotificationService.syncFromSettings(dueToday: due)
    }

    private static func date(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}
