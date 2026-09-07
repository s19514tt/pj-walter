# pj-walter

スピフル（PROGRIT）風のスピーキング練習アプリ。日本人学習者向けに、日本語UIで2種類のスピーキングトレーニングと、SRS復習・フレーズ帳・学習記録をまとめて提供する Flutter アプリです。

**英語と中国語に対応**しています。設定画面で学習する言語を切り替えると、教材・採点プロンプト・文字起こしの言語指定がまとめて切り替わります。

| 学習言語 | デッキ | 教材 |
|---|---|---|
| 英語 | TOEIC700点台 / TOEIC800点台 | 各200文 |
| 中国語 | HSK3級 / HSK4級 | 各300文（ピンイン付き） |

採点対象は**文法・語彙・語順のみ**です。発音・声調は評価しません（音声認識を経た時点で発音の情報が失われており、LLMに評価させても根拠のない指摘になるため）。

## 概要

- **口頭作文**（口頭英作文 / 口頭中国語作文）: 日本語文を見て制限時間内に学習言語で発話 → 音声認識で文字起こし → Gemini が採点・添削
- **独り言**（独り言英会話 / 独り言中国語）: お題について 30秒/1分/2分/3分 スピーキング → 文字起こし → Gemini が流暢さ・修正・使えるフレーズをフィードバック
- **SRS復習**: 口頭作文で不正解だった文を間隔反復（1日→3日→7日→14日→30日→卒業）で自動的に再出題
- **フレーズ帳**: 独り言のフィードバックで出てきた表現をワンタップで保存・検索・削除
- **学習記録**: 学習ストリーク、週間グラフ、学習カレンダー、履歴一覧

詳しい仕様・データモデル・API契約は [DESIGN.md](./DESIGN.md) を参照してください。

## 機能一覧（画面ごと）

| 画面 | 内容 |
|---|---|
| ホーム | 今日の学習ストリーク、今日の復習件数、各トレーニングへのショートカット、設定への導線 |
| 学習 | 口頭作文・独り言のトレーニングメニュー |
| 口頭作文 | テーマ（日常/ビジネス/旅行）×レベル（英語 700/800、中国語 HSK3/4）でデッキ選択 → 出題一覧 → 発話＆採点 → 添削表示（問題文・修正版/模範解答の読み上げ付き） → まとめ画面（平均スコア、問ごとの結果、APIトークン使用量と概算コスト） |
| 独り言 | お題選択 → 制限時間スピーキング → 文字起こし → 流暢さスコア・修正・使えるフレーズのフィードバック |
| 復習 | 「今日の復習」（SRSキュー）の一括開始、フレーズ帳の一覧・検索・削除 |
| 記録 | ストリーク、週間学習量グラフ、学習カレンダー、ドリル/独り言の履歴一覧 |
| 設定 | Gemini APIキーの登録・削除、独り言のデフォルト時間。使用モデル（`gemini-3.8-flash`）と音声認識方式（録音→Gemini文字起こし）は固定 |

## セットアップ

### 必要環境

- Flutter SDK: stable 3.44 系（Dart ^3.12.2）
- Android Studio / Xcode（実機・エミュレータで動かす場合）

### 手順

```bash
git clone <このリポジトリ>
cd pj-walter
flutter pub get
flutter run
```

### プラットフォームごとの注意点

- **Android / iOS**: マイク権限が必要です（Android: `RECORD_AUDIO`、iOS: `NSMicrophoneUsageDescription`。マニフェストには設定済みですが、初回起動時にOSの権限ダイアログが表示されるので許可してください）。
- **Web**: `flutter run -d chrome` で動作します。音声認識はファイルI/Oを使わずメモリ上で録音データを扱うため、ブラウザでもそのまま動きます（ブラウザが実際に採用したサンプルレート・チャンネル数は録音開始時に受け取り、送信前に16kHzモノラルへ変換しています）。マイク使用にはHTTPSまたはlocalhostが必要です。ビルド確認は `flutter build web` で通ることを確認しています。

