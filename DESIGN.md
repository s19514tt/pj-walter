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
差分の**比較**は1文字ずつのままで、**表示**だけ `groupDiffSegments()` で単語ごとの
まとまり（ハイライトの箱1つ分）にする。語の切れ目は添削応答が返す語区切りから取り、
無ければ連続する差分をひとまとまりにする（1文字ずつ色が付くのを防ぐ）。

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
- 読み上げ: Gemini TTS（`gemini-3.1-flash-tts-preview`）で音声生成し、`audioplayers` で再生
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
    tts_service.dart        # 読み上げ（TTS）の抽象化
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
  widgets/                  # 共通ウィジェット（PrimaryButton, SecondaryButton, SectionHeader, AppCard, PillChip, SpeakButton 等）
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

### スピーキング画面のカウントダウンリング

`widgets/countdown_ring.dart` の `CountdownRing`（口頭英作文のドリル・独り言スピーキング共通）:

- 200×200のボックスに半径`size * 0.45`（＝直径180）・線幅8のリング。トラックは`#EDEEF1`固定
- 12時起点で**時計回りに消費**（先端を12時に固定し、空きを時計回りに広げる）。
  1秒刻みの更新は`TweenAnimationBuilder`のlinear補間で滑らかにする
- 弧・数値の色は pre=`#B9BDC4` / rec=primary / 残りわずか（urgent）=`scoreLow`。
  状態ドットとラベルは pre=グレー＋「聞き取り前」、rec=赤＋「聞き取り中」
- **聞き取りを開始した瞬間に、リング全体が一度弾む**（デザインの`ringPop`）:
  620msで 1.0 →（38%地点）1.11 → 1.08 と進み、聞き取り中は1.08倍のまま保持する。
  preへ戻すと等倍に戻る。線幅・半径は変えない（音量に反応させて太らせるのは廃止した。
  デザインに無いうえ、リングが常に脈打っていると残り時間が読み取りづらいため）

### わからないので飛ばす（口頭英作文のドリルのみ）

答えが浮かばないまま制限時間を眺め続けずに模範解答へ進める逃げ道。独り言英会話には無い。

- ドリル画面のリング下に「わからないので飛ばす」を下線付きテキストリンクで置く
  （主ボタン「答える／採点する」より弱く見せる）。pre・rec のどちらでも押せる
- 押すと `widgets/skip_question_dialog.dart` の `confirmSkipQuestion()` で必ず確認する
  （「この問題を飛ばしますか？」／続ける・飛ばす）。誤タップで学習機会を失わせない
- 「飛ばす」を選ぶと、録音中なら `SpeechInputService.cancel()` で音声を**文字起こしせずに破棄**する
  （Geminiに送らないのでトークンを消費しない）。そのうえで時間切れと同じく
  ローカル生成のスコア0の`CompositionFeedback`（`corrected`は空）で結果画面へ進む。
  score<70 なので既存ロジックのままSRS復習キューに載る
- 結果画面（`DrillFeedbackView`）は `skipped: true` で受け取り、スコアリングの代わりに
  グレーの「未採点」カード（バッジ「この問題は飛ばしました」）を出し、「あなたの発話」の位置には
  録音が無かったことの説明カードを置く。模範解答・解説はそのまま表示する
  （飛ばしても学べる画面にする。罰を与える見せ方はしない）。フッターは通常どおり「もう一度／次の問題へ」

### 口頭中国語作文の添削画面（ピンインのルビ＋声調フィードバック）

デザイン `SpeakingApp-Chinese.dc.html` に従い、中国語（`profile.readingLabel != null`）の添削画面では
漢字1文字ごとに「ピンインのルビ（上、10px、textSecondary）＋漢字（17px 太字）」のセルを `Wrap` で並べる
（`_RubyDiffText` / `_RubyText`）。差分トークンは `utils/word_diff.dart` がCJKを1文字1トークンに切るので、
そのままセルに対応する。ルビの割り当ては `utils/pinyin.dart` の `alignReading()` で行い、
漢字数と音節数が合わないときはルビ無しで漢字だけを出す（位置のずれたルビは出さない）。
修正版は語ごとにピンインが返るので `alignWordReadings()` で語ごとに割り当て、合わない語だけ
ルビを落とす（1語ずれただけで修正版のルビが全部消えるのを防ぐ）。
儿化は「点」に `diǎn`、「儿」に `r` を付ける。

