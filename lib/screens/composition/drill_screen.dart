import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/drill_result.dart';
import '../../models/pronunciation_feedback.dart';
import '../../models/sentence.dart';
import '../../services/gemini_service.dart';
import '../../services/history_service.dart';
import '../../services/pronunciation_assessor.dart';
import '../../services/settings_service.dart';
import '../../services/speech_input_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../utils/theme_labels.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/mic_button.dart';
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
/// [sentences]を1問ずつ出題する。マイクボタンで[SpeechInputService]による
/// 音声入力を行い（利用不可時は手入力にフォールバック）、「答え合わせ」で
/// Geminiに添削させる。音声入力で回答した場合は録音データを保持し、添削と
/// 並列で[PronunciationAssessor]による発音評価も行う（失敗しても添削は表示する）。
/// 制限時間内に回答できなかった場合は自動的に採点処理
/// （回答があれば自動答え合わせ、無ければ時間切れ扱い）を行う。
/// 全問終了後は[DrillSummaryScreen]へ遷移する。
class DrillScreen extends StatefulWidget {
  const DrillScreen({
    super.key,
    required this.sentences,
    required this.level,
    required this.theme,
    this.isReview = false,
    this.speechInputService,
    this.pronunciationAssessor,
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

  /// テスト注入用。省略時は[GeminiPronunciationAssessor]を自動生成する。
  final PronunciationAssessor? pronunciationAssessor;

  /// 1問あたりの制限時間（秒）。テスト注入用で、省略時は[_questionSeconds]（30秒）。
  final int questionSeconds;

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  late final SpeechInputService _speechInput;
  late final PronunciationAssessor _assessor;
  final _answerController = TextEditingController();
  final _entries = <DrillSummaryEntry>[];

  /// 直近の音声入力の録音データ（発音評価用）。手入力のみの場合はnull
  Uint8List? _audioBytes;
  String? _audioMimeType;

  int _index = 0;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _recording = false;
  bool _processingSpeech = false;
  String _partialText = '';
  bool _grading = false;
  CompositionFeedback? _feedback;
  PronunciationFeedback? _pronunciation;
  String? _gradedSpoken;

  Sentence get _current => widget.sentences[_index];

  @override
  void initState() {
    super.initState();
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(geminiService: context.read<GeminiService>());
    _assessor =
        widget.pronunciationAssessor ??
        GeminiPronunciationAssessor(
          geminiService: context.read<GeminiService>(),
        );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
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
    if (_recording) {
      await _stopRecording();
    }
    if (!mounted || _grading || _feedback != null) return;
    if (_answerController.text.trim().isNotEmpty) {
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

  Future<void> _toggleRecording() =>
      _recording ? _stopRecording() : _startRecording();

  Future<void> _startRecording() async {
    setState(() {
      _partialText = '';
      _audioBytes = null;
      _audioMimeType = null;
    });
    try {
      await _speechInput.start(
        onPartial: (text) => setState(() => _partialText = text),
      );
      setState(() => _recording = true);
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _recording = false;
      _processingSpeech = true;
    });
    try {
      final result = await _speechInput.stop();
      if (!mounted) return;
      setState(() {
        _answerController.text = result.text;
        _audioBytes = result.audioBytes;
        _audioMimeType = result.mimeType;
        _partialText = '';
      });
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
    if (!mounted || _grading) return;
    final spoken = _answerController.text.trim();
    if (spoken.isEmpty) return;

    final settings = context.read<SettingsService>();
    if (!settings.hasApiKey) {
      _showApiKeyDialog();
      return;
    }

    setState(() => _grading = true);
    final gemini = context.read<GeminiService>();
    final sentence = _current;
    try {
      // 添削と発音評価は独立なので並列に投げ、添削の完了を待ってから
      // 発音評価の結果を回収する。発音評価の失敗は添削の失敗にしない。
      final feedbackFuture = gemini.correctComposition(
        ja: sentence.ja,
        modelAnswer: sentence.en,
        spoken: spoken,
      );
      final pronunciationFuture = _assessPronunciation(
        spoken: spoken,
        modelAnswer: sentence.en,
      );
      final feedback = await feedbackFuture;
      final (pronunciation, pronunciationError) = await pronunciationFuture;
      final result = DrillResult(
        id: const Uuid().v4(),
        sentenceId: sentence.id,
        level: sentence.level,
        spoken: spoken,
        timestamp: DateTime.now(),
        feedback: feedback,
        pronunciation: pronunciation,
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
        _pronunciation = pronunciation;
        _gradedSpoken = spoken;
        _grading = false;
      });
      if (pronunciationError != null) {
        _showSnack('発音評価を取得できませんでした（$pronunciationError）');
      }
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _grading = false);
      _showRetrySnack(e.message);
    }
  }

  /// 録音データがあれば発音評価を行う。
  ///
  /// 戻り値は（評価結果, エラーメッセージ）のペア。録音が無い（手入力回答）
  /// 場合は(null, null)、評価に失敗した場合は(null, 日本語メッセージ)を返し、
  /// 例外は外へ投げない。
  Future<(PronunciationFeedback?, String?)> _assessPronunciation({
    required String spoken,
    required String modelAnswer,
  }) async {
    final audioBytes = _audioBytes;
    final mimeType = _audioMimeType;
    if (audioBytes == null || mimeType == null) return (null, null);
    try {
      final feedback = await _assessor.assess(
        audioBytes: audioBytes,
        mimeType: mimeType,
        spokenText: spoken,
        modelAnswer: modelAnswer,
      );
      return (feedback, null);
    } on GeminiException catch (e) {
      return (null, e.message);
    } catch (_) {
      return (null, '不明なエラー');
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
      _entries.add(
        DrillSummaryEntry(
          ja: _current.ja,
          score: feedback.score,
          pronunciationScore: _pronunciation?.score,
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
      _answerController.clear();
      _feedback = null;
      _pronunciation = null;
      _gradedSpoken = null;
      _partialText = '';
      _audioBytes = null;
      _audioMimeType = null;
    });
    _startTimer();
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
                pronunciation: _pronunciation,
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
              Center(
                child: Column(
                  children: [
                    MicButton(
                      recording: _recording,
                      processing: _processingSpeech,
                      onTap: _toggleRecording,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'タップして話す / もう一度タップで確定',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_recording || _partialText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _partialText.isEmpty ? '聞き取り中…' : _partialText,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _answerController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '英語で回答',
                  hintText: 'マイクで話すか、直接入力してください',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        BottomCtaBar(
          child: PrimaryButton(
            label: '答え合わせ',
            onPressed: _submit,
            loading: _grading,
          ),
        ),
      ],
    );
  }
}
