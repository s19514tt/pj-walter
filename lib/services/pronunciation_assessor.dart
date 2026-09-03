// コンストラクタの公開パラメータ名（geminiService）と内部フィールド名
// （_geminiService）をあえて分けているため、initializing formalは使わない。
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../models/pronunciation_feedback.dart';
import 'gemini_service.dart';

/// 発音評価の抽象化。
///
/// 現在の実装は[GeminiPronunciationAssessor]（Gemini音声マルチモーダル）のみ。
/// 将来、音素レベルの専用API（Azure Pronunciation Assessment等）に差し替える
/// 場合もこのインターフェースの背後で行い、画面側は変更しない。
abstract class PronunciationAssessor {
  /// 録音音声の発音を評価する。
  ///
  /// [spokenText]は音声の文字起こし（ユーザーが編集済みの場合はその文）で、
  /// 単語ごとの評価はこの語順に沿って返る。[modelAnswer]は参考情報として渡す。
  /// 失敗時は[GeminiException]等を投げる。呼び出し側は発音評価の失敗を
  /// 添削全体の失敗として扱わないこと（degrade可能）。
  Future<PronunciationFeedback> assess({
    required Uint8List audioBytes,
    required String mimeType,
    required String spokenText,
    required String modelAnswer,
  });
}

/// [GeminiService.assessPronunciation]に委譲する実装。
class GeminiPronunciationAssessor implements PronunciationAssessor {
  GeminiPronunciationAssessor({required GeminiService geminiService})
    : _geminiService = geminiService;

  final GeminiService _geminiService;

  @override
  Future<PronunciationFeedback> assess({
    required Uint8List audioBytes,
    required String mimeType,
    required String spokenText,
    required String modelAnswer,
  }) {
    return _geminiService.assessPronunciation(
      audioBytes: audioBytes,
      mimeType: mimeType,
      spokenText: spokenText,
      modelAnswer: modelAnswer,
    );
  }
}