| カード | ルビの元 |
|---|---|
| あなたの発話 | 文字起こしが返した「聞こえたままのピンイン」（`SpeechInputResult.reading`、参考値） |
| 修正版 | 添削応答の `corrected_words`（語ごとの標準ピンイン。無ければ `corrected_reading`） |
| 模範解答 | `Sentence.reading` |

差分のある文字は既存の差分表示と同じ色（削除＝`scoreLow`＋取り消し線＋`scoreLowSurface`、
追加＝`scoreGood`＋`scoreGoodSurface`）で強調する。ハイライトの箱は**単語ずつ**で、同じ語の中の
セルは隙間（2px）を詰めて角丸を外側だけに寄せ、1つの箱に見せる（`groupDiffSegments()`。
語区切りが無ければ連続する差分がひとまとまりになる）。セルは1文字ずつのままなので、
長い語でも従来どおり行末で折り返せる。ルビは文字起こしが確定した stage 1 から出す
（採点を待たない。声調の気づきも文字起こしだけで決まるので赤ルビは stage 1 から）。

スコアカードの一文は、声調の気づきが1件以上あるときだけ
「声調が違って聞こえた音節がNつあります。赤いルビを確認しましょう。」に置き換える（デザインの総評に相当）。
気づきが無いときは英語と同じスコア帯の定型文のまま。デザインにある「声調は問題ありません」は出さない
（見逃した分がそのまま嘘になる）。ドリル画面の AppBar は `profile.compositionTitle`（中国語では「口頭中国語作文」）。

**声調の気づき（赤ルビ）**: 下記ガードをすべて通った音節だけ、あなたの発話のセルで
上のルビ（聞こえた声調）を `scoreLow` に、下段に期待された声調（`scoreGood` 太字 10px）を添え、
セル背景を `scoreLowSurface` にする。1件以上あるときだけ凡例の下に
「赤字のルビは上＝実際の声調（参考値）／下＝期待された声調」を出す。
デザインにある総評の「声調は問題ありません」は**出さない**（ガード3）。

**「気づいた点」カード**: 同じ声調の気づきを一覧でも出す。`sentence.reading != null` かつ
文字起こしが `reading` を返し、かつ指摘が1件以上あるときだけ、
採点完了（stage 2）で他のカードと同じフェードインで出す。それ以外はカードごと非表示
（「問題なし」の表示は無い）。

- 見出し: `Icons.hearing` ＋「気づいた点」。「声調チェック」「声調OK」といった語は使わない
- 補足文（textSecondary 12px）: 「音声認識が聞き取った声調（参考値）が模範解答のピンインと違っていた音節です。聞き取りの誤差も含まれます。」
- 1件1行: `[3声 → 4声]` のピル（`scoreLowSurface` 背景・`scoreLow` 文字）＋ 対象の漢字（`alignReading` で対応が取れるときだけ。儿化は「点儿」）
  ＋ `shuǐ`（模範解答、textPrimary 太字）→ `shuì`（聞こえた音、scoreLow 太字）
- 英語モード（`readingLabel == null`）ではルビ・カードに関わる処理は一切走らない

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
| `drill_results` | uuid | DrillResult（sentenceId, spoken, feedback一式（中国語は corrected_reading も）, timestamp, toneNotes=声調の気づき。null は未判定＝英語・ピンイン無し。既存データは null で読める） |
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

中国語（`readingLabel != null`）ではスキーマに語区切りを2つ追加する
（`CompositionFeedback.correctedWords` / `spokenWords`。英語・旧データでは null）。

- `corrected_words`: `corrected` を単語ごとに切った `{hanzi, pinyin}` の配列。`hanzi` を繋ぐと `corrected` に
  一致させる。`pinyin` はその語の標準ピンイン（変調適用、音節ごとに半角スペース区切り、軽声は記号なし。
  句読点だけの語は空文字）。辞書どおりの読みでよく、声調の判定には使わない
- `spoken_words`: 生徒の発話を同じ規則で切った文字列の配列（ピンインは持たない。聞こえたままのピンインは
  文字起こし側が返す）

用途は2つ: 差分のハイライトを単語ずつの箱にすること（`groupDiffSegments()`）と、修正版のルビを語ごとに
割り当てること（`alignWordReadings()`）。語ごとに突き合わせるので、音節数が合わない語だけルビが落ちる。
`correctedReading`（文全体のピンイン）は語ごとのピンインを繋いだもので、語区切りが使えないとき
（旧データ・語区切りが本文と食い違うとき）のフォールバックに残している。

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
- 読み上げは別モデル（`gemini-3.1-flash-tts-preview`）なので単価も別: `GeminiPricing.tts`
  （入力 $1.00 / 出力（音声）$20.00 per 1M tokens、導入価格の設定なし。2026-09-05確認）。
  **合計トークンに単価を1つ掛けると請求とずれる**ため、コストは必ず用途ごとに計算して足す
  （`DrillQuestionUsage.costUsd()`）。音声出力は単価が高いので同じ文の読み上げはキャッシュする
