# pj-walter 設計ドキュメント

スピフル（PROGRITの英語スピーキング練習アプリ）のFlutterクローン。**このドキュメントが実装の単一の真実源。** 実装時に矛盾や不足を見つけたら、このファイルを更新してからコードを書くこと。

## プロダクト概要

英語スピーキング特化の学習アプリ。ユーザーは TOEIC 750 前後の日本人。UIは全て日本語。

2つのトレーニング:
1. **口頭英作文**: 日本語文を見て制限時間内に英語で発話 → 音声認識で文字化 → Gemini が添削
2. **独り言英会話**: お題について 30秒/1分/2分/3分 スピーキング → 文字起こし → Gemini がフィードバック

補助機能: SRS復習、フレーズ帳、学習記録（ストリーク・カレンダー・グラフ）、設定（Gemini APIキー等）。

## 技術スタック

- Flutter (stable 3.44) / Dart 3。対応: Android / iOS / Web（検証は analyze・test・web build）
- 状態管理: `provider` + `ChangeNotifier`（Riverpod/BLoC は使わない）
- ルーティング: 素の `Navigator`（go_router は使わない）
- ローカルDB: `hive` / `hive_flutter`（コード生成なし、`Box<Map>` 相当で Map を格納）
- APIキー保存: `flutter_secure_storage`
- 音声認識: `speech_to_text`（端末STT） / `record`（録音→Gemini音声認識）
- HTTP: `http`
- グラフ: `fl_chart`
- その他: `intl`, `uuid`

## ディレクトリ構成

```
lib/
  main.dart                 # Hive初期化、Provider登録、MaterialApp
  theme/app_theme.dart      # テーマ定義（色・タイポ・コンポーネントテーマを全て集約）
  models/                   # 純Dartモデル（fromJson/toJson を持つ）
    sentence.dart           # 教材文
    topic.dart              # 独り言のお題
    drill_result.dart       # 口頭英作文の1問の結果＋添削
    monologue_result.dart   # 独り言1回の結果＋添削
    srs_item.dart           # SRS復習アイテム
    phrase.dart             # フレーズ帳エントリ
  services/
    settings_service.dart   # 設定の読み書き（ChangeNotifier）
    gemini_service.dart     # Gemini REST クライアント
    speech_input_service.dart # STT/録音の抽象化
    sentence_repository.dart  # 教材JSONのロード・フィルタ
    history_service.dart    # 履歴・SRS・フレーズ帳・日次統計の永続化（ChangeNotifier）
    drill_question_selector.dart  # 口頭英作文の出題選定ロジック
    review_question_resolver.dart # SRSアイテム→出題文の解決
  screens/
    home_screen.dart        # ダッシュボード（ストリーク/今日の復習/開始ボタン、設定への導線）
    shell.dart              # BottomNavigationBar のシェル（ホーム/学習/復習/記録の4タブ。設定はホームからpush）
    training_menu_screen.dart # 学習タブ（口頭英作文/独り言英会話への導線）
    composition/            # 口頭英作文（デッキ選択→ドリル→添削表示→まとめ）
      deck_select_screen.dart
      sentence_list_screen.dart
      drill_screen.dart
      drill_feedback_view.dart
      drill_summary_screen.dart
    monologue/              # 独り言英会話（お題選択→スピーキング→フィードバック）
      topic_select_screen.dart
      monologue_speak_screen.dart
      monologue_feedback_screen.dart
    review_screen.dart      # 復習タブ（今日の復習＋フレーズ帳）
    stats_screen.dart       # 記録タブ
    stats/                   # 記録タブの構成パーツ
      streak_summary.dart
      weekly_chart.dart
      study_calendar.dart
      history_section.dart
    settings_screen.dart    # APIキー/モデル/音声認識方式/独り言デフォルト時間
  widgets/                  # 共通ウィジェット（PrimaryButton, SecondaryButton, SectionHeader, AppCard, PillChip 等）
  utils/                    # 画面をまたいで使う小さなヘルパー
    review_launcher.dart    # 「今日の復習」開始処理の共通ロジック（ホーム/復習タブ両方から利用）
    score_colors.dart       # スコア(0-100)→表示色の変換
    theme_labels.dart       # テーマ識別子(daily/business/travel)→日本語表示名
assets/data/
  sentences_700.json        # TOEIC700点台 200文
  sentences_800.json        # TOEIC800点台 200文
  topics.json               # 独り言のお題
```

