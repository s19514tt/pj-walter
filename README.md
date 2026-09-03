# pj-walter

スピフル（PROGRIT）風の英語スピーキング練習アプリ。日本人学習者（TOEIC 750前後を想定）向けに、日本語UIで2種類のスピーキングトレーニングと、SRS復習・フレーズ帳・学習記録をまとめて提供する Flutter アプリです。

## 概要

- **口頭英作文**: 日本語文を見て制限時間内に英語で発話 → 音声認識で文字起こし → Gemini が採点・添削
- **独り言英会話**: お題について 30秒/1分/2分/3分 スピーキング → 文字起こし → Gemini が流暢さ・修正・使えるフレーズをフィードバック
- **SRS復習**: 口頭英作文で不正解だった文を間隔反復（1日→3日→7日→14日→30日→卒業）で自動的に再出題
- **フレーズ帳**: 独り言のフィードバックで出てきた表現をワンタップで保存・検索・削除
- **学習記録**: 学習ストリーク、週間グラフ、学習カレンダー、履歴一覧

詳しい仕様・データモデル・API契約は [DESIGN.md](./DESIGN.md) を参照してください。

## 機能一覧（画面ごと）

| 画面 | 内容 |
|---|---|
| ホーム | 今日の学習ストリーク、今日の復習件数、各トレーニングへのショートカット、設定への導線 |
| 学習 | 「口頭英作文」「独り言英会話」トレーニングメニュー |
| 口頭英作文 | テーマ（日常/ビジネス/旅行）×レベル（700/800）でデッキ選択 → 出題一覧 → 発話＆採点 → 添削表示 → まとめ画面 |
| 独り言英会話 | お題選択 → 制限時間スピーキング → 文字起こし → 流暢さスコア・修正・使えるフレーズのフィードバック |
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

## 設定項目

| 項目 | 説明 |
|---|---|
| Gemini APIキー | 上記の手順で取得したキー。未入力の場合は添削・音声文字起こしが利用できません |
| モデル・音声認識（表示のみ） | 使用モデルは `gemini-3.8-flash` に固定。音声認識は録音をGeminiに送信して文字起こしする方式のみ（端末の音声認識は廃止） |
| 独り言のデフォルト時間 | 独り言英会話のスピーキング時間（30秒/1分/2分/3分）の初期選択値 |

## アーキテクチャ概略

詳細は [DESIGN.md](./DESIGN.md) を参照してください。要点のみ:

- 状態管理: `provider` + `ChangeNotifier`（Riverpod/BLoCは不使用）
- ルーティング: 素の `Navigator`（`go_router` は不使用）
- ローカルDB: `hive` / `hive_flutter`（学習履歴・SRS・フレーズ帳・設定・日次統計）
- APIキー保存: `flutter_secure_storage`
- 音声入力: `record` で録音（PCM16）→ 16kHz mono に変換 → WAV化 → Gemini文字起こし。`SpeechInputService` で抽象化（テストではフェイクに差し替え）
- Gemini通信: `http` でREST APIを直接呼び出し（構造化出力はJSON Schemaで固定）
- グラフ: `fl_chart`

### ディレクトリ構成

```
lib/
  main.dart          # Hive初期化、Provider登録、MaterialApp
  theme/              # デザインシステム（色・タイポ・コンポーネントテーマ）
  models/             # 純Dartモデル（fromJson/toJson）
  services/           # 設定・Gemini通信・音声入力・教材ロード・履歴永続化などのロジック
  screens/            # 画面（composition/, monologue/, stats/ にサブ画面をまとめて配置）
  widgets/            # 共通UIパーツ
  utils/              # 画面をまたぐ小さなヘルパー
assets/data/          # 教材文（TOEIC700/800）・独り言お題のJSON
test/                 # ウィジェットテスト・ユニットテスト
```

## 開発コマンド

```bash
export PATH="$HOME/flutter/bin:$PATH"

flutter pub get        # 依存パッケージ取得
flutter analyze         # 静的解析（警告0を維持）
flutter test             # 全テスト実行
dart format lib test      # フォーマット
flutter build web         # Webビルド確認
```