- 口頭英作文の `DrillScreen` は問ごとに文字起こしと添削の `TokenUsage` を `DrillSummaryEntry.usage`（`DrillQuestionUsage`）に積み（「もう一度」のやり直し分も加算）、全問終了後の `DrillSummaryScreen` で
  - 「APIトークン使用量」カード: 文字起こし／添削／読み上げ（使った場合のみ）／合計の入力・出力トークンとコスト（USD、小数4桁）、思考トークン数、適用単価
  - 問ごとの行: `入力 N · 出力 M · $X.XXXX`（使用量ゼロの問は非表示）
- 独り言英会話は使用量を受け取るが表示はまだしない
- Hive には保存しない（セッション内表示のみ）

### 読み上げ（TTS）

`POST .../models/gemini-3.1-flash-tts-preview:generateContent`（`GeminiService.ttsModelName`）。
`gemini-3.8-flash` は音声出力に対応していないため、読み上げだけモデルを分けている。

```json
{ "contents": [{ "parts": [{ "text": "Read the following 英語 sentence clearly and a little slowly, in a calm teaching voice: I had toast this morning." }] }],
  "generationConfig": {
    "responseModalities": ["AUDIO"],
    "speechConfig": { "voiceConfig": { "prebuiltVoiceConfig": { "voiceName": "Kore" } } } } }
```

応答は `candidates[0].content.parts[0].inlineData` に base64 のPCM16（モノラル、mimeType は
`audio/L16;codec=pcm;rate=24000`）。`buildWavBytes` でWAVヘッダーを付けて再生する
（サンプリングレートは mimeType の `rate` を読む。無ければ 24000）。
`thinkingConfig` は付けない（TTSモデルは思考を持たない）。

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
2. **声調記号を外した綴り**で2つの音節列をLCS整列する（`tool/pinyin_poc` の `alignSyllables` と同じ）
3. 綴りが対応した音節どうしだけ声調番号を比較する。対応が取れない音節（聞き取りの崩れ・言い回しの違い）には
   何も言わない（ガード1）
4. どちらかが軽声（記号なし＝tone 5）の音節はスキップする（ガード2）
5. 残った不一致だけを `ToneNote`（模範解答側・発話側それぞれの音節位置・対応する漢字・期待/実測のピンイン・
   声調番号）として返す

音節分割の要件: 語ごとに連結された表記（`Qǐngwèn`）と音節スペース区切り（`qǐng wèn`）の両方／
声調記号つき母音→素の母音＋声調番号／記号なし＝軽声／j・q・x・yの後ろの ü は u と綴られるため
韻母表に `ue` を含める／儿化（`diǎnr`）の r を音節に取り込む／大文字小文字無視・句読点（全角含む）除去。

**ガード（妥協不可）**:

- **ガード1**: 綴りが模範解答の音節と対応しない音節については声調について一切何も言わない。
  聞き取り失敗時の巻き添え誤指摘を避け、模範解答と違う言い回しをしたときも期待ピンインの算出
  （変調・多音字の解決）を行わない（対応した音節の期待声調は模範解答から引ける）
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
  （`onLevel` は任意。現在の画面はどちらも表示に使っていない）
- `cancel()` は録音を止めて溜めた音声を捨てる（文字起こししない）。「わからないので飛ばす」のように
  結果が要らないと決まったときに使い、`stop()` と違ってGeminiを呼ばないのでトークンを消費しない
- 権限拒否・録音失敗時は日本語エラーメッセージ（`SpeechInputException`）を返し、画面側は録り直しの導線を用意する
- 端末STT（speech_to_text）はPR17で廃止（設定項目も削除）

## 読み上げ（TTS）の抽象化

`TtsService`（抽象）の実装は `GeminiTtsService` のみ。端末のTTSエンジンは使わない
（対応言語・声質が端末ごとにぶれるため。中国語の音声が入っていない端末でも読み上げたい）:
- `GeminiService.synthesizeSpeech()` が Gemini TTS のWAVを返し、それを `audioplayers` の
  `BytesSource` で鳴らす。読み上げ言語はモデルが入力テキストから自動判定する
