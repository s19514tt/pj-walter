import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/drill_result.dart';
import '../../models/sentence.dart';
import '../../models/token_usage.dart';
import '../../services/gemini_service.dart';
import '../../services/history_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_input_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../utils/pinyin.dart';
import '../../widgets/abort_session_dialog.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/countdown_ring.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skip_question_dialog.dart';
import '../settings_screen.dart';
import 'drill_feedback_view.dart';
import 'drill_summary_screen.dart';

/// 1問あたりの制限時間（秒）
const _questionSeconds = 30;

/// 残り時間がこの秒数以下になったらリング・タイムバーを警告色にする
const _urgentSeconds = 5;

/// 時間切れで回答できなかった場合に保存する添削結果
const _timeoutExplanation = '時間切れで回答できませんでした。模範解答を確認して復習しましょう。';

/// 「わからないので飛ばす」で未回答のまま進んだ場合に保存する添削結果
const _skipExplanation = 'わからないので飛ばした問題です。模範解答を声に出して真似るところから始めましょう。';

/// 口頭英作文ドリルの進行画面。
///
/// [sentences]を1問ずつ出題する。問題表示と同時に[SpeechInputService]による
/// 音声入力を自動で開始する。画面の要素は日本語文・残り時間・「答え合わせ」
/// ボタン1つだけで、録音停止＝採点：ボタン一押し（または時間切れ）で
/// 聞き取り終了→文字起こし→Gemini添削まで一気に行う。編集用の入力欄は無い。
/// 聞き取りに失敗した場合のみ「録り直す」導線を出す。
/// 答えが浮かばないときは「わからないので飛ばす」（確認ダイアログ付き）で
/// 未採点のまま模範解答・解説へ進める。
/// 各問の文字起こし・添削で消費したトークン数を[DrillSummaryEntry.usage]に
/// 積み（同じ問のやり直し分も加算）、全問終了後は[DrillSummaryScreen]へ
/// 遷移して使用量とコストを表示する。
class DrillScreen extends StatefulWidget {
  const DrillScreen({
    super.key,
    required this.sentences,
    required this.level,
    required this.theme,
    this.isReview = false,
    this.speechInputService,
    this.ttsService,
    this.questionSeconds = _questionSeconds,
  });

  /// 出題文一覧（すでにランダム選出済み）
  final List<Sentence> sentences;

  /// TOEICレベル（「もう一度」の再出題に使用)。復習モードでは未使用。
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）。復習モードでは未使用。
  final String? theme;

  /// 復習モードかどうか。
  ///
  /// trueの場合、添削完了時に[HistoryService.saveDrillResult]を
  /// `updateSrs: false`で呼び（SRSの二重更新を避ける）、
  /// [HistoryService.applyReviewResult]でSRSを進める。
  /// また全問終了後は[DrillSummaryScreen]（通常モード専用の「もう一度」を持つ）
  /// へは遷移せず、呼び出し元（[ReviewScreen]）に戻る。
  final bool isReview;

  /// テスト注入用。省略時は本番用のインスタンスを自動生成する。
  final SpeechInputService? speechInputService;

  /// 添削結果の読み上げに使う音声合成。テスト注入用で、省略時は
  /// 本番用の[GeminiTtsService]を自動生成する。
  final TtsService? ttsService;

  /// 1問あたりの制限時間（秒）。テスト注入用で、省略時は[_questionSeconds]（30秒）。
  final int questionSeconds;

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  late final SpeechInputService _speechInput;
  late final TtsService _tts;
  final _entries = <DrillSummaryEntry>[];

  int _index = 0;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _recording = false;
  bool _processingSpeech = false;

  /// 結果画面（段階表示）に遷移済みかどうか。「採点する」押下と同時にtrueになり、
  /// スケルトン→文字起こし→採点結果の順で埋まっていく。
  bool _resultMode = false;

  /// 録音停止時に確定した文字起こし。nullは音声認識の完了待ち（stage 0）。
  String? _stagedSpoken;

  /// 文字起こしと一緒に返った「聞こえたままのピンイン」（中国語のみ。英語はnull）。
  /// 模範解答のピンインとの声調比較（`toneNotesFor`）に使う。
  String? _stagedReading;
  bool _grading = false;
  CompositionFeedback? _feedback;

  /// 「わからないので飛ばす」で未回答のまま結果画面へ進んだかどうか。
  /// 結果画面を「未採点」表示に切り替えるためのフラグで、次の問題でリセットする。
  bool _skipped = false;

