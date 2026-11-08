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
                    Toggle("毎日の学習リマインダー", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, on in
                            Task { await handleToggle(on) }
                        }

                    DatePicker(
                        "通知時刻",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!notificationsEnabled)
                    .onChange(of: reminderTime) { _, date in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                        NotificationService.reminderHour = parts.hour ?? 20
                        NotificationService.reminderMinute = parts.minute ?? 0
                        republishAndReschedule()
                        statusMessage = "通知時刻を更新しました"
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("期限がある日は枚数付きで知らせます。デフォルトは 20:00 です。App Group と通知の許可が必要です。")
                }

                if permissionDenied {
                    Section {
                        Text("設定アプリで Vocab9000 の通知を許可してください。")
                            .foregroundStyle(.orange)
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            Link("システム設定を開く", destination: url)
                        }
                    }
                }

                Section("ウィジェット") {
                    Text("ホーム画面でウィジェットを追加すると、今日の期限と連続学習日数が表示されます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("ウィジェットデータを更新") {
                        republishAndReschedule()
                        statusMessage = "ウィジェットを更新しました"
                    }
                }

                Section("ディープリンク") {
                    Text("vocab9000://study → 学習タブ")
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
            .navigationTitle("設定")
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
                statusMessage = "通知が許可されませんでした"
                return
            }
            permissionDenied = false
            NotificationService.isEnabled = true
            republishAndReschedule()
            statusMessage = "リマインダーをオンにしました"
        } else {
            NotificationService.isEnabled = false
            NotificationService.refreshSchedule(dueToday: 0)
            statusMessage = "リマインダーをオフにしました"
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