## Gemini APIキーの取得・設定

1. [Google AI Studio](https://aistudio.google.com/) にアクセスし、Googleアカウントでログインします。
2. 「Get API key」からAPIキーを新規作成します。
3. アプリを起動し、ホーム画面右上の設定アイコンから設定画面を開きます。
4. 「Gemini APIキー」欄に取得したキーを貼り付けて保存します。

保存したAPIキーは端末の secure storage（`flutter_secure_storage`）に暗号化して保存され、Gemini APIへのリクエスト以外の目的で外部に送信されることはありません。キーは設定画面からいつでも削除できます。

APIキーが未設定の状態で添削・フィードバックを利用しようとすると、設定画面へ誘導するダイアログが表示されます。音声入力（録音→Gemini文字起こし）もAPIキーを消費します。

口頭英作文のまとめ画面では、そのセッション（10問）で消費したトークン数（文字起こし／添削／合計）と、`gemini-3.8-flash` の公開単価から算出した概算コスト（USD）を表示します。単価は [Gemini API の料金ページ](https://ai.google.dev/gemini-api/docs/pricing) に基づき、2026年12月31日までは導入価格（入力 $0.75 / 出力 $3.75 per 1M tokens）、2027年1月1日以降は標準価格（入力 $1.50 / 出力 $7.50）が自動で適用されます。無料枠は考慮していません。

## 設定項目

| 項目 | 説明 |
|---|---|
| Gemini APIキー | 上記の手順で取得したキー。未入力の場合は添削・音声文字起こしが利用できません |
| モデル・音声認識（表示のみ） | 使用モデルは `gemini-3.8-flash` に固定。音声認識は録音をGeminiに送信して文字起こしする方式のみ（端末の音声認識は廃止） |
| 独り言のデフォルト時間 | 独り言英会話のスピーキング時間（30秒/1分/2分/3分）の初期選択値 |

## アーキテクチャ概略

詳細は [DESIGN.md](./DESIGN.md) の「アーキテクチャ」、今後の計画は [docs/ROADMAP.md](./docs/ROADMAP.md) を参照してください。要点のみ:

- 構成: feature-first のクリーンアーキテクチャ（`lib/core/` + `lib/features/<機能>/{domain,data,presentation}`）
- 状態管理: `signals`（`signals_flutter`）。画面ごとの Store が signal / computed を持ち、UI は `SignalBuilder` で購読（`provider` は不使用）
- DI: `get_it` によるコンポジションルート（`lib/core/di/`）。Store へはコンストラクタ注入。UI・Store から get_it は参照しない
- モデル: `freezed` + `json_serializable`。外部 I/O 用の DTO（Hive / Gemini）と domain の Entity を分離
- i18n: `flutter_localizations` + ARB（`lib/core/l10n/app_ja.arb`）。UI 文言はすべて ARB 経由（現在は ja のみ）
- ルーティング: 素の `Navigator`（`go_router` は不使用）
- ローカルDB: `hive` / `hive_flutter`（学習履歴・SRS・フレーズ帳・設定・日次統計）
- APIキー保存: `flutter_secure_storage`
- 音声入力: `record` で録音（PCM16）→ 16kHz mono に変換 → WAV化 → `TranscriptionRepository` で文字起こし。`SpeechInputService` で抽象化（テストではフェイクに差し替え）
- 外部 I/O は `CorrectionRepository` / `MonologueReviewRepository` / `TranscriptionRepository` / `TtsRepository` / `ContentRepository` のインタフェースに閉じ込め、現在は Gemini REST 直叩き（構造化出力はJSON Schemaで固定）とアセット読み込みで実装。次フェーズでここがバックエンド呼び出しに差し替わる
- グラフ: `fl_chart`

### ディレクトリ構成

```
lib/
  main.dart           # Hive初期化 → configureDependencies() → runApp
  app.dart            # MaterialApp（テーマ・ローカライズ・AppScope）
  core/
    di/               # コンポジションルート（get_it）、StoreFactory / AppScope
    state/            # Store 基底クラス（signals のライフサイクル管理）
    l10n/             # ARB と gen-l10n の生成物
    language/         # LearningLanguage / LanguageProfile / LanguageSupport
    domain/           # TokenUsage, GeminiPricing, AppFailure
    data/             # GeminiClient（共通トランスポート）
    theme/            # デザインシステム（色・タイポ・コンポーネントテーマ）
    widgets/          # 共通UIパーツ
    utils/            # 画面をまたぐ小さなヘルパー
  features/
    settings/         # 学習言語・独り言デフォルト時間・APIキー
    content/          # 教材・お題（アセット読み込み）
    speech/           # 文字起こし・読み上げ・録音／再生の抽象化
    composition/      # 口頭作文（デッキ選択→ドリル→添削表示→まとめ）
    monologue/        # 独り言（お題選択→スピーキング→フィードバック）
    review/           # SRS復習・フレーズ帳
    stats/            # 日次統計・記録タブ
    home/             # シェル・ホーム・学習メニュー
    （各 feature は domain/ data/ presentation/ と <feature>_module.dart を持つ）
assets/data/en/       # 英語教材（TOEIC700/800）・独り言お題のJSON
assets/data/zh/       # 中国語教材（HSK3/4）・独り言お題のJSON
docs/ROADMAP.md       # フェーズ計画
tool/hsk/             # 中国語教材のHSK語彙検証・ピンイン生成スクリプト
test/                 # ウィジェットテスト・ユニットテスト・Store のユニットテスト・ゴールデン
widgetbook/           # UIの状態一覧（Widgetbook）
```

## 開発コマンド

```bash
export PATH="$HOME/flutter/bin:$PATH"

flutter pub get        # 依存パッケージ取得
dart run build_runner build --delete-conflicting-outputs  # freezed / json_serializable の生成（モデルを変えたとき）
flutter gen-l10n         # ARB からローカライズクラスを生成（app_ja.arb を変えたとき）
flutter analyze         # 静的解析（警告0を維持）
flutter test             # 全テスト実行
dart format lib test      # フォーマット
flutter build web         # Webビルド確認

# UIの状態一覧をブラウザで確認（Widgetbook = Flutter版Storybook）
flutter run -d chrome -t widgetbook/main.dart
# 見た目を意図して変えたときだけゴールデン画像を更新（CIと同じLinuxで実行すること）
flutter test --update-goldens test/goldens
```

UIの状態（例: 添削画面で声調の気づきが1件ある／儿化がある／採点待ち）は `widgetbook/fixtures/` に
まとめてあり、Widgetbook での目視と `test/goldens/` のゴールデンテスト（CIでの崩れ検出）の両方が
同じ一覧を使います。新しい状態を足すときは fixtures に1件追加するだけです。

Widgetbook は GitHub Pages にも配信されます（`.github/workflows/widgetbook-pages.yml`）。
`main` への push で自動更新、Actions の「Widgetbook (GitHub Pages)」→「Run workflow」で任意のブランチから
手動デプロイもできます。初回だけ Settings → Pages → Source を「GitHub Actions」にしてください。
公開URLは `https://<owner>.github.io/pj-walter/` です。

## 中国語教材について

`assets/data/zh/` の教材は、**HSKの公式語彙リストに対して機械的に検証**しています。
文を勘で書かず、「その級の学習者が話せるようになるべきこと」から選んだうえで、
使う語彙が級の外に出ていないことを `tool/hsk/verify_vocabulary.py` で確認しています。
ピンイン（`reading`）も手書きではなく `tool/hsk/generate_reading.py` で生成しています。

許容語彙の定義・検証手順は [tool/hsk/README.md](./tool/hsk/README.md) を参照してください。
教材を追加・修正したら必ず検証スクリプトを通してください。
