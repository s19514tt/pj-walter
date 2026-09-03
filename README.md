# pj-walter

スピフル（PROGRIT）風のスピーキング練習アプリ。日本人学習者向けに、日本語UIで2種類のスピーキングトレーニングと、SRS復習・フレーズ帳・学習記録をまとめて提供する Flutter アプリです。

**英語と中国語に対応**しています。設定画面で学習する言語を切り替えると、教材・採点プロンプト・音声認識のロケールがまとめて切り替わります。

| 学習言語 | デッキ | 教材 |
|---|---|---|
| 英語 | TOEIC700点台 / TOEIC800点台 | 各200文 |
| 中国語 | HSK3級 / HSK4級 | 各300文（ピンイン付き） |

## 概要

- **口頭作文**（口頭英作文 / 口頭中作文）: 日本語文を見て制限時間内に学習言語で発話 → 音声認識で文字起こし → Gemini が採点・添削
- **独り言**（独り言英会話 / 独り言中国語会話）: お題について 30秒/1分/2分/3分 スピーキング → 文字起こし → Gemini が流暢さ・修正・使えるフレーズをフィードバック
- **SRS復習**: 口頭作文で不正解だった文を間隔反復（1日→3日→7日→14日→30日→卒業）で自動的に再出題
- **フレーズ帳**: 独り言のフィードバックで出てきた表現をワンタップで保存・検索・削除
- **学習記録**: 学習ストリーク、週間グラフ、学習カレンダー、履歴一覧

採点対象は**文法・語彙・語順のみ**です。発音・声調は評価しません（音声認識を経た時点で発音の情報が失われており、LLMに評価させても根拠のない指摘になるため）。

詳しい仕様・データモデル・API契約は [DESIGN.md](./DESIGN.md) を参照してください。

## 機能一覧（画面ごと）

| 画面 | 内容 |
|---|---|
| ホーム | 今日の学習ストリーク、今日の復習件数、各トレーニングへのショートカット、設定への導線 |
| 学習 | 口頭作文・独り言のトレーニングメニュー |
| 口頭作文 | テーマ（日常/ビジネス/旅行）×レベル（英語 700/800、中国語 HSK3/4）でデッキ選択 → 出題一覧 → 発話＆採点 → 添削表示 → まとめ画面 |
| 独り言 | お題選択 → 制限時間スピーキング → 文字起こし → 流暢さスコア・修正・使えるフレーズのフィードバック |
| 復習 | 「今日の復習」（SRSキュー）の一括開始、フレーズ帳の一覧・検索・削除 |
| 記録 | ストリーク、週間学習量グラフ、学習カレンダー、ドリル/独り言の履歴一覧 |
| 設定 | 学習言語（英語/中国語）、Gemini APIキーの登録・削除、モデル名、音声認識方式（端末/Gemini）、独り言のデフォルト時間 |

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

- **Android / iOS**: マイク権限が必要です（Android: `RECORD_AUDIO`、iOS: `NSMicrophoneUsageDescription`。マニフェストには設定済みですが、初回起動時にOSの権限ダイアログが表示されるので許可してください）。権限を拒否した場合や音声認識が使えない端末でも、テキスト入力欄への手入力でトレーニングを続行できます。
- **Web**: `flutter run -d chrome` で動作しますが、設定画面の音声認識方式を **「Gemini音声認識」にすると録音データの一時ファイルI/O（`dart:io` の `File` / `path_provider`）がブラウザ環境で正しく動作しない可能性があります**。Webで試す場合は「端末の音声認識」（ブラウザのWeb Speech API相当）を選んでください。ビルド確認は `flutter build web` で通ることを確認しています。

## Gemini APIキーの取得・設定

1. [Google AI Studio](https://aistudio.google.com/) にアクセスし、Googleアカウントでログインします。
2. 「Get API key」からAPIキーを新規作成します。
3. アプリを起動し、ホーム画面右上の設定アイコンから設定画面を開きます。
4. 「Gemini APIキー」欄に取得したキーを貼り付けて保存します。

保存したAPIキーは端末の secure storage（`flutter_secure_storage`）に暗号化して保存され、Gemini APIへのリクエスト以外の目的で外部に送信されることはありません。キーは設定画面からいつでも削除できます。

APIキーが未設定の状態で添削・フィードバックを利用しようとすると、設定画面へ誘導するダイアログが表示されます。

## 設定項目

| 項目 | 説明 |
|---|---|
| 学習する言語 | 英語（TOEIC 700/800）または中国語（HSK 3/4）。教材・採点プロンプト・音声認識のロケールが一括で切り替わります |
| Gemini APIキー | 上記の手順で取得したキー。未入力の場合は添削・音声文字起こし（Gemini方式）が利用できません |
| モデル名 | Gemini APIに渡すモデル名。候補（`gemini-2.5-flash` / `gemini-2.5-pro` / `gemini-2.0-flash`）から選ぶか直接入力できます。デフォルトは `gemini-2.5-flash` |
| 音声認識方式 | 「端末の音声認識」（`speech_to_text`、無料・高速）または「Gemini音声認識」（録音をGeminiに送信、高精度だがAPIキーを消費）を切り替えられます |
| 独り言のデフォルト時間 | 独り言英会話のスピーキング時間（30秒/1分/2分/3分）の初期選択値 |

## アーキテクチャ概略

詳細は [DESIGN.md](./DESIGN.md) を参照してください。要点のみ:

- 状態管理: `provider` + `ChangeNotifier`（Riverpod/BLoCは不使用）
- ルーティング: 素の `Navigator`（`go_router` は不使用）
- ローカルDB: `hive` / `hive_flutter`（学習履歴・SRS・フレーズ帳・設定・日次統計）
- APIキー保存: `flutter_secure_storage`
- 音声入力: `speech_to_text`（端末STT） / `record`（録音→Gemini音声認識）を `SpeechInputService` で抽象化
- 学習言語: `LanguageProfile`（`lib/models/learning_language.dart`）が言語ごとの差分（教材の場所・音声認識ロケール・画面の呼び名・差分表示のトークン化）を一手に持つ
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
assets/data/en/       # 英語教材（TOEIC700/800）・独り言お題のJSON
assets/data/zh/       # 中国語教材（HSK3/4）・独り言お題のJSON
tool/hsk/             # 中国語教材のHSK語彙検証・ピンイン生成スクリプト
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

## 中国語教材について

`assets/data/zh/` の教材は、**HSKの公式語彙リストに対して機械的に検証**しています。
文を勘で書かず、「その級の学習者が話せるようになるべきこと」から選んだうえで、
使う語彙が級の外に出ていないことを `tool/hsk/verify_vocabulary.py` で確認しています。
ピンイン（`reading`）も手書きではなく `tool/hsk/generate_reading.py` で生成しています。

許容語彙の定義・検証手順は [tool/hsk/README.md](./tool/hsk/README.md) を参照してください。
教材を追加・修正したら必ず検証スクリプトを通してください。
