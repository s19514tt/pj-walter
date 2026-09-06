import '../../../core/domain/token_usage.dart';

/// [TtsService.speak]の結果（読み上げに消費したトークン使用量）。
///
/// 同じ文をキャッシュから再生した場合は[TokenUsage.zero]（API呼び出し無し）。
typedef SpeakResult = ({TokenUsage usage});

/// 学習言語の文を読み上げる音声合成＋再生の抽象化。
///
/// 実装は `AudioPlayerTtsService`（[TtsRepository] で音声を生成して端末で再生）のみ。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
/// 失敗は [AppFailure]（[FailureKind.playback] など）。
abstract interface class TtsService {
  /// [text]を読み上げる。再生が終わる（または中断される）まで待つ。
  ///
  /// すでに読み上げ中の場合は、それを止めてから新しい文を読み始める。
  Future<SpeakResult> speak(String text);

  /// 読み上げ中なら中断する。読み上げていない場合は何もしない。
  Future<void> stop();

  /// 内部リソースを解放する。所有者（Store）の破棄時に必ず呼ぶこと。
  void dispose();
}