  /// 現在の問で消費したトークン（「もう一度」でやり直した分も加算）
  TokenUsage _transcriptionUsage = TokenUsage.zero;
  TokenUsage _correctionUsage = TokenUsage.zero;
  TokenUsage _speechUsage = TokenUsage.zero;

  Sentence get _current => widget.sentences[_index];

  @override
  void initState() {
    super.initState();
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(
          geminiService: context.read<GeminiService>(),
          profile: context.read<SettingsService>().languageProfile,
        );
    _tts =
        widget.ttsService ??
        GeminiTtsService(
          geminiService: context.read<GeminiService>(),
          profile: context.read<SettingsService>().languageProfile,
        );
    // カウントダウンは画面表示と同時に開始する（「読む時間」もカウントに
    // 含まれる前提）。録音は「答える」ボタンが押されるまで始めない。
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechInput.dispose();
    _tts.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = widget.questionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        _handleTimeUp();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _handleTimeUp() async {
    // 「採点する」押下による段階採点が既に走っている場合はそちらに任せる。
    if (_resultMode || _processingSpeech || _grading) return;
    if (_recording) {
      // 録音中の時間切れ＝「採点する」を押したのと同じ（段階表示で採点へ）
      await _submit();
      return;
    }
    // pre（一度も話していない）まま時間切れ → 未回答として即結果表示
    await _submitTimeout();
  }

  /// 回答が空のまま時間切れになった場合の処理。
  Future<void> _submitTimeout() =>
      _submitUnanswered(explanation: _timeoutExplanation, skipped: false);

  /// 未回答のまま結果画面へ進む処理（時間切れ／「わからないので飛ばす」）。
  ///
  /// ローカルでスコア0の[CompositionFeedback]を組み立てて即座に表示する
  /// （通信を伴わないため、待たせずにすぐ結果を見せる）。履歴・SRSキューへの
  /// 保存（score<70のため既存ロジックで自動的にSRS復習キューへ登録される）は
  /// 表示をブロックしないよう並行して行う。
  Future<void> _submitUnanswered({
    required String explanation,
    required bool skipped,
  }) async {
    if (!mounted || _grading || _feedback != null) return;
    final feedback = CompositionFeedback(
      score: 0,
      isAcceptable: false,
      corrected: '',
      explanationJa: explanation,
      comparisonJa: '',
    );
    setState(() {
      _resultMode = true;
      _skipped = skipped;
      _stagedSpoken = '';
      _stagedReading = null;
      _feedback = feedback;
    });

    final sentence = _current;
    final result = DrillResult(
      id: const Uuid().v4(),
      sentenceId: sentence.id,
      language: context.read<SettingsService>().languageProfile.code,
      level: sentence.level,
      spoken: '',
      timestamp: DateTime.now(),
      feedback: feedback,
    );
    final historyService = context.read<HistoryService>();
    if (widget.isReview) {
      await historyService.saveDrillResult(result, updateSrs: false);
      if (!mounted) return;
      await historyService.applyReviewResult(sentence.id, false);
    } else {
      await historyService.saveDrillResult(result);
    }
  }

  /// 「答える」: 録音を開始する。カウントダウンはすでに動いているので
  /// 触らない（recに入った時点でリセットしてはいけない）。
  Future<void> _startRecording() async {
    if (_recording || _secondsLeft <= 0) return;
    try {
      // 部分認識テキストは表示しない（画面は日本語文・残り時間・主ボタンのみ）
      await _speechInput.start(onPartial: (_) {});
      setState(() => _recording = true);
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
    }
  }

  /// 録音を停止し文字起こしを確定する（stage 0 → stage 1）。
  /// 失敗時は[_stagedSpoken]をnullのままにしてfalseを返す。
  Future<bool> _stopRecording() async {
    if (!_recording) return _stagedSpoken != null;
    setState(() {
      _recording = false;
      _processingSpeech = true;
    });
    try {
      final result = await _speechInput.stop();
      if (!mounted) return false;
      setState(() {
        _stagedSpoken = result.text;
        _stagedReading = result.reading;
        _transcriptionUsage = _transcriptionUsage + result.usage;
      });
      return true;
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
      return false;
    } on GeminiException catch (e) {
      _showSnack(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _processingSpeech = false);
    }
  }

  /// 段階採点を途中で断念し、pre（カウントダウン再スタート）に戻す。
  void _resetToPre() {
    if (!mounted) return;
    setState(() {
      _resultMode = false;
      _stagedSpoken = null;
      _stagedReading = null;
      _feedback = null;
      _recording = false;
      _skipped = false;
    });
    _startTimer();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 「わからないので飛ばす」: 確認ダイアログのうえで、この問題を未回答のまま
  /// 結果画面（未採点）へ進める。
  ///
  /// 録音中なら音声は文字起こしせずに破棄する（Geminiに送らないので
  /// トークンも消費しない）。飛ばした問題はスコア0で履歴に残り、
  /// 既存のロジックでそのままSRS復習キューに登録される。
  Future<void> _skipQuestion() async {
    if (_resultMode || _processingSpeech || _grading) return;
    final skip = await confirmSkipQuestion(context);
    if (!skip || !mounted || _resultMode) return;
    _timer?.cancel();
    if (_recording) {
      setState(() => _recording = false);
      await _speechInput.cancel();
      if (!mounted) return;
    }
    await _submitUnanswered(explanation: _skipExplanation, skipped: true);
  }

  Future<void> _submit() async {
    // SnackBarの「再試行」から画面破棄後・添削中に呼ばれる可能性があるためガード
    if (!mounted || _grading || _processingSpeech) return;

    final settings = context.read<SettingsService>();
    if (!settings.hasApiKey) {
      // 録音は止めずにダイアログを出す（キー設定後にそのまま続行できる）
      _showApiKeyDialog();
      return;
    }

    // 「採点する」押下と同時に結果画面（stage 0: 全カードスケルトン）へ遷移し、
    // 文字起こし完了でstage 1、採点完了でstage 2と段階的に埋める。
    if (!_resultMode) {
      if (!_recording) return; // preでは主ボタンは「答える」なのでここには来ない
      _timer?.cancel();
      setState(() => _resultMode = true);
      final ok = await _stopRecording();
      if (!mounted) return;
      if (!ok) {
        // 文字起こし失敗 → preへ戻してやり直せるようにする
        _resetToPre();
        return;
      }
      if (_stagedSpoken!.trim().isEmpty) {
        _showSnack('発話を聞き取れませんでした。もう一度話してください。');
        _resetToPre();
        return;
      }
    }

    final spoken = _stagedSpoken!.trim();
    setState(() => _grading = true);
    final gemini = context.read<GeminiService>();
    final sentence = _current;
    try {
      final profile = context.read<SettingsService>().languageProfile;
      final correction = await gemini.correctComposition(
        profile: profile,
        ja: sentence.ja,
        modelAnswer: sentence.target,
        spoken: spoken,
      );
      final feedback = correction.feedback;
      final result = DrillResult(
        id: const Uuid().v4(),
        sentenceId: sentence.id,
        language: profile.code,
        level: sentence.level,
        spoken: spoken,
        timestamp: DateTime.now(),
        feedback: feedback,
        // 声調の気づき（中国語のみ）。スコア・SRSには一切影響しない。
        toneNotes: toneNotesFor(
          profile: profile,
          sentence: sentence,
          spokenReading: _stagedReading,
        ),
      );
      if (!mounted) return;
      final historyService = context.read<HistoryService>();
      if (widget.isReview) {
        // 復習モードではSRSの二重更新を避けるためsaveDrillResultではSRSを
        // 更新せず、applyReviewResultで明示的に反映する（履歴・日次統計は記録する）。
        await historyService.saveDrillResult(result, updateSrs: false);
        if (!mounted) return;
        await historyService.applyReviewResult(
          sentence.id,
          feedback.isAcceptable,
        );
      } else {
        await historyService.saveDrillResult(result);
      }
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _correctionUsage = _correctionUsage + correction.usage;
        _grading = false;
      });
    } on GeminiException catch (e) {
      // 採点失敗: stage 1（文字起こし表示）のまま留まり、再試行できるようにする
      if (!mounted) return;
      setState(() => _grading = false);
      _showRetrySnack(e.message);
    }
  }

