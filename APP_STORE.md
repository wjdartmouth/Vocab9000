# Vocab9000 — App Store 提出チェックリスト

対象 Bundle ID: **`com.jianwang.Vocab9000`**  
Widget: **`com.jianwang.Vocab9000.Widget`**  
App Group: **`group.com.jianwang.Vocab9000`**  
最低 OS: **iOS 17.0** / バージョン **1.0 (1)**

---

## 1. Apple Developer / App Store Connect（手動）

- [ ] [Apple Developer Program](https://developer.apple.com) に加入済み（Jian 名義）
- [ ] Certificates / Identifiers / Profiles
  - [ ] App ID `com.jianwang.Vocab9000`（App Groups 有効）
  - [ ] App ID `com.jianwang.Vocab9000.Widget`（同じ App Group）
  - [ ] Group `group.com.jianwang.Vocab9000`
- [ ] App Store Connect で新規アプリ作成
  - プラットフォーム: iOS
  - Bundle ID: 上記と一致
  - SKU: 任意（例 `vocab9000-ios`）
  - プライマリ言語: 日本語

---

## 2. Xcode 側（提出前）

```bash
cd Vocab9000
xcodegen generate
open Vocab9000.xcodeproj
```

- [ ] Signing Team を Jian のチームに設定（App + Widget）
- [ ] Capabilities
  - [ ] **App Groups** → `group.com.jianwang.Vocab9000`（両方）
  - [ ] URL Scheme `vocab9000`（Info にあり）
  - [ ] ローカル通知のみ（Push Notifications capability は不要）
- [ ] `PrivacyInfo.xcprivacy` がターゲットに含まれていること（本リポジトリの Resources / Copy Bundle）
- [ ] Archive → **Distribute App** → App Store Connect
- [ ] Export compliance: 暗号化は HTTPS のみ → **ITSAppUsesNonExemptEncryption = NO**（project.yml 済み）

---

## 3. プライバシー（App Privacy / Nutrition Labels）

**トラッキング: なし**（ATT 不要）

| 項目 | 回答の目安 |
|------|------------|
| データの収集 | **いいえ**（アカウント・分析・広告なし）。学習進捗は端末内 SwiftData / App Group のみ |
| ネットワーク | 任意機能: **Free Dictionary API**（`https://api.dictionaryapi.dev`）へ単語の英語定義を取得。失敗してもオフライン学習可 |
| 通知 | ユーザーが設定でオンにした場合のみローカル通知 |
| トラッキング | なし |
| サードパーティ広告 | なし |
| 購入 | なし（現状） |

App Store Connect → App Privacy で「データを収集しない」または、もし将来分析を入れる場合のみ更新。現状は **収集なし** で問題ない想定。

通知の用途説明（Info）: 「学習リマインダーのために通知を送ります。」

---

## 4. ATS（App Transport Security）

- API は **HTTPS のみ**。Arbitrary Loads は不要・無効のまま。
- 例外ドメインの追加は不要。

---

## 5. スクリーンショットサイズ（必須の例）

App Store Connect の「iPhone」枠。実機またはシミュレータで撮影。

| デバイス枠 | 解像度の例 |
|-----------|------------|
| 6.7" (iPhone 15 Pro Max 等) | 1290 × 2796 |
| 6.5" | 1284 × 2778 |
| 5.5"（求められる場合） | 1242 × 2208 |
| iPad（Universal の場合） | 2048 × 2732 など |

推奨カット（日本語 UI）:
1. カタログ（Longman 9000 一覧）
2. 学習（カードめくり + SM-2 ボタン）
3. 統計（連続日数・チャート）
4. デッキ一覧
5. 設定（リマインダー）またはウィジェット説明

---

## 6. 審査メモ（Review Notes 草案）

```
Vocab9000 は学生向け英単語フラッシュカードです。
・ログイン不要。課金なし。
・語彙リストはオープンな Longman Communication 9000 単語リスト（辞書本文は含みません）。
・日本語訳は CC0 の EJDict-hand および編集による短訳。
・英語定義は任意で Free Dictionary API（HTTPS）から取得し端末にキャッシュします。
・学習リマインダーは設定画面からユーザーが許可した場合のみローカル通知します。
・ウィジェットは App Group で期限枚数・連続日数を表示します。
デモ: 起動 → デッキ「はじめての50語」または学習タブ → カードをめくり評価。
```

---

## 7. 提出物チェック

- [ ] `STORE_LISTING_JP.md` の文言を Connect に転記
- [ ] サポート URL / プライバシーポリシー URL（リポジトリの [PRIVACY_POLICY.md](./PRIVACY_POLICY.md) を GitHub Pages 等で公開可）
- [ ] 年齢制限: 4+（教育・単語帳）
- [ ] 著作権: 年 + Jian Wang
- [ ] カテゴリ: 教育 / Education

詳細なストア文言 → [STORE_LISTING_JP.md](./STORE_LISTING_JP.md)


## 8. 中文市场（简体 / 繁体）本地化

- 应用内 UI：`Localizable.xcstrings`（`ja` / `en` / `zh-Hans` / `zh-Hant`）
- 卡片背面：系统语言为 `zh-Hans*` → `zhHans`；`zh-Hant` / 台湾・香港・澳门 → `zhHant`；否则日文 `ja`
- App Store Connect 本地化：
  - [ ] 添加 **简体中文** — 文案见 [STORE_LISTING_ZH_HANS.md](./STORE_LISTING_ZH_HANS.md)
  - [ ] 添加 **繁体中文**（或 繁体中文（台湾）/ 香港）— 见 [STORE_LISTING_ZH_HANT.md](./STORE_LISTING_ZH_HANT.md)
- 截图：用系统语言切到简体/繁体各拍一套（学习、统计、目录）
- 隐私标签各国区一致（无追踪）；网络仅为可选 Free Dictionary API
