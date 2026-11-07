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
- **学習**: 3D めくり（裏面=日本語訳優先）、スワイプ、TTS、ハプティクス、英語定義の任意表示
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

## 注意

- 定義取得にはネットワークが必要です（初回のみ。以降はキャッシュ）。
- 組み込み「All」デッキは約 9000 枚相当の仮想カードです。学習タブは未習得優先で出題します。
- 本アプリは教育・学習用途の個人プロジェクト想定です。商標・辞書コンテンツの権利は各権利者に帰属します。
