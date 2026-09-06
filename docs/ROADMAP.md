# ロードマップ

pj-walter は**未リリースで既存ユーザーがいない**。したがって、以下のどのフェーズでも
**データマイグレーション・フィーチャーフラグ・段階リリース・後方互換の維持は行わない**。
Hive の保存データは壊してよく、形式を変えるときは起動時に旧 box を削除するだけでよい
（`lib/main.dart` の `_legacyBoxNames`）。「旧データを読めるようにする」ためのフォールバック
コードは書かない。

## フェーズ1（完了）: クリーンアーキテクチャ化 + signals + i18n 基盤

- feature-first 構成（`lib/core/` + `lib/features/<機能>/{domain,data,presentation}`）
- 状態管理を `provider` + `ChangeNotifier` から **signals（`signals_flutter`）** へ全面移行。
  画面ごとに Store（signal / computed を持つ）を置き、UI は `SignalBuilder` で購読する
- DI は **get_it によるコンポジションルート**（`lib/core/di/`）。UI・Store は get_it を直接見ない
- モデルは **freezed + json_serializable**。外部 I/O 用の DTO と domain の Entity を分離
- **flutter_localizations + ARB（gen-l10n）** を導入し、UI 文言をすべて ARB 経由にした（訳文は ja のみ）
- 外部 I/O（添削・文字起こし・読み上げ・教材）を Repository インタフェースに分解し、
  Gemini 直叩き・アセット読み込みの実装を `data/` に隔離した（フェーズ2の差し替え点）
- API 契約から日本語を剥がした（`explanation_ja` → `explanation` 等）。リクエストには
  `uiLocale`（アプリ表示言語）と `learningLanguage`（学習言語）の2軸を明示的に渡す

詳細は [DESIGN.md](../DESIGN.md) の「アーキテクチャ」を参照。

## フェーズ2: バックエンド構築

- Rust + axum、Docker / EC2、Firebase Auth、Postgres
- REST + OpenAPI。リアルタイム音声のみ WebSocket
- **Gemini API キーはサーバ側に集約**し、アプリの設定画面から API キー入力を廃止する
- プロンプトと JSON スキーマを Rust 側へ移植する
  （現在は `lib/features/*/data/gemini_*_repository.dart` にある。契約の形はフェーズ1で最終形にしてあるので、
  スキーマのキー名は変えずに移す）
- アプリ側の差し替え点: 次の Repository インタフェースの実装を Gemini 直叩きからサーバ呼び出しに置き換える
  - `CorrectionRepository`（口頭作文の添削）
  - `MonologueReviewRepository`（独り言のフィードバック）
  - `TranscriptionRepository`（文字起こし）
  - `TtsRepository`（読み上げ音声の生成）
  - `ContentRepository`（教材・お題。アセット同梱からサーバ配信へ）
  - 併せて `SettingsRepository` から API キーが消え、`lib/core/data/gemini_client.dart` は削除される
- 認証リダイレクトが必要になった時点で `go_router` の導入を検討する（フェーズ1では入れない）

## フェーズ3: 多言語対応

- 学習言語 6 言語 + アプリ UI 6 言語
- UI 言語: `lib/core/l10n/app_<locale>.arb` を追加するだけ（キーは ja と同じ）
- 学習言語: `LanguageProfile.values` に1件足し、`LanguageSupport`（分かち書き・読み表記・TTS ボイス）を
  実装し、教材アセットを置く。言語名・トレーニング名・デッキ名は ARB の select キーで
  UI 言語 × 学習言語の組み合わせを表す（直書きしない）
- ゴールデンテストはロケールを `ja` に固定してあるため、翻訳を足しても画像は変わらない
