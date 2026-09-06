import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/topic.dart';
import '../../review/domain/phrase.dart';
import '../../review/domain/phrase_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../../speech/domain/speech_input_service.dart';
import '../domain/monologue_result.dart';
import '../domain/monologue_review_repository.dart';
import '../domain/record_monologue_result.dart';

/// フィードバック画面が反応する一回きりの出来事。
sealed class MonologueFeedbackNotice {
  const MonologueFeedbackNotice();
}

/// 文字起こし段階で失敗した（SnackBar を出して前の画面へ戻る）
class MonologueTranscriptionFailedNotice extends MonologueFeedbackNotice {
  const MonologueTranscriptionFailedNotice(this.failure);

  /// null は「発話が空だった」
  final AppFailure? failure;
}

/// 添削に失敗した（stage 1 に留まり再試行できる）
class MonologueGradingFailedNotice extends MonologueFeedbackNotice {
  const MonologueGradingFailedNotice(this.failure);

  final AppFailure failure;
}

/// 独り言のフィードバック画面の Store（段階表示）。
///
/// - stage 0: [transcript] = null（録音停止＝文字起こしを待つ）
/// - stage 1: [transcript] あり、[result] = null（添削待ち）
/// - stage 2: [result] あり
///
/// [initialResult] を渡した場合は完成済みとして最初から stage 2。
/// [speechInput] を渡した場合は [start] で停止→文字起こし→添削→保存まで進め、
/// 録音サービスの破棄もこの Store が責任を持つ。
class MonologueFeedbackStore extends Store {
  MonologueFeedbackStore({
    required this.topic,
    required this.seconds,
    required this.uiLocale,
    required this._review,
    required this._recordResult,
    required this._phrases,
    required SettingsRepository settings,
    MonologueResult? initialResult,
    this._speechInput,
  }) : assert(
         initialResult != null || _speechInput != null,
         'initialResult か speechInput のどちらかが必要',
       ),
       profile = settings.settings.peek().languageProfile {
    transcript = createSignal(initialResult?.transcript);
    result = createSignal(initialResult);
    grading = createSignal(false);
    addedPhraseIndices = createSignal(const {});
    notice = createSignal(null);
    addDisposer(() => _speechInput?.dispose());
  }

  final Topic topic;
  final int seconds;

  /// 解説を書く言語（フィードバックリクエストの `uiLocale`）
  final String uiLocale;
  final LanguageProfile profile;

  final MonologueReviewRepository _review;
  final RecordMonologueResult _recordResult;
  final PhraseRepository _phrases;
  final SpeechInputService? _speechInput;

  /// 文字起こし。null は音声認識の完了待ち（stage 0）
  late final Signal<String?> transcript;

  /// 添削済み結果。null は添削待ち（stage 0〜1）
  late final Signal<MonologueResult?> result;
  late final Signal<bool> grading;

  /// フレーズ帳に追加済みの「使えるフレーズ」の添字
  late final Signal<Set<int>> addedPhraseIndices;
  late final Signal<MonologueFeedbackNotice?> notice;

  /// 録音停止（文字起こし）→添削→保存のパイプラインを始める。
  ///
  /// 画面が [notice] を購読してから呼ぶこと（失敗時に前の画面へ戻るため）。
  Future<void> start() async {
    final speech = _speechInput;
    if (speech == null || result.value != null) return;
    String text;
    try {
      text = (await speech.stop()).text;
    } on AppFailure catch (e) {
      if (disposed) return;
      notice.value = MonologueTranscriptionFailedNotice(e);
      return;
    }
    if (disposed) return;
    if (text.trim().isEmpty) {
      notice.value = const MonologueTranscriptionFailedNotice(null);
      return;
    }
    // stage 1: 文字起こしだけ実テキストに
    transcript.value = text.trim();
    await grade();
  }

  /// 添削（stage 1 → stage 2）。失敗時は notice を出して stage 1 に留まる。
  Future<void> grade() async {
    if (disposed || grading.value || result.value != null) return;
    final text = transcript.value;
    if (text == null) return;
    grading.value = true;
    try {
      // 独り言ではトークン使用量の表示はまだ行わない（口頭作文のまとめ画面のみ）。
      final review = await _review.review(
        MonologueReviewRequest(
          uiLocale: uiLocale,
          learningLanguage: profile.code,
          topicSource: topic.ja,
          topicTarget: topic.target,
          seconds: seconds,
          transcript: text,
        ),
      );
      if (disposed) return;
      final saved = MonologueResult(
        id: const Uuid().v4(),
        topicId: topic.id,
        language: profile.code,
        seconds: seconds,
        transcript: text,
        timestamp: DateTime.now(),
        feedback: review.feedback,
      );
      await _recordResult(saved);
      if (disposed) return;
      batch(() {
        result.value = saved;
        grading.value = false;
      });
    } on AppFailure catch (e) {
      if (disposed) return;
      grading.value = false;
      notice.value = MonologueGradingFailedNotice(e);
    }
  }

  /// 「使えるフレーズ」の[index]番目をフレーズ帳に追加する。
  Future<void> addPhrase(int index) async {
    final current = result.value;
    if (current == null || addedPhraseIndices.value.contains(index)) return;
    final phrase = current.feedback.usefulPhrases[index];
    await _phrases.add(
      Phrase(
        id: const Uuid().v4(),
        target: phrase.target,
        ja: phrase.ja,
        source: topic.id,
        createdAt: DateTime.now(),
      ),
    );
    if (disposed) return;
    addedPhraseIndices.value = {...addedPhraseIndices.value, index};
  }
}
