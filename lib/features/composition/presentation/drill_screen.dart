import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/abort_session_dialog.dart';
import '../../../core/widgets/bottom_cta_bar.dart';
import '../../../core/widgets/countdown_ring.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skip_question_dialog.dart';
import '../../content/domain/sentence.dart';
import '../../settings/presentation/settings_screen.dart';
import 'drill_feedback_view.dart';
import 'drill_store.dart';
import 'drill_summary_screen.dart';

/// 口頭作文ドリルの進行画面。
///
/// 進行は [DrillStore] が担い、この画面は状態を描画し、Store の
/// [DrillStore.notice]（SnackBar・ダイアログ・画面遷移）に反応する。
/// 画面の要素は日本語文・残り時間・主ボタン（答える／採点する）と
/// 「わからないので飛ばす」（確認ダイアログ付き）だけ。
class DrillScreen extends StatefulWidget {
  const DrillScreen({
    super.key,
    required this.sentences,
    required this.level,
    required this.theme,
    this.isReview = false,
    this.questionSeconds = DrillStore.defaultQuestionSeconds,
  });

  /// 出題文一覧（すでにランダム選出済み）
  final List<Sentence> sentences;

  /// デッキレベル（「もう一度」の再出題に使用)。復習モードでは未使用。
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）。復習モードでは未使用。
  final String? theme;

  /// 復習モードかどうか。全問終了後はまとめ画面へ行かず呼び出し元へ戻る。
  final bool isReview;