## デザインシステム（Klook風）

参考: Klookアプリ。白基調＋オレンジ、丸みの強いUI、余白多め。**色・スタイルは必ず `app_theme.dart` の定数経由で使う（画面コードに生の Color を書かない）。**

- Primary: `#FF5B00`（オレンジ）/ pressed `#E64F00` / 薄背景 `#FFF3EC`
- テキスト: 主 `#212121`、副 `#757575`
- 背景: 白 `#FFFFFF`、セクション区切り・ページ背景 `#F5F6F8`
- 成功/正解: `#0BA05F`、エラー/要復習: `#D32F2F`、スコア良 `#0BA05F`・中 `#F5A623`・低 `#D32F2F`
- カード: 白、radius 16、border `#EEEEEE` 1px（影は使っても極薄）
- CTAボタン: 全幅、高さ52、radius 14、オレンジ塗り＋白太字。セカンダリはオレンジ枠線＋白地
- チップ（テーマ/レベル選択）: ピル型（radius 999）、選択時オレンジ薄背景＋オレンジ枠＋オレンジ文字、非選択はグレー枠
- セクション見出し: 左にオレンジ縦バー（幅4×高さ18、radius 2）＋太字18px
- AppBar: 白背景、黒文字、elevation 0
- BottomNav: 白、選択オレンジ・非選択グレー

## データモデル

### 教材 (assets/data/sentences_*.json)

```json
{ "level": 700,
  "sentences": [
    { "id": "s700-001", "ja": "この件については後ほど折り返しご連絡します。",
      "en": "I'll get back to you on this matter later.",
      "theme": "business",            // "daily" | "business" | "travel"
      "tips": "get back to A on B で「BについてAに折り返す」" }
  ] }
```

`id` は `s{level}-{連番3桁}`。約数十文ごとの「ユニット」には分けず、テーマ×レベルでフィルタして出題。

### 独り言お題 (assets/data/topics.json)

```json
{ "topics": [ { "id": "t-001", "ja": "今日の朝ごはんについて話してください", "en": "Talk about what you had for breakfast today", "theme": "daily" } ] }
```

50題以上。theme は教材と同じ3分類。

### Hive ボックス（全て Map を格納、モデルの toJson/fromJson で変換）

| box名 | キー | 内容 |
|---|---|---|
| `settings` | 固定キー | モデル名、STT方式(`device`/`gemini`)、独り言デフォルト秒数など非秘匿設定 |
| `drill_results` | uuid | DrillResult（sentenceId, spoken, feedback一式, timestamp） |
| `monologue_results` | uuid | MonologueResult（topicId, seconds, transcript, feedback一式, timestamp） |
| `srs_items` | sentenceId | SrsItem（stage, dueDate, lapses, lastResult） |
| `phrases` | uuid | Phrase（en, ja, source, createdAt） |
| `daily_stats` | `YYYY-MM-DD` | その日の学習量（drillCount, monologueCount, studySeconds） |

APIキーだけは `flutter_secure_storage`（キー名 `gemini_api_key`）。

### SRS アルゴリズム

- 間隔: stage 0→翌日, 1→3日後, 2→7日後, 3→14日後, 4→30日後, 5=卒業（キューから除外）
- ドリルで不正解（スコア < 70）→ srs_items に stage 0 で登録（既存なら stage 0 に戻し lapses+1）
- 復習で正解（スコア ≥ 70）→ stage+1、dueDate 更新
- 「今日の復習」= `dueDate <= 今日` のアイテム。日付は日単位で比較（時刻無視）

