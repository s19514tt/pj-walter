# pj-walter 設計ドキュメント

スピフル（PROGRITの英語スピーキング練習アプリ）のFlutterクローン。**このドキュメントが実装の単一の真実源。** 実装時に矛盾や不足を見つけたら、このファイルを更新してからコードを書くこと。

## プロダクト概要

外国語スピーキング特化の学習アプリ。ユーザーは日本人学習者。UIは全て日本語。

学習対象言語は設定画面で切り替える:

| 言語 | デッキ | 想定レベル |
|---|---|---|
| 英語 | TOEIC700点台 / 800点台 | TOEIC 750 前後 |
| 中国語 | HSK3級 / HSK4級 | HSK 3〜4（累計 600〜1200語） |

**発音・声調は採点対象外。** 文法・語彙・語順のみを見る。音声認識を経た時点で発音の情報は失われており、
LLMに発音を評価させると根拠のない指摘（ハルシネーション）になるため、プロンプトで明示的に除外している。

例外として、**口頭中国語作文ドリルだけ**は文字起こし時に「聞こえたままの声調付きピンイン」を
併せて受け取り、模範解答のピンインとDart側で決定的に比較して、声調の食い違いを**スコアと無関係の
別カード「気づいた点」**として控えめに出す（「声調フィードバック」の節を参照）。LLMに声調の正誤を
判定させるのではなく、比較はすべてローカルで行う。独り言モードにはこの機能は無い。

### 学習言語の抽象化

言語で分岐する設定は `models/learning_language.dart` の `LanguageProfile` に集約する。
言語を増やすときは `LanguageProfile.values` に1件足し、教材アセットを置くだけで済むようにしてある。
`LanguageProfile` が持つもの: 言語コード / 表示名 / トレーニングの呼び名 / 教材アセットのディレクトリ /
デッキのレベル一覧 / 発音表記のラベル（中国語のみ「ピンイン」）/ 分かち書きする言語かどうか。

「分かち書きするか」は差分表示に効く。`utils/word_diff.dart` は空白分割ではなく
CJK文字を1文字1トークンとして切るため、中国語でも語レベルに近い差分が出る
（空白分割だと文全体が1トークンになり「全消し・全追加」になってしまう）。

教材データの作り方（特に中国語の語彙検証・ピンイン生成）は [tool/hsk/README.md](./tool/hsk/README.md) を参照。

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
- 音声認識: `record`（録音→Gemini音声認識）のみ。端末STT（speech_to_text）はPR17で廃止
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
    drill_result.dart       # 口頭英作文の1問の結果＋添削（中国語は声調の気づき toneNotes も持つ）
    tone_note.dart          # 声調の気づき1件（音節位置・期待/実測のピンインと声調番号）
    token_usage.dart        # Gemini APIのトークン使用量（usageMetadata由来）
    monologue_result.dart   # 独り言1回の結果＋添削
    srs_item.dart           # SRS復習アイテム
    phrase.dart             # フレーズ帳エントリ
  services/
    settings_service.dart   # 設定の読み書き（ChangeNotifier）
    gemini_service.dart     # Gemini REST クライアント（結果＋TokenUsageを返す）
    gemini_pricing.dart     # gemini-3.8-flash の単価とコスト計算
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
    settings_screen.dart    # APIキー/独り言デフォルト時間（モデル・音声認識方式は固定表示）
  widgets/                  # 共通ウィジェット（PrimaryButton, SecondaryButton, SectionHeader, AppCard, PillChip 等）
  utils/                    # 画面をまたいで使う小さなヘルパー
    review_launcher.dart    # 「今日の復習」開始処理の共通ロジック（ホーム/復習タブ両方から利用）
    score_colors.dart       # スコア(0-100)→表示色の変換
    theme_labels.dart       # テーマ識別子(daily/business/travel)→日本語表示名
    pinyin.dart             # ピンインの音節分割・声調抽出・声調差分（自前実装、外部パッケージ不使用）
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
- ヒーローカード用グラデーション: `AppColors.primaryGradient`（`#FF7A2E → #FF5B00`、左上→右下）。ストリークカードなどメリハリを出したい箇所に使用
- スコア系の薄背景: `scoreGoodSurface #E6F7EF` / `scoreMediumSurface #FEF3DC` / `scoreLowSurface #FDECEC`（バッジ・ハイライトカード背景。`scoreSurfaceColor(score)` で取得）
- `AppCard` は `color` 引数で背景色を上書きできる（薄色ハイライトカード用。既定は白）