- `speak()` は再生完了（または `stop()` による中断）まで待つ。画面側はこれを
  「読み上げ中」表示（ボタンが「停止」に変わる）にそのまま使える。
  `audioplayers` は `stop()` では `onPlayerComplete` を流さないため、
  完了通知と停止の両方で `Completer` を解いている（片方だけだと停止後に待ち続ける）
- 音声出力は単価が高いので、同じ文の2回目以降はメモリ上のキャッシュから再生してAPIを呼ばない
- 生成・破棄は画面（`DrillScreen`）が持ち、テストでは `FakeTtsService` に差し替える

添削画面（`drill_feedback_view.dart`）の「修正版」「模範解答」の見出し右端に
`widgets/speak_button.dart` の `SpeakButton` を置いている。読み上げ中はもう一度押すと止まる。

## Widgetbook とゴールデンテスト（見た目の確認・崩れ検出）

「実機で再現するまで崩れに気づけない」を避けるため、UIの状態一覧を2つの用途で共有する。

- **Widgetbook**（Flutter版Storybook、`widgetbook` パッケージ。dev_dependencies のみ・本番ビルドには入らない）:
  `flutter run -d chrome -t widgetbook/main.dart` でコンポーネントの各状態をブラウザで一覧できる。
  ビューポート（iPhone 13 / 12 mini / Galaxy S20）・テキストスケールのアドオンあり。
  `flutter build web -t widgetbook/main.dart` で静的サイトにもできる。
  GitHub Pages に自動配信する（`.github/workflows/widgetbook-pages.yml`: `main` への push で更新、
  `workflow_dispatch` で任意ブランチから手動デプロイ可。Pages の Source は「GitHub Actions」に設定する）
- **ゴールデンテスト**（`test/goldens/`）: 同じ状態一覧を1件ずつ描画して PNG と比較し、`flutter test`（CI）で
  レイアウトの崩れを止める。画像は `flutter test --update-goldens test/goldens` で生成し、**CI と同じ Linux で
  生成したものをコミットする**（プラットフォームでレンダリングが変わるため）

ルール:

- 状態一覧は `widgetbook/fixtures/*.dart` にだけ書く（`Story(name, slug, build)` のリスト）。Widgetbook と
  ゴールデンの両方がそこから読むので、**新しい状態は fixtures に1件足すだけ**で両方に出る
- fixtures は `widgetbook` パッケージに依存しない（テストからも読むため）。画面側は Provider や Hive に
  依存せず引数だけで描けること（`DrillFeedbackView` はそのまま載る）
- ゴールデンは `AppTheme.build(webFonts: false)` で描く。`AppTheme.light` は Google Fonts をネットワーク取得するため
  テストでは使えない。既定フォントでは漢字が四角（tofu）で描かれるが、検出したいのは文字の形ではなく
  位置・サイズ・色の崩れなので問題ない。見た目の確認は Widgetbook で行う
- 意図して見た目を変えたときだけ `--update-goldens` で画像を更新し、差分を PR で確認する

現在の対象: `DrillFeedbackView`（中国語の声調の気づき1件／なし／語数違い／複数／儿化／ルビ不整合／
修正版のピンインが1語だけ合わない／語区切りなしの旧データ＋記号なしピンイン／stage 0・1／時間切れ、
英語の差分あり／なし／飛ばした問題の未採点）。共通ウィジェット（`ScoreRing` /
`CountdownRing`）は Widgetbook のみ。

## コーディング規約

- `flutter analyze` 警告ゼロ、`dart format` 適用、flutter_lints デフォルト準拠
- UI文言は日本語ハードコード（i18n しない）。コメントも日本語可
- 1ファイル400行を目安に分割。ウィジェットの深いネストはメソッド/クラス抽出
- モデルは immutable（final フィールド＋fromJson/toJson）
- 新規依存パッケージの追加は原則しない（必要なら PR 説明に理由を書く）。例外として `widgetbook` は
  dev_dependencies に入れている（上記「Widgetbook とゴールデンテスト」）

## Git / PR ワークフロー

- ブランチ名 `feature/pr{N}-{slug}`、mainから分岐。PRは `gh pr create`
- 実装エージェントは: 実装 → `flutter analyze`（警告0）→ `flutter test` パス → commit/push → PR作成まで。**マージはしない**（レビュー担当がマージ）
- コミットは論理単位で分割。メッセージは英語1行要約＋必要なら本文
- `flutter` コマンドは `export PATH="$HOME/flutter/bin:$PATH"` で使う
