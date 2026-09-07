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
import '../../content/domain/topic.dart';
import '../../settings/presentation/settings_screen.dart';
import 'monologue_feedback_screen.dart';
import 'monologue_speak_store.dart';

/// 独り言のスピーキング画面。進行は [MonologueSpeakStore] が担う。
///
/// 「フィードバックを見る」（または録音中の時間切れ）で、録音サービスの
/// 所有権ごと段階表示のフィードバック画面へ即遷移し、文字起こし→添削の
/// 進行に合わせてコンテンツが埋まっていく。
class MonologueSpeakScreen extends StatefulWidget {
  const MonologueSpeakScreen({
    super.key,
    required this.topic,
    required this.seconds,
  });

  /// 出題されたお題
  final Topic topic;

  /// 選択された発話時間（秒）
  final int seconds;

  @override
  State<MonologueSpeakScreen> createState() => _MonologueSpeakScreenState();
}

class _MonologueSpeakScreenState extends State<MonologueSpeakScreen> {
  late final MonologueSpeakStore _store;
  late final void Function() _unsubscribe;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(
      context,
    ).monologueSpeak(topic: widget.topic, seconds: widget.seconds);
    _unsubscribe = _store.notice.subscribe(_onNotice);
  }

  @override
  void dispose() {
    _unsubscribe();
    _store.dispose();
    super.dispose();
  }

  void _onNotice(MonologueSpeakNotice? notice) {
    if (notice == null || !mounted) return;
    switch (notice) {
      case MonologueSpeakFailureNotice(:final failure):
        _showSnack(context.l10n.failureMessage(failure.kind.name));
      case MonologueTimeUpNotice():
        _showSnack(context.l10n.timeUpBeforeSpeaking);
      case MonologueApiKeyMissingNotice():
        _showApiKeyDialog();
      case MonologueHandOffNotice(:final speechInput):
        Navigator.of(context).pushReplacement(
          appRoute(
            builder: (_) => MonologueFeedbackScreen(
              topic: widget.topic,
              seconds: widget.seconds,
              speechInput: speechInput,
            ),
          ),
        );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
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
      appBar: AppBar(title: Text(l10n.monologueTitle(_store.profile.code))),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final recording = _store.recording.value;
            final ratio = _store.ratio.value;
            final urgent = _store.urgent.value;
            // pre（録音前）かどうか。円環・ゲージだけ色を落とす（お題カードは常時アクティブ）
            final pre = !recording;
            return Column(
              children: [
                // 画面上端の残り時間ゲージ（6px）。pre=#C9CCD1 / rec=オレンジ、残りわずかで赤
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: ratio),
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.speakAboutThisTopic,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.topic.ja,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  height: 1.7,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.topic.target,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: CountdownRing(
                              progress: ratio,
                              label: _formatTime(_store.secondsLeft.value),
                              recording: recording,
                              idleLabel: l10n.beforeListening,
                              dimmed: pre,
                              urgent: urgent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BottomCtaBar(
                  child: PrimaryButton(
                    // pre=話しはじめる（録音開始）/ rec=フィードバックを見る（停止＝添削）。
                    // 「録音する」という語は使わない。
                    label: recording ? l10n.seeFeedback : l10n.startSpeaking,
                    onPressed: recording
                        ? _store.submit
                        : _store.startRecording,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
