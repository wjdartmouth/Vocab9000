# Privacy Policy — Vocab9000

**Last updated:** 8 November 2026  
**App:** Vocab9000 (`com.jianwang.Vocab9000`)  
**Developer:** Jian Wang  
**Contact:** [GitHub Issues](https://github.com/wjdartmouth/Vocab9000/issues)

This policy describes how Vocab9000 handles information. The app is designed for on-device learning with minimal data leaving your device.

---

## English

### Summary
Vocab9000 does **not** require an account, does **not** show ads, and does **not** track you for advertising or analytics. Learning progress stays on your device. Optional network use is limited to fetching English definitions. Local notifications and a home-screen widget use data only on your device (and, for the widget, a shared App Group container on the same device).

### Information we do **not** collect
- No sign-up, login, or user profile
- No advertising identifiers or third-party ad SDKs
- No analytics / crash-reporting SDKs that send personal data to us
- No sale or sharing of personal data with data brokers

### Information stored **on your device**
Vocab9000 stores learning-related data locally using **SwiftData** (and related on-device storage), including for example:
- Decks and flashcards you create or edit
- Spaced-repetition / progress fields (e.g. learned status, review schedule)
- Cached English definitions after a successful fetch
- Your notification preference and reminder time (UserDefaults)

This data remains on your device unless you back up or transfer the device with your own system tools (e.g. iCloud device backup), which is controlled by Apple and your account settings—not by Vocab9000 servers (we do not operate an app backend for user data).

### Optional network: Free Dictionary API
If you view English definitions (e.g. on a word detail or study screen), the app may request definitions from the **Free Dictionary API** (`https://api.dictionaryapi.dev`) for the English headword.  
- Only the word needed for lookup is sent to that service.  
- Successful responses may be **cached on device** so later opens work offline.  
- If the request fails or you are offline, learning still works using bundled glosses (Japanese / Chinese as available).  
We do not control the Free Dictionary API’s own servers or policies; use of that service is optional for the English-definition feature.

### Local notifications
If you enable the daily study reminder in Settings and grant notification permission, Vocab9000 schedules **local** notifications on your device (default evening time, configurable).  
- Notifications are not sent from our servers.  
- You can turn reminders off in-app or revoke permission in iOS Settings.

### App Group and widget
The home-screen widget reads a small **on-device** snapshot (e.g. due count, streak, learned count) via the App Group `group.com.jianwang.Vocab9000`.  
- This sharing is between the main app and the widget extension on the **same device**.  
- It is not uploaded to Vocab9000 servers (none exist for this purpose).

### Children’s privacy
Vocab9000 is a general vocabulary study app (App Store age rating as declared). We do not knowingly collect personal information from children. There is no account system for creating child profiles.

### Your choices
- Disable network: avoid opening English-definition fetches; core study with bundled glosses still works.  
- Disable notifications: Settings in-app or iOS Settings → Vocab9000.  
- Remove widget data: remove the widget; uninstalling the app removes App Group data with the app.  
- Delete local study data: delete/reinstall the app (or clear app data via iOS as available).

### Changes
We may update this policy when the app’s practices change. The “Last updated” date will be revised; continued use after changes means you accept the updated policy where applicable.

### Contact
Questions about privacy: open an issue at  
https://github.com/wjdartmouth/Vocab9000/issues

---

## 日本語（要約）

Vocab9000 は **アカウント不要・広告なし・トラッキングなし** の単語帳アプリです。

- **端末内:** 学習進捗・デッキ・間隔反復データなどは **SwiftData** 等で端末に保存します。当社のユーザーデータ用サーバーはありません。  
- **任意の通信:** 英語の定義表示時のみ **Free Dictionary API** に英単語を問い合わせ、成功時は端末にキャッシュします。失敗・オフラインでもバンドル訳で学習できます。  
- **通知:** 設定でオンにした場合のみ **ローカル通知**（サーバー配信ではありません）。  
- **ウィジェット:** App Group（`group.com.jianwang.Vocab9000`）で同一端末内の期限枚数・連続日数などを共有します。  
- **連絡先:** https://github.com/wjdartmouth/Vocab9000/issues

詳細は上記 English 本文に準じます。

---

## 简体中文（摘要）

Vocab9000 **无需账号、无广告、不用于广告的追踪**。

- **仅存本机：** 学习进度、卡组、间隔重复等数据保存在设备上的 **SwiftData** 等本地存储中；我们不运营用于存储用户学习数据的应用服务器。  
- **可选联网：** 查看英文释义时，可能向 **Free Dictionary API** 查询该英文词，成功后可缓存在本机；离线仍可用内置中文/日文释义学习。  
- **通知：** 仅在您于设置中开启并授权后，使用设备上的 **本地通知**。  
- **小组件：** 通过 App Group（`group.com.jianwang.Vocab9000`）在 **同一设备** 上与主应用共享到期数量、连续天数等摘要。  
- **联系：** https://github.com/wjdartmouth/Vocab9000/issues

完整说明以英文正文为准。

---

## 繁體中文（摘要）

Vocab9000 **不需帳號、無廣告、不作廣告追蹤**。

- **僅存本機：** 學習進度、卡組、間隔重複等資料保存在裝置上的 **SwiftData** 等本地儲存；我們不營運用於存放使用者學習資料的 App 伺服器。  
- **可選連網：** 查看英文釋義時，可能向 **Free Dictionary API** 查詢該英文詞，成功後可快取於本機；離線仍可用內建中文／日文釋義學習。  
- **通知：** 僅在您於設定中開啟並授權後，使用裝置上的 **本地通知**。  
- **小組件：** 透過 App Group（`group.com.jianwang.Vocab9000`）在 **同一裝置** 上與主應用程式共用到期數量、連續天數等摘要。  
- **聯絡：** https://github.com/wjdartmouth/Vocab9000/issues

完整說明以英文正文為準。