  void _showRetrySnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: '再試行', onPressed: _submit),
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('APIキーが未設定です'),
        content: const Text('Gemini APIキーが設定されていません。設定画面から登録してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const SettingsScreen()));
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  /// 「もう一度」: 同じ問題のpre（カウントダウン再スタート）に戻す
  /// （採点結果は破棄。履歴には残る）。
  void _retryCurrent() {
    _resetToPre();
  }

  void _next() {
    final feedback = _feedback;
    if (feedback != null) {
      _entries.add(
        DrillSummaryEntry(
          ja: _current.ja,
          score: feedback.score,
          usage: DrillQuestionUsage(
            transcription: _transcriptionUsage,
            correction: _correctionUsage,
            speech: _speechUsage,
          ),
        ),
      );
    }

    if (_index >= widget.sentences.length - 1) {
      if (widget.isReview) {
        // 復習セッションは複数レベル・テーマの文が混在しうるため、通常モード専用の
        // 「もう一度」（単一level/themeで再出題）を持つDrillSummaryScreenは使わず、
        // 呼び出し元のReviewScreenへ戻る。
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacement(
        appRoute(
          builder: (_) => DrillSummaryScreen(
            level: widget.level,
            theme: widget.theme,
            entries: List.of(_entries),
          ),
        ),
      );
      return;
    }

    setState(() {
      _index++;
      _resultMode = false;
      _stagedSpoken = null;
      _stagedReading = null;
      _feedback = null;
      _recording = false;
      _skipped = false;
      _transcriptionUsage = TokenUsage.zero;
      _correctionUsage = TokenUsage.zero;
      _speechUsage = TokenUsage.zero;
    });
    // 次の問題もカウントダウンは表示と同時に開始する
    _startTimer();
  }

  /// 戻る操作（AppBarの戻る・システムバック）の誤操作防止。
  /// 確認ダイアログで「中断する」を選んだときだけ画面を閉じる。
  Future<void> _onPopRequested() async {
    final abort = await confirmAbortSession(context);
    if (abort && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onPopRequested();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReview
              ? '復習'
              : context
                    .watch<SettingsService>()
                    .languageProfile
                    .compositionTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_index + 1} / ${widget.sentences.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        // 「採点する」押下と同時に段階表示の結果ビューへ切り替える
        // （スケルトン→文字起こし→採点結果と埋まっていく）。
        child: _resultMode
            ? DrillFeedbackView(
                sentence: _current,
                profile: context.watch<SettingsService>().languageProfile,
                spoken: _stagedSpoken,
                spokenReading: _stagedReading,
                feedback: _feedback,
                skipped: _skipped,
                onNext: _next,
                onRetry: _retryCurrent,
                ttsService: _tts,
                onSpeechUsage: (usage) => _speechUsage = _speechUsage + usage,
                isLast: _index >= widget.sentences.length - 1,
              )
            : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final profile = context.watch<SettingsService>().languageProfile;
    // pre（録音前）かどうか。円環・ゲージだけ色を落とす（問題文カードは常時アクティブ）
    final pre = !_recording;
    final urgent = !pre && _secondsLeft <= _urgentSeconds;
    return Column(
      children: [
        // 画面上端の残り時間ゲージ（6px）。pre=#C9CCD1 / rec=オレンジ、残り5秒以下で赤
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _secondsLeft / widget.questionSeconds),
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          builder: (context, value, child) => LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(
              pre
                  ? const Color(0xFFC9CCD1)
                  : urgent
                  ? AppColors.scoreLow
                  : AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'この日本語を${profile.label}で',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _current.ja,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.7,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: CountdownRing(
                      progress: _secondsLeft / widget.questionSeconds,
                      label: '$_secondsLeft',
                      recording: _recording,
                      idleLabel: '聞き取り前',
                      dimmed: pre,
                      urgent: urgent,
                    ),
                  ),
                ),
                // 答えが浮かばないまま時間を眺め続けずに模範解答へ進める逃げ道。
                // 主ボタンと競合しないよう、下線付きのテキストリンクで控えめに置く。
                _SkipQuestionButton(onPressed: _skipQuestion),
              ],
            ),
          ),
        ),
        BottomCtaBar(
          child: PrimaryButton(
            // pre=答える（録音開始）/ rec=採点する（停止＝採点）。
            // 「録音する」という語は使わない。
            label: _recording ? '採点する' : '答える',
            onPressed: _recording ? _submit : _startRecording,
          ),
        ),
      ],
    );
  }
}

/// 「わからないので飛ばす」導線（下線付きのテキストリンク）。
///
/// 主ボタン（答える／採点する）より弱く見せるため、グレー文字＋薄いグレーの
/// 下線にしている。
///
/// 下線は[TextDecoration.underline]ではなく下ボーダーで引く。デザインは
/// `text-underline-offset:4px`で文字から離した下線（ベースラインの約6px下）
/// だが、Flutterの下線はフォントの下線位置に密着し、オフセットを指定できないため。
class _SkipQuestionButton extends StatelessWidget {
  const _SkipQuestionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5F6368),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Container(
        // 文字ボックス（fontSize 13・height 1 なので高さ13）の下端から4px下に
        // 1pxの線。ブラウザで`text-underline-offset:4px`と重ねて実測した値。
        padding: const EdgeInsets.only(bottom: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFB9BDC4))),
        ),
        child: const Text(
          'わからないので飛ばす',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
