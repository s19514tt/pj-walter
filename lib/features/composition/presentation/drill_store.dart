import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/token_usage.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/sentence.dart';
import '../../settings/domain/settings_repository.dart';
import '../../speech/domain/speech_input_service.dart';
import '../../speech/domain/tts_service.dart';
import '../domain/correction_repository.dart';
import '../domain/drill_result.dart';
import '../domain/drill_session.dart';
import '../domain/pinyin.dart';
import '../domain/record_drill_result.dart';

/// 画面側で表示する必要のある、Store の状態としては持たない一回きりの出来事。
///
/// Store は `BuildContext` を持たないため、SnackBar・ダイアログ・画面遷移は
/// 画面がこれを受けて行う（[DrillStore.notice] を `initState` で購読する）。
sealed class DrillNotice {
  const DrillNotice();
}

/// 失敗を SnackBar で見せる。[retryable] なら「再試行」アクション付き。
class DrillFailureNotice extends DrillNotice {
  const DrillFailureNotice(this.failure, {this.retryable = false});

  final AppFailure failure;
  final bool retryable;
}

/// 文字起こしが空だった（録り直しを促す）。
class DrillEmptyTranscriptNotice extends DrillNotice {
  const DrillEmptyTranscriptNotice();
}

/// API キーが未設定（設定画面へ誘導するダイアログを出す）。
class DrillApiKeyMissingNotice extends DrillNotice {
  const DrillApiKeyMissingNotice();
}

/// 全問終了した。復習モードなら呼び出し元へ戻り、通常はまとめ画面へ。
class DrillSessionFinishedNotice extends DrillNotice {
  const DrillSessionFinishedNotice(this.entries);

  final List<DrillSummaryEntry> entries;
}

/// 未回答のまま確定するときに履歴へ残す解説文（UI 言語で書かれた文言）。
///
/// Store は文言を持たないため、画面が ARB から引いて渡す。
class DrillTexts {
  const DrillTexts({
    required this.timeoutExplanation,
    required this.skipExplanation,
  });

  /// 時間切れで回答できなかった場合の解説
  final String timeoutExplanation;

  /// 「わからないので飛ばす」で進んだ場合の解説
  final String skipExplanation;
}

/// 口頭作文ドリルの進行を担う Store（DESIGN.md「口頭英作文」）。
///
/// [sentences]を1問ずつ出題する。カウントダウンは問題表示と同時に始まり、
/// 録音は「答える」まで始めない。「採点する」（または録音中の時間切れ）で
/// 結果ビュー（段階表示）へ切り替え、文字起こし→添削と埋めていく。
/// 各問の文字起こし・添削・読み上げで消費したトークンを
/// [DrillSummaryEntry.usage]に積み、全問終了で [DrillSessionFinishedNotice] を出す。
///
/// 録音・読み上げサービスの寿命は Store と同じ（[dispose] で解放）。
class DrillStore extends Store {
  DrillStore({
    required this.sentences,
    required this.level,
    required this.theme,
    required this.isReview,
    required this.uiLocale,
    required this.texts,
    required this._speechInput,
    required this._tts,
    required this._correction,
    required this._recordResult,
    required SettingsRepository settings,
    this.questionSeconds = defaultQuestionSeconds,
  }) : _settings = settings,
       profile = settings.settings.peek().languageProfile {
    index = createSignal(0);
    secondsLeft = createSignal(questionSeconds);
    recording = createSignal(false);
    processingSpeech = createSignal(false);
    resultMode = createSignal(false);
    stagedSpoken = createSignal(null);
    stagedReading = createSignal(null);
    grading = createSignal(false);
    feedback = createSignal(null);
    skipped = createSignal(false);
    notice = createSignal(null);
    current = createComputed(() => sentences[index.value]);
    isLast = createComputed(() => index.value >= sentences.length - 1);
    urgent = createComputed(
      () => recording.value && secondsLeft.value <= urgentSeconds,
    );
    progress = createComputed(() => secondsLeft.value / questionSeconds);
    addDisposer(() {
      _timer?.cancel();
      _speechInput.dispose();
      _tts.dispose();
    });
    // カウントダウンは画面表示と同時に開始する（「読む時間」もカウントに
    // 含まれる前提）。録音は「答える」が押されるまで始めない。
    _startTimer();
  }

  /// 1問あたりの制限時間（秒）
  static const defaultQuestionSeconds = 30;

  /// 残り時間がこの秒数以下になったらリング・タイムバーを警告色にする
  static const urgentSeconds = 5;

  final List<Sentence> sentences;
  final int level;
  final String? theme;

  /// 復習モードかどうか（SRS の更新の仕方が変わる。DESIGN.md「SRS アルゴリズム」）
  final bool isReview;

  /// 解説を書く言語（添削リクエストの `uiLocale`）
  final String uiLocale;
  final DrillTexts texts;
  final int questionSeconds;

  /// 学習言語（画面を開いた時点の設定で固定）
  final LanguageProfile profile;