### 新規共通ウィジェット（PR9）

- `widgets/score_ring.dart` の `ScoreRing`: 円形スコアゲージ。背景リング`#EEEEEE`＋値リング（scoreColor、丸端、太さ10）、中央にスコア数値（44px bold）＋「/100」。`TweenAnimationBuilder`で0→スコアへ800msイージングアニメーション（数値もカウントアップ）
- `widgets/stat_badge.dart` の `StatBadge`: ピル型バッジ。`scoreXxxSurface`背景＋濃色（scoreXxx）文字（例: 「合格 🎉」「要復習」）
- `widgets/bottom_cta_bar.dart` の `BottomCtaBar`: 画面下固定のCTAバー。白背景・上辺1px border・SafeArea内、左右16px/上下12pxパディング。`secondary`引数で上にテキストボタン等を追加可。スクロール本文側はこの分の下部余白を確保する
- `widgets/mic_button.dart` の `MicButton`: ドリル・独り言共通のマイク操作ボタン（直径88px既定）。未録音時はprimaryGradient背景＋オレンジ影（blur16、alpha 0.2）。録音中は外側に広がる半透明オレンジのパルスリングを1.2秒周期で繰り返しアニメーション（無限ループ。テストで`pumpAndSettle()`を使うと収束しないため、明示的に`pump(duration)`で扱う）
- `utils/app_route.dart` の `appRoute()`: 250msの軽いスライド（右から）＋フェードの`PageRouteBuilder`。主要な画面遷移で`MaterialPageRoute`の代わりに使用

### 口頭中国語作文の「気づいた点」カード（声調フィードバック）

`DrillFeedbackView` は `profile.readingLabel != null` かつ `sentence.reading != null` かつ
文字起こしの `reading` が模範解答と音節列で一致（ガード1）し、かつ指摘が1件以上あるときだけ、
採点完了（stage 2）で「気づいた点」カードを他のカードと同じフェードインで出す。それ以外は
カードごと非表示（「問題なし」の表示は無い）。

- 見出し: `Icons.hearing` ＋「気づいた点」。「声調チェック」「声調OK」といった語は使わない
- 補足文（textSecondary 12px）: 「音声認識が聞き取った声調（参考値）が模範解答のピンインと違っていた音節です。聞き取りの誤差も含まれます。」
- 1件1行: `[3声 → 4声]` のピル（`scoreLowSurface` 背景・`scoreLow` 文字）＋ 対象の漢字（音節数と漢字数が一致するときだけ）
  ＋ `shuǐ`（模範解答、textPrimary 太字）→ `shuì`（聞こえた音、scoreLow 太字）
- 英語モード（`readingLabel == null`）ではこのカードに関わる処理は一切走らない

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
| `settings` | 固定キー | 独り言デフォルト秒数など非秘匿設定（旧`modelName`/`sttMode`キーは起動時に削除） |
| `drill_results` | uuid | DrillResult（sentenceId, spoken, feedback一式, timestamp, toneNotes=声調の気づき。null は未判定＝英語・ピンイン無し・音節列不一致。既存データは null で読める） |
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
- モデルは `gemini-3.8-flash`（最新のFlash系）1本に固定（`GeminiService.modelName`）。設定画面からは変更不可
- 思考制御: Gemini 3系は `generationConfig.thinkingConfig.thinkingLevel` で制御（`thinkingBudget` は使わない）。文字起こし・添削は `low`
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

### トークン使用量とコスト