## Gemini API 契約

- エンドポイント: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- 認証: HTTPヘッダー `x-goog-api-key: {apiKey}`（URLクエリに入れない）
- デフォルトモデル `gemini-2.5-flash`。設定画面で任意文字列に変更可（候補チップ: gemini-2.5-flash / gemini-2.5-pro / gemini-2.0-flash）
- 構造化出力: `generationConfig.responseMimeType = "application/json"` ＋ `responseSchema` を必ず指定し、返答をモデルの fromJson でパース
- エラー処理: 非200・パース失敗・タイムアウト(30s)は `GeminiException(message日本語)` を投げ、UI側でスナックバー＋リトライボタン表示。APIキー未設定なら添削ボタン押下時に設定画面へ誘導するダイアログ

### 口頭英作文の添削（テキスト）

入力: 日本語原文、模範解答、ユーザー発話（文字起こし）。出力スキーマ:

```json
{ "score": 85,                      // 0-100 伝わりやすさ＋正確さ
  "is_acceptable": true,            // score>=70 相当の合否
  "corrected": "発話を最小修正した英文",
  "explanation_ja": "誤りの解説（日本語、2-3文）",
  "comparison_ja": "模範解答との違い・どちらでも良い点の解説（日本語）" }
```

プロンプト方針: 「あなたは日本人向け英語講師。発話は音声認識由来なので大文字小文字・句読点は減点しない。意味が通り文法的に正しければ模範解答と違っても許容」。

### 独り言英会話のフィードバック

入力: お題、発話時間、トランスクリプト。出力スキーマ:

```json
{ "fluency_score": 72,
  "corrected_transcript": "全文を自然な英語に直したもの",
  "corrections": [ { "original": "...", "corrected": "...", "reason_ja": "..." } ],
  "useful_phrases": [ { "en": "It slipped my mind.", "ja": "うっかり忘れていた" } ],  // 3-5個、次回使える表現
  "overall_feedback_ja": "良かった点＋改善点（日本語、3-4文）" }
```

### 音声文字起こし（STT方式=gemini のとき）

`inline_data`（base64、mimeType は録音フォーマットに一致: wav推奨）＋指示「Transcribe this English speech verbatim. Return only the transcript.」。プレーンテキスト応答。録音は `record` パッケージで wav (16kHz mono)。

## 音声入力の抽象化

`SpeechInputService` が2モードを隠蔽:
- `device`: speech_to_text。リアルタイムに認識テキストを流す（partial表示）
- `gemini`: record で録音 → 停止後に GeminiService.transcribe() → テキスト
- 権限拒否・STT利用不可時は日本語エラーメッセージを返し、**手入力フォールバック**（TextFieldで回答入力）を必ず用意

## コーディング規約

- `flutter analyze` 警告ゼロ、`dart format` 適用、flutter_lints デフォルト準拠
- UI文言は日本語ハードコード（i18n しない）。コメントも日本語可
- 1ファイル400行を目安に分割。ウィジェットの深いネストはメソッド/クラス抽出
- モデルは immutable（final フィールド＋fromJson/toJson）
- 新規依存パッケージの追加は原則しない（必要なら PR 説明に理由を書く）

## Git / PR ワークフロー

- ブランチ名 `feature/pr{N}-{slug}`、mainから分岐。PRは `gh pr create`
- 実装エージェントは: 実装 → `flutter analyze`（警告0）→ `flutter test` パス → commit/push → PR作成まで。**マージはしない**（レビュー担当がマージ）
- コミットは論理単位で分割。メッセージは英語1行要約＋必要なら本文
- `flutter` コマンドは `export PATH="$HOME/flutter/bin:$PATH"` で使う
