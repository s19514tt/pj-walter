import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/drill_result.dart';
import '../../models/sentence.dart';
import '../../services/gemini_service.dart';
import '../../services/history_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_input_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../utils/theme_labels.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/primary_button.dart';
import '../settings_screen.dart';
import 'drill_feedback_view.dart';
import 'drill_summary_screen.dart';

/// 1問あたりの制限時間（秒）
const _questionSeconds = 30;

/// 残り時間がこの秒数以下になったらタイマー表示・進捗バーを警告色にする
const _urgentSeconds = 10;

/// 時間切れで回答できなかった場合に保存する添削結果
const _timeoutExplanation = '時間切れで回答できませんでした。模範解答を確認して復習しましょう。';

/// 口頭英作文ドリルの進行画面。
///
/// [sentences]を1問ずつ出題する。問題表示と同時に[SpeechInputService]による
/// 音声入力を自動で開始する。画面の要素は日本語文・残り時間・「答え合わせ」
/// ボタン1つだけで、録音停止＝採点：ボタン一押し（または時間切れ）で
/// 聞き取り終了→文字起こし→Gemini添削まで一気に行う。編集用の入力欄は無い。
/// 聞き取りに失敗した場合のみ「録り直す」導線を出す。
/// 全問終了後は[DrillSummaryScreen]へ遷移する。
class DrillScreen extends StatefulWidget {
  const DrillScreen({
    super.key,
    required this.sentences,
    required this.level,
    required this.theme,
    this.isReview = false,
    this.speechInputService,
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

  /// テスト注入用。省略時は設定に応じたインスタンスを自動生成する。
  final SpeechInputService? speechInputService;

  /// 1問あたりの制限時間（秒）。テスト注入用で、省略時は[_questionSeconds]（30秒）。
  final int questionSeconds;

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  late final SpeechInputService _speechInput;
  final _entries = <DrillSummaryEntry>[];

  int _index = 0;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _recording = false;
  bool _processingSpeech = false;

  /// 録音停止時に確定した文字起こし。停止＝採点に直結するため編集UIは持たない。
  String _spoken = '';
  bool _grading = false;
  CompositionFeedback? _feedback;
  String? _gradedSpoken;

  /// 自動録音開始に失敗した（マイク権限なし等）ことを記録するフラグ。
  /// 問題が切り替わるたびに同じエラーSnackBarを出さないため、これがtrueの間は
  /// 自動開始をスキップする。「録り直す」で成功すれば解除される。
  bool _speechUnavailable = false;

  Sentence get _current => widget.sentences[_index];

  @override
  void initState() {
    super.initState();
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(
          settingsService: context.read<SettingsService>(),
          geminiService: context.read<GeminiService>(),
        );
    _startTimer();
    // 問題表示と同時に音声入力を自動開始する（ボタン操作を待たない）。
    // SnackBar表示にScaffoldが必要なため初回フレーム後に行う。
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStartRecording());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechInput.dispose();
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
    // 「答え合わせ」押下による文字起こし・採点が既に走っている場合は
    // そちらに任せる（二重停止・二重採点を防ぐ）。
    if (_processingSpeech || _grading || _feedback != null) return;
    if (_recording) {
      await _stopRecording();
    }
    if (!mounted || _grading || _feedback != null) return;
    if (_spoken.trim().isNotEmpty) {
      await _submit();
      return;
    }
    await _submitTimeout();
  }

  /// 回答が空のまま時間切れになった場合の処理。
  ///
  /// ローカルでスコア0の[CompositionFeedback]を組み立てて即座に表示する
  /// （通信を伴わないため、待たせずにすぐ結果を見せる）。履歴・SRSキューへの
  /// 保存（score<70のため既存ロジックで自動的にSRS復習キューへ登録される）は
  /// 表示をブロックしないよう並行して行う。
  Future<void> _submitTimeout() async {
    if (!mounted || _grading || _feedback != null) return;
    const feedback = CompositionFeedback(
      score: 0,
      isAcceptable: false,
      corrected: '',
      explanationJa: _timeoutExplanation,
      comparisonJa: '',
    );
    setState(() {
      _feedback = feedback;
      _gradedSpoken = '';
    });

    final sentence = _current;
    final result = DrillResult(
      id: const Uuid().v4(),
      sentenceId: sentence.id,
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

  /// 問題表示時の自動録音開始。
  ///
  /// 一度失敗した（[_speechUnavailable]）場合は問題ごとにSnackBarを
  /// 出し続けないようスキップする（「録り直す」から再試行できる）。
  Future<void> _autoStartRecording() async {
    if (!mounted || _speechUnavailable || _recording) return;
    await _startRecording();
  }

  Future<void> _startRecording() async {
    // 録り直し＝新しいテイクなので、前回の文字起こしはクリアする。
    setState(() => _spoken = '');
    try {
      // 部分認識テキストは表示しない（画面は日本語文・残り時間・停止ボタンのみ）
      await _speechInput.start(onPartial: (_) {});
      setState(() {
        _recording = true;
        _speechUnavailable = false;
      });
    } on SpeechInputException catch (e) {
      _speechUnavailable = true;
      _showSnack(e.message);
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    setState(() {
      _recording = false;
      _processingSpeech = true;
    });
    try {
      final text = await _speechInput.stop();
      if (!mounted) return;
      setState(() => _spoken = text);
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
    } on GeminiException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _processingSpeech = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

    // 録音中なら「答え合わせ」一押しで聞き取り終了→文字起こしまで行い、
    // そのまま採点に進む。
    if (_recording) {
      await _stopRecording();
      if (!mounted) return;
    }

    final spoken = _spoken.trim();
    if (spoken.isEmpty) {
      _showSnack('発話を聞き取れませんでした。「録り直す」からもう一度話してください。');
      return;
    }

    setState(() => _grading = true);
    final gemini = context.read<GeminiService>();
    final sentence = _current;
    try {
      final feedback = await gemini.correctComposition(
        ja: sentence.ja,
        modelAnswer: sentence.en,
        spoken: spoken,
      );
      final result = DrillResult(
        id: const Uuid().v4(),
        sentenceId: sentence.id,
        level: sentence.level,
        spoken: spoken,
        timestamp: DateTime.now(),
        feedback: feedback,
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
      _timer?.cancel();
      setState(() {
        _feedback = feedback;
        _gradedSpoken = spoken;
        _grading = false;
      });
    } on GeminiException catch (e) {
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

  void _next() {
    final feedback = _feedback;
    if (feedback != null) {
      _entries.add(DrillSummaryEntry(ja: _current.ja, score: feedback.score));
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
      _spoken = '';
      _feedback = null;
      _gradedSpoken = null;
    });
    _startTimer();
    // 次の問題でも表示と同時に音声入力を自動開始する
    _autoStartRecording();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.isReview ? '復習' : '口頭英作文'} '
          '(${_index + 1}/${widget.sentences.length})',
        ),
      ),
      body: SafeArea(
        child: feedback == null
            ? _buildQuestion(context)
            : DrillFeedbackView(
                sentence: _current,
                spoken: _gradedSpoken ?? '',
                feedback: feedback,
                onNext: _next,
              ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final timeUp = _secondsLeft <= 0;
    final urgent = _secondsLeft <= _urgentSeconds;
    final timerColor = urgent ? AppColors.scoreLow : AppColors.primary;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1,
                  end: _secondsLeft / widget.questionSeconds,
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.linear,
                builder: (context, value, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(timerColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '残り$_secondsLeft秒',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: timeUp ? AppColors.scoreLow : timerColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillChip(
                      label:
                          'TOEIC ${_current.level}点台・'
                          '${themeLabel(_current.theme)}',
                      selected: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _current.ja,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 操作ボタンは下部の「答え合わせ」1つだけ（録音停止＝採点）。
              // ここは録音状態の表示のみ：録音中はインジケーター、文字起こし中は
              // スピナー、失敗して録音が止まっている時だけ録り直しの導線を出す。
              Center(
                child: _processingSpeech
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : _recording
                    ? const RecordingIndicator()
                    : TextButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.mic),
                        label: const Text('録り直す'),
                      ),
              ),
            ],
          ),
        ),
        BottomCtaBar(
          child: PrimaryButton(
            // 録音中は「停止＝採点」であることをラベルでも明示する
            label: _recording ? '停止して答え合わせ' : '答え合わせ',
            onPressed: _submit,
            // 文字起こし（_processingSpeech）→採点（_grading）まで一続きの
            // 処理として、ボタンはその間ずっとローディング表示にする。
            loading: _grading || _processingSpeech,
          ),
        ),
      ],
    );
  }
}