- 全ての呼び出しでレスポンスの `usageMetadata`（`promptTokenCount` / `candidatesTokenCount` / `thoughtsTokenCount`）を `TokenUsage` に読み取り、結果と一緒に返す（`correctComposition` → `CorrectionResult`、`transcribe` → `TranscriptionResult` など Dart の record）。`usageMetadata` が無ければゼロ扱い
- 課金上の出力トークン = 返答本文 + 思考（`billedOutputTokens`）
- 単価は `GeminiPricing`（`gemini-3.8-flash`、Standardティア、出典 https://ai.google.dev/gemini-api/docs/pricing 2026-09-03確認）
  - 2026-12-31まで: 入力 $0.75 / 出力 $3.75 per 1M tokens（導入価格）
  - 2027-01-01から: 入力 $1.50 / 出力 $7.50 per 1M tokens（標準価格）
  - 音声入力も入力単価をそのまま適用（このモデルでは音声の別単価なし）。コンテキストキャッシュ・Batchは未使用
- 口頭英作文の `DrillScreen` は問ごとに文字起こしと添削の `TokenUsage` を `DrillSummaryEntry.usage`（`DrillQuestionUsage`）に積み（「もう一度」のやり直し分も加算）、全問終了後の `DrillSummaryScreen` で
  - 「APIトークン使用量」カード: 文字起こし／添削／合計の入力・出力トークンとコスト（USD、小数4桁）、思考トークン数、適用単価
  - 問ごとの行: `入力 N · 出力 M · $X.XXXX`（使用量ゼロの問は非表示）
- 独り言英会話は使用量を受け取るが表示はまだしない
- Hive には保存しない（セッション内表示のみ）

### 音声文字起こし

`inline_data`（base64、mimeType は録音フォーマットに一致: wav推奨）＋指示「Transcribe this English speech verbatim. Return only the transcript.」。プレーンテキスト応答。録音は `record` パッケージで wav (16kHz mono)。

- 聞き取れる対象言語の発話が無い場合はマーカー `[NO_SPEECH]`（`GeminiService.noSpeechMarker`）を返すよう指示し、応答に含まれていれば「音声を聞き取れませんでした」の `GeminiException`。空文字を返させると下記の空応答と区別できないため
- 空応答（`"content": {}` で `parts` が無く `finishReason: STOP`、出力トークン0）は Gemini 3系Flash が稀に返す一時的な不調。`_requestText` で同じリクエストを最大3回まで送り直し、それでも空なら「文字起こし結果が返ってきませんでした」の `GeminiException`（添削の構造化出力も同じ再試行を通る）。使用量は再試行分も合算する

#### 中国語の文字起こし（声調付きピンイン併記）

`LanguageProfile.readingLabel != null`（＝中国語）のときだけ、文字起こしを構造化出力にして
漢字と一緒に「聞こえたままの声調付きピンイン」を受け取る。英語はプレーンテキストのまま一切変えない。

```json
{ "pinyin": "wǒ yào shuì",   // 聞こえたとおりの声調記号付きピンイン（音節ごとに半角スペース区切り）
  "hanzi": "我要睡" }         // 簡体字の書き起こし（聞き取れなければ [NO_SPEECH]）
```

- `responseSchema.propertyOrdering` を **`["pinyin", "hanzi"]` に固定**する。構造化出力は左から順に
  生成されるため、漢字を先に確定させるとピンインがその辞書引きになり実際の声調が消える
  （`tool/pinyin_poc` はこの順序で測定している）
- プロンプトで「ピンインは実際に聞こえた音をそのまま書く／語彙的に正しい声調に直さない／意味・文脈から
  声調を推測せずピッチだけを根拠にする／声調が判断できない音節は軽声（記号なし）」を明示する
- **この呼び出しに模範解答は渡さない**（渡すと確実にそれに引っ張られる）
- 無音・聞き取り不能の扱いは英語と同じ（`hanzi` に `[NO_SPEECH]` を返させ、含まれていれば
  「音声を聞き取れませんでした」の `GeminiException`。`hanzi` が空文字の場合も同様）