  final SpeechInputService _speechInput;
  final TtsService _tts;
  final CorrectionRepository _correction;
  final RecordDrillResult _recordResult;
  final SettingsRepository _settings;

  /// 「修正版」「模範解答」の読み上げに使う音声合成（結果ビューが使う）
  TtsService get tts => _tts;

  late final Signal<int> index;
  late final Signal<int> secondsLeft;
  late final Signal<bool> recording;
  late final Signal<bool> processingSpeech;

  /// 結果ビュー（段階表示）に切り替え済みかどうか。「採点する」押下と同時に true になり、
  /// スケルトン→文字起こし→採点結果の順で埋まっていく
  late final Signal<bool> resultMode;

  /// 録音停止時に確定した文字起こし。null は音声認識の完了待ち（stage 0）
  late final Signal<String?> stagedSpoken;

  /// 文字起こしと一緒に返った「聞こえたままのピンイン」（中国語のみ）
  late final Signal<String?> stagedReading;
  late final Signal<bool> grading;
  late final Signal<CompositionFeedback?> feedback;

  /// 「わからないので飛ばす」で未回答のまま結果ビューへ進んだかどうか
  late final Signal<bool> skipped;

  /// 一回きりの出来事（画面が購読する）
  late final Signal<DrillNotice?> notice;

  late final Computed<Sentence> current;
  late final Computed<bool> isLast;
  late final Computed<bool> urgent;
  late final Computed<double> progress;

  final _entries = <DrillSummaryEntry>[];
  Timer? _timer;

  /// 現在の問で消費したトークン（「もう一度」でやり直した分も加算）
  TokenUsage _transcriptionUsage = TokenUsage.zero;
  TokenUsage _correctionUsage = TokenUsage.zero;
  TokenUsage _speechUsage = TokenUsage.zero;

