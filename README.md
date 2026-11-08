# Vocab9000 — Longman Communication 9000 単語帳

学生向け・複数言語対応（TTS 言語切替）の SwiftUI 単語帳アプリです。  
コア語彙は **Longman Communication 9000** の公開単語リスト（lemma / 頻度マーカー / 品詞）をバンドルしています。

## 要件

- macOS + **Xcode 15+**
- **iOS 17.0+**
- SwiftUI / SwiftData / AVFoundation

## データの出典（重要）

| 内容 | 出典 |
|------|------|
| 単語リスト（約 9000 語・lemma / sense / POS） | [MuhammadYaseenKhan/Longman-Communication](https://github.com/MuhammadYaseenKhan/Longman-Communication)（オープンな単語リスト） |
| カード裏面の**日本語訳** | [EJDict-hand](https://github.com/kujirahand/EJDict)（**CC0**・大半）＋未マッチ分は編集部による学習者向け短訳 |
| 補足の英語定義 | [Free Dictionary API](https://dictionaryapi.dev/)（取得後 SwiftData にキャッシュ） |

**Pearson / Longman Dictionary の定義文は一切収録・スクレイピングしていません。**  
学習カードは日本語訳を優先表示し、英語定義は API 取得後に小さく併記します。未マッチ語は品詞フォールバックです。

バンドル JSON: `Vocab9000/Resources/longman9000.json`（`word` / `pos` / `sense?` / `ja?`）

## Xcode で開く方法

### 方法 A: XcodeGen（推奨）

```bash
brew install xcodegen
cd Vocab9000
xcodegen generate
open Vocab9000.xcodeproj
```

シミュレータまたは実機で Run（⌘R）。

### 方法 B: 手動で新規プロジェクトに取り込み

1. Xcode → **File > New > Project > iOS App**
2. Product Name: `Vocab9000`、Interface: **SwiftUI**、Storage: **None**（SwiftData はコード側で設定）、Language: Swift、iOS 17+
3. 生成されたテンプレートの `ContentView.swift` / `*App.swift` を削除
4. このリポジトリの `Vocab9000/` フォルダ内の `.swift` ファイルをプロジェクトに追加（Create groups）
5. `Vocab9000/Resources/longman9000.json` を追加し、**Target Membership** をオン、**Copy Bundle Resources** に含まれることを確認
6. Deployment Target を **iOS 17.0**
7. Run

## 機能

- **カタログ**: A–Z / 品詞フィルタ / 検索、単語詳細、TTS、覚えたマーク、マイデッキへ追加
- **デッキ**: 組み込み仮想デッキ（All / A–C … V–Z）＋マイデッキ CRUD、カード追加・編集・削除
- **学習 / SRS**: SM-2 間隔反復（もう一度 / 難しい / 普通 / 簡単）。期限切れ優先キュー、セッション上限、SwiftData 永続化
- **統計**: 覚えた語数・今日の期限・連続学習日数・最終学習、文字別チャート（Swift Charts）、デッキ別進捗
- **ウィジェット / 通知**: ホーム画面ウィジェット（期限・連続日数）、毎日の学習リマインダー（設定で時刻変更）、`vocab9000://study` ディープリンク
- **オフライン**: 語彙カタログはバンドル、学習進捗・定義キャッシュは SwiftData
- **初回起動**: 組み込みデッキ＋「はじめての50語」サンプルをシード

## ディレクトリ

```
Vocab9000/
├── project.yml
├── README.md
└── Vocab9000/
    ├── Vocab9000App.swift
    ├── Models/
    ├── Services/
    ├── Theme/
    ├── Views/
    └── Resources/longman9000.json
```


## ウィジェット・通知の有効化（Xcode）

1. `xcodegen generate` 後、**Signing & Capabilities** で App / Widget 両方に **App Groups** を追加し、`group.com.jianwang.Vocab9000` にチェック。
2. メインアプリに **Push Notifications** は不要（ローカル通知のみ）。初回は設定タブで通知を許可。
3. 実機またはシミュレータで Run 後、ホーム画面を長押し → **ウィジェットを追加** → Vocab9000。
4. ウィジェットをタップすると `vocab9000://study` で学習タブが開きます（URL Types は Info のカスタム URL Scheme `vocab9000` を Xcode で追加してください）。

手動で URL Scheme を足す場合: Target Vocab9000 → Info → URL Types → Identifier `vocab9000`, Scheme `vocab9000`。

## 注意

- 定義取得にはネットワークが必要です（初回のみ。以降はキャッシュ）。
- 組み込み「All」デッキは約 9000 枚相当の仮想カードです。学習タブは **期限切れ → 新規** の順で出題します（1セッション上限あり）。
- 既存の「覚えた」フラグは初回起動時に SM-2（interval=1日・再提示）へ移行されます。
- 本アプリは教育・学習用途の個人プロジェクト想定です。商標・辞書コンテンツの権利は各権利者に帰属します。