- 返り値は `TranscriptionResult.reading`（英語では常に null）。ピンインの解釈・比較は Dart 側で行う
- コスト増は1問あたり出力+50トークン程度

### 声調フィードバック（口頭中国語作文ドリルのみ）

**背景**: `tool/pinyin_poc`（ブランチ `claude/chinese-hanzi-pinyin-output-n0pzxe`）でTTS音声を使い
3声⇄4声の最小対8組を実測したところ、取り違え0件・聞き分け7/8組だった一方、対象外の音節への
誤指摘（嘘）が2箇所/56音節、音節ズレが4箇所あった。測定はTTSの明瞭な発音によるもので、学習者の
あいまいな発音では未検証（上限値）。**嘘をゼロと仮定して設計してはいけない**ため、下記の3つの
ガードは仕様として固定する。学習アプリでは「見逃し」より「嘘」（正しく発音できている箇所を誤りと
教える）のほうが有害。

**アルゴリズム**（`utils/pinyin.dart`、すべてDart側の決定的処理。Geminiに正誤判定を聞かない）:

1. `Sentence.reading`（模範解答。変調適用済み）と認識ピンインをそれぞれ音節に分割する
2. **声調記号を外した綴りの列**を比較し、完全一致しなければ打ち切って null（ガード1）
3. 一致した場合のみ音節ごとに声調番号を比較する
4. どちらかが軽声（記号なし＝tone 5）の音節はスキップする（ガード2）
5. 残った不一致だけを `ToneNote`（音節位置・期待/実測のピンイン・声調番号）として返す

音節分割の要件: 語ごとに連結された表記（`Qǐngwèn`）と音節スペース区切り（`qǐng wèn`）の両方／
声調記号つき母音→素の母音＋声調番号／記号なし＝軽声／j・q・x・yの後ろの ü は u と綴られるため
韻母表に `ue` を含める／儿化（`diǎnr`）の r を音節に取り込む／大文字小文字無視・句読点（全角含む）除去。

**ガード（妥協不可）**:

- **ガード1**: 音節列（綴り）が模範解答と一致しないときは声調について一切何も言わない。
  聞き取り失敗時の巻き添え誤指摘と、模範解答と違う言い回しをしたときの期待ピンイン算出
  （変調・多音字の解決）をまとめて回避する。v1は「模範解答どおりに言えたときだけ声調を見る」
- **ガード2**: 軽声がらみの差は絶対に報告しない（喜欢 xǐhuan / xǐhuān のように辞書・話者・TTSで揺れる）
- **ガード3**: UIで「声調をチェックした」と言わない。見出しは「気づいた点」。「声調OK」等の肯定的な
  断定を出さない。指摘0件のときはカードごと非表示（「問題なし」と出さない）。検出できた誤りだけを
  控えめに列挙する。指摘がない＝正しい、と誤解される見せ方をすると見逃した分がそのまま嘘になる

**スコアに声調を含めない。** `correctComposition()` の「発音・声調は評価対象に含めません」の行は
そのまま残す。声調は加点減点と無関係の別カード。

**やらないこと**: 独り言モードへの追加／変調・多音字の自前解決／声調のスコアリング／
発音評価専用API（SpeechSuper・Chivox等）の導入／`pinyin`・`lpinyin` 等の依存パッケージ追加。

## 音声入力の抽象化

`SpeechInputService`（抽象）の実装は `GeminiSpeechInputService` のみ:
- record の `startStream` でPCM16をメモリに蓄積 → 停止後に16kHz monoへ変換・WAV化して GeminiService.transcribe() → テキスト
- 返り値 `SpeechInputResult` は `text`・`usage` に加えて `reading`（中国語の声調付きピンイン。英語では null）を透過する
- 録音中は `onPartial` に「聞き取り中…」の固定文言、`onLevel` に正規化した入力音量を流す
- 権限拒否・録音失敗時は日本語エラーメッセージ（`SpeechInputException`）を返し、画面側は録り直しの導線を用意する
- 端末STT（speech_to_text）はPR17で廃止（設定項目も削除）

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