  void _startTimer() {
    _timer?.cancel();
    secondsLeft.value = questionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (disposed) {
        timer.cancel();
        return;
      }
      if (secondsLeft.value <= 1) {
        timer.cancel();
        secondsLeft.value = 0;
        _handleTimeUp();
        return;
      }
      secondsLeft.value--;
    });
  }

  Future<void> _handleTimeUp() async {
    // 「採点する」押下による段階採点が既に走っている場合はそちらに任せる。
    if (resultMode.value || processingSpeech.value || grading.value) return;
    if (recording.value) {
      // 録音中の時間切れ＝「採点する」を押したのと同じ（段階表示で採点へ）
      await submit();
      return;
    }
    // pre（一度も話していない）まま時間切れ → 未回答として即結果表示
    await _submitUnanswered(
      explanation: texts.timeoutExplanation,
      skipped: false,
    );
  }

  /// 未回答のまま結果ビューへ進む（時間切れ／「わからないので飛ばす」）。
  ///
  /// ローカルでスコア0の[CompositionFeedback]を組み立てて即座に表示する
  /// （通信を伴わないため、待たせずにすぐ結果を見せる）。履歴・SRSキューへの
  /// 保存（score<70のため自動的にSRS復習キューへ登録される）は表示をブロックしない。
  Future<void> _submitUnanswered({
    required String explanation,
    required bool skipped,
  }) async {
    if (disposed || grading.value || feedback.value != null) return;
    final unanswered = CompositionFeedback.unanswered(explanation: explanation);
    batch(() {
      resultMode.value = true;
      this.skipped.value = skipped;
      stagedSpoken.value = '';
      stagedReading.value = null;
      feedback.value = unanswered;
    });

    final sentence = current.peek();
    await _recordResult(
      DrillResult(
        id: const Uuid().v4(),
        sentenceId: sentence.id,
        language: profile.code,
        level: sentence.level,
        spoken: '',
        timestamp: DateTime.now(),
        feedback: unanswered,
      ),
      isReview: isReview,
    );
  }

  /// 「答える」: 録音を開始する。カウントダウンはすでに動いているので触らない。
  Future<void> startRecording() async {
    if (recording.value || secondsLeft.value <= 0) return;
    try {
      await _speechInput.start();
      if (disposed) return;
      recording.value = true;
    } on AppFailure catch (e) {
      notice.value = DrillFailureNotice(e);
    }
  }

  /// 録音を停止し文字起こしを確定する（stage 0 → stage 1）。
  /// 失敗時は[stagedSpoken]をnullのままにしてfalseを返す。
  Future<bool> _stopRecording() async {
    if (!recording.value) return stagedSpoken.value != null;
    batch(() {
      recording.value = false;
      processingSpeech.value = true;
    });
    try {
      final result = await _speechInput.stop();
      if (disposed) return false;
      batch(() {
        stagedSpoken.value = result.text;
        stagedReading.value = result.reading;
      });
      _transcriptionUsage += result.usage;
      return true;
    } on AppFailure catch (e) {
      notice.value = DrillFailureNotice(e);
      return false;
    } finally {
      if (!disposed) processingSpeech.value = false;
    }
  }

  /// 段階採点を途中で断念し、pre（カウントダウン再スタート）に戻す。
  void _resetToPre() {
    if (disposed) return;
    batch(() {
      resultMode.value = false;
      stagedSpoken.value = null;
      stagedReading.value = null;
      feedback.value = null;
      recording.value = false;
      skipped.value = false;
    });
    _startTimer();
  }

  /// 「わからないので飛ばす」（画面側で確認ダイアログを通した後に呼ぶ）。
  ///
  /// 録音中なら音声は文字起こしせずに破棄する（トークンを消費しない）。
  /// 飛ばした問題はスコア0で履歴に残り、そのままSRS復習キューに登録される。
  Future<void> skip() async {
    if (resultMode.value || processingSpeech.value || grading.value) return;
    _timer?.cancel();
    if (recording.value) {
      recording.value = false;
      await _speechInput.cancel();
      if (disposed) return;
    }
    await _submitUnanswered(explanation: texts.skipExplanation, skipped: true);
  }

  /// 「採点する」／再試行: 録音停止→文字起こし→添削→保存。
  Future<void> submit() async {
    // SnackBarの「再試行」から画面破棄後・添削中に呼ばれる可能性があるためガード
    if (disposed || grading.value || processingSpeech.value) return;

    if ((_settings.apiKey.peek() ?? '').isEmpty) {
      // 録音は止めずにダイアログを出す（キー設定後にそのまま続行できる）
      notice.value = const DrillApiKeyMissingNotice();
      return;
    }

    // 「採点する」押下と同時に結果ビュー（stage 0: 全カードスケルトン）へ遷移し、
    // 文字起こし完了でstage 1、採点完了でstage 2と段階的に埋める。
    if (!resultMode.value) {
      if (!recording.value) return; // preでは主ボタンは「答える」なのでここには来ない
      _timer?.cancel();
      resultMode.value = true;
      final ok = await _stopRecording();
      if (disposed) return;
      if (!ok) {
        // 文字起こし失敗 → preへ戻してやり直せるようにする
        _resetToPre();
        return;
      }
      if (stagedSpoken.value!.trim().isEmpty) {
        notice.value = const DrillEmptyTranscriptNotice();
        _resetToPre();
        return;
      }
    }

    final spoken = stagedSpoken.value!.trim();
    grading.value = true;
    final sentence = current.peek();
    try {
      final correction = await _correction.correct(
        CorrectionRequest(
          uiLocale: uiLocale,
          learningLanguage: profile.code,
          source: sentence.ja,
          modelAnswer: sentence.target,
          spoken: spoken,
        ),
      );
      if (disposed) return;
      final result = DrillResult(
        id: const Uuid().v4(),
        sentenceId: sentence.id,
        language: profile.code,
        level: sentence.level,
        spoken: spoken,
        timestamp: DateTime.now(),
        feedback: correction.feedback,
        // 声調の気づき（中国語のみ）。スコア・SRSには一切影響しない。
        toneNotes: toneNotesFor(
          profile: profile,
          sentence: sentence,
          spokenReading: stagedReading.peek(),
        ),
      );
      await _recordResult(result, isReview: isReview);
      if (disposed) return;
      _correctionUsage += correction.usage;
      batch(() {
        feedback.value = correction.feedback;
        grading.value = false;
      });
    } on AppFailure catch (e) {
      // 採点失敗: stage 1（文字起こし表示）のまま留まり、再試行できるようにする
      if (disposed) return;
      grading.value = false;
      notice.value = DrillFailureNotice(e, retryable: true);
    }
  }

  /// 読み上げでAI APIが消費したトークンを現在の問に積む。
  void addSpeechUsage(TokenUsage usage) => _speechUsage += usage;

  /// 「もう一度」: 同じ問題のpre（カウントダウン再スタート）に戻す
  /// （採点結果は破棄。履歴には残る）。
  void retryCurrent() => _resetToPre();

  /// 「次の問題へ」／「結果を見る」。
  void next() {
    final current = feedback.value;
    if (current != null) {
      _entries.add(
        DrillSummaryEntry(
          ja: this.current.peek().ja,
          score: current.score,
          usage: DrillQuestionUsage(
            transcription: _transcriptionUsage,
            correction: _correctionUsage,
            speech: _speechUsage,
          ),
        ),
      );
    }

    if (isLast.value) {
      _timer?.cancel();
      notice.value = DrillSessionFinishedNotice(List.unmodifiable(_entries));
      return;
    }

    batch(() {
      index.value++;
      resultMode.value = false;
      stagedSpoken.value = null;
      stagedReading.value = null;
      feedback.value = null;
      recording.value = false;
      skipped.value = false;
    });
    _transcriptionUsage = TokenUsage.zero;
    _correctionUsage = TokenUsage.zero;
    _speechUsage = TokenUsage.zero;
    // 次の問題もカウントダウンは表示と同時に開始する
    _startTimer();
  }
}