  /// 1問あたりの制限時間（秒）。テスト用。
  final int questionSeconds;

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  late final DrillStore _store;
  late final void Function() _unsubscribe;
  bool _storeCreated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store に渡す文言（ARB）とロケールは InheritedWidget 由来なので、initState ではなく
    // 最初の didChangeDependencies で組み立てる（DESIGN.md「signals のライフサイクル規約」）。
    if (_storeCreated) return;
    _storeCreated = true;
    final l10n = context.l10n;
    _store = StoreFactory.of(context).drill(
      sentences: widget.sentences,
      level: widget.level,
      theme: widget.theme,
      isReview: widget.isReview,
      uiLocale: Localizations.localeOf(context).toLanguageTag(),
      texts: DrillTexts(
        timeoutExplanation: l10n.timeoutExplanation,
        skipExplanation: l10n.skipExplanation,
      ),
      questionSeconds: widget.questionSeconds,
    );
    _unsubscribe = _store.notice.subscribe(_onNotice);
  }

  @override
  void dispose() {
    _unsubscribe();
    _store.dispose();
    super.dispose();
  }

  void _onNotice(DrillNotice? notice) {
    if (notice == null || !mounted) return;
    switch (notice) {
      case DrillFailureNotice(:final failure, :final retryable):
        _showSnack(
          context.l10n.failureMessage(failure.kind.name),
          retry: retryable,
        );
      case DrillEmptyTranscriptNotice():
        _showSnack(context.l10n.emptyTranscript);
      case DrillApiKeyMissingNotice():
        _showApiKeyDialog();
      case DrillSessionFinishedNotice(:final entries):
        if (widget.isReview) {
          // 復習セッションは複数レベル・テーマの文が混在しうるため、通常モード専用の
          // 「もう一度」を持つまとめ画面は使わず、呼び出し元（復習タブ）へ戻る。
          Navigator.of(context).pop();
          return;
        }
        Navigator.of(context).pushReplacement(
          appRoute(
            builder: (_) => DrillSummaryScreen(
              level: widget.level,
              theme: widget.theme,
              entries: entries,
            ),
          ),
        );
    }
  }

  void _showSnack(String message, {bool retry = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retry
            ? SnackBarAction(
                label: context.l10n.retry,
                onPressed: _store.submit,
              )
            : null,
      ),
    );
  }

  void _showApiKeyDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.apiKeyMissingTitle),
        content: Text(l10n.apiKeyMissingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const SettingsScreen()));
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  /// 「わからないので飛ばす」: 確認ダイアログのうえで Store に飛ばしを頼む。
  Future<void> _skipQuestion() async {
    if (_store.resultMode.peek()) return;
    final skip = await confirmSkipQuestion(context);
    if (!skip || !mounted) return;
    await _store.skip();
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReview
              ? l10n.review
              : l10n.compositionTitle(_store.profile.code),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SignalBuilder(
                builder: (context) => Text(
                  l10n.questionProgress(
                    _store.index.value + 1,
                    widget.sentences.length,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        // 「採点する」押下と同時に段階表示の結果ビューへ切り替える
        // （スケルトン→文字起こし→採点結果と埋まっていく）。
        child: SignalBuilder(
          builder: (context) => _store.resultMode.value
              ? DrillFeedbackView(
                  sentence: _store.current.value,
                  profile: _store.profile,
                  spoken: _store.stagedSpoken.value,
                  spokenReading: _store.stagedReading.value,
                  feedback: _store.feedback.value,
                  skipped: _store.skipped.value,
                  onNext: _store.next,
                  onRetry: _store.retryCurrent,
                  ttsService: _store.tts,
                  onSpeechUsage: _store.addSpeechUsage,
                  isLast: _store.isLast.value,
                )
              : _buildQuestion(context),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final l10n = context.l10n;
    final recording = _store.recording.value;
    final secondsLeft = _store.secondsLeft.value;
    // pre（録音前）かどうか。円環・ゲージだけ色を落とす（問題文カードは常時アクティブ）
    final pre = !recording;
    final urgent = _store.urgent.value;
    final progress = _store.progress.value;
    return Column(
      children: [
        // 画面上端の残り時間ゲージ（6px）。pre=#C9CCD1 / rec=オレンジ、残り5秒以下で赤
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress),
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
                        l10n.translateThisInto(
                          l10n.languageName(_store.profile.code),
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _store.current.value.ja,
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
                      progress: progress,
                      label: '$secondsLeft',
                      recording: recording,
                      idleLabel: l10n.beforeListening,
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
            label: recording ? l10n.grade : l10n.answer,
            onPressed: recording ? _store.submit : _store.startRecording,
          ),
        ),
      ],
    );
  }
}

/// 「わからないので飛ばす」導線（下線付きのテキストリンク）。
///
/// 主ボタン（答える／採点する）より弱く見せるため、グレー文字＋薄いグレーの
/// 下線にしている。hoverでは背景を敷かず、デザインどおり文字と下線が濃くなる
/// だけにする（面で光ると主ボタンのように見えてしまうため）。
///
/// 下線は[TextDecoration.underline]ではなく下ボーダーで引く。デザインは
/// `text-underline-offset:4px`で文字から離した下線（ベースラインの約6px下）
/// だが、Flutterの下線はフォントの下線位置に密着し、オフセットを指定できないため。
class _SkipQuestionButton extends StatefulWidget {
  const _SkipQuestionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SkipQuestionButton> createState() => _SkipQuestionButtonState();
}

class _SkipQuestionButtonState extends State<_SkipQuestionButton> {
  static const _label = Color(0xFF5F6368);
  static const _labelHovered = Color(0xFF212121);
  static const _line = Color(0xFFB9BDC4);
  static const _lineHovered = Color(0xFF757575);

  // hover は描画都合のローカル状態
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TextButton(
        onPressed: widget.onPressed,
        style:
            TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ).copyWith(
              // 背景のハイライトは一切出さない。stateごとにnullを返すと
              // InkWellがテーマ既定のhighlightColorにフォールバックして
              // 背景が出てしまうので、明示的に透明を渡す。
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
        child: Container(
          // 文字ボックス（fontSize 13・height 1 なので高さ13）の下端から4px下に
          // 1pxの線。ブラウザで`text-underline-offset:4px`と重ねて実測した値。
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _hovered ? _lineHovered : _line),
            ),
          ),
          child: Text(
            context.l10n.skipQuestionLink,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1,
              color: _hovered ? _labelHovered : _label,
            ),
          ),
        ),
      ),
    );
  }
}
