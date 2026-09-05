import 'package:flutter/material.dart';

import '../../models/drill_result.dart';
import '../../models/sentence.dart';
import '../../models/token_usage.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../utils/word_diff.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/speak_button.dart';
import '../../widgets/stat_badge.dart';

/// 口頭英作文1問分のGemini添削結果の段階表示。
///
/// 「採点する」押下と同時にこのビューへ遷移し、3段階でコンテンツを埋める：
/// - stage 0（[spoken]=null・[feedback]=null）: 全カードがスケルトン
/// - stage 1（[spoken]あり・[feedback]=null）: 文字起こしカードだけ素の
///   認識テキスト（差分ハイライト・凡例は出さない）。他はスケルトン＋バッジ
/// - stage 2（[feedback]あり）: 全部実データ。フッターの次アクションが出現
///
/// feedbackの`corrected`が空文字（時間切れで回答できなかった場合）は
/// 「あなたの発話」差分カードを非表示にし、模範解答＋tipsを主役として表示する。
///
/// スコアカードの直下には出題された日本語文（問題文）を常に表示する。採点を
/// 待っている間も何に答えたのかを見失わないようにするため、段階表示の対象外。
/// 「修正版」「模範解答」には[SpeakButton]を置き、[ttsService]（Gemini TTS）で
/// 学習言語の発音を確認できるようにする。読み上げで消費したトークンは
/// [onSpeechUsage]で親に渡し、まとめ画面のコスト表示に含める。
class DrillFeedbackView extends StatefulWidget {
  const DrillFeedbackView({
    super.key,
    required this.sentence,
    required this.spoken,
    required this.feedback,
    required this.onNext,
    required this.onRetry,
    required this.ttsService,
    this.onSpeechUsage,
    this.isLast = false,
  });

  /// 出題されたSentence
  final Sentence sentence;

  /// ユーザーの発話の文字起こし。nullは音声認識の完了待ち（stage 0）。
  final String? spoken;

  /// Geminiによる添削結果。nullは採点待ち（stage 0〜1）。
  final CompositionFeedback? feedback;

  /// 「次の問題へ」（最終問題では「結果を見る」）タップ時のコールバック
  final VoidCallback onNext;

  /// 「もう一度」タップ時のコールバック（同じ問題を録り直す）
  final VoidCallback onRetry;

  /// 「修正版」「模範解答」の読み上げに使う音声合成
  final TtsService ttsService;

  /// 読み上げでGeminiが消費したトークンの通知。
  /// キャッシュから再生した場合は[TokenUsage.zero]なので呼ばれない。
  final void Function(TokenUsage usage)? onSpeechUsage;

  /// 最終問題かどうか（プライマリボタンのラベルに反映）
  final bool isLast;

  @override
  State<DrillFeedbackView> createState() => _DrillFeedbackViewState();
}

class _DrillFeedbackViewState extends State<DrillFeedbackView> {
  /// いま読み上げている文。読み上げていなければnull。
  ///
  /// 「修正版」「模範解答」のどちらのボタンを停止表示にするかの判定に使う。
  String? _speaking;

  @override
  void dispose() {
    // 画面を離れた後に読み上げが続かないようにする（サービス自体の破棄は
    // 生成元のDrillScreenが行う）。
    widget.ttsService.stop();
    super.dispose();
  }

  /// [text]の読み上げをトグルする。読み上げ中の文をもう一度押すと停止する。
  Future<void> _toggleSpeak(String text) async {
    if (_speaking == text) {
      await widget.ttsService.stop();
      if (mounted) setState(() => _speaking = null);
      return;
    }
    setState(() => _speaking = text);
    try {
      final (:usage) = await widget.ttsService.speak(text);
      if (usage != TokenUsage.zero) widget.onSpeechUsage?.call(usage);
    } on TtsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      // 別の文の読み上げに切り替わっている場合は、そちらの表示を消さない。
      if (mounted && _speaking == text) setState(() => _speaking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final spoken = widget.spoken;
    final timedOut = feedback != null && feedback.corrected.isEmpty;
    var delayStep = 0;
    Widget staggered(Widget child) {
      final delay = Duration(milliseconds: 60 * delayStep);
      delayStep++;
      return _FadeInCard(delay: delay, child: child);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // スコアカード: 採点完了（stage 2）まではスケルトン
              if (feedback == null)
                const _ScoreSkeletonCard()
              else
                _ScoreCard(feedback: feedback),
              const SizedBox(height: 14),
              // 問題文は採点を待たずに出せるので、段階表示の対象にしない
              _QuestionCard(ja: widget.sentence.ja),
              const SizedBox(height: 12),
              // 文字起こしカード:
              //   stage 0 = スケルトン＋認識中バッジ
              //   stage 1 = 素の認識テキストのみ（差分・凡例なし）
              //   stage 2 = 差分ハイライト＋凡例
              if (!timedOut) ...[
                if (spoken == null)
                  const SkeletonSectionCard(
                    title: 'あなたの発話（文字起こし）',
                    badge: '認識中',
                  )
                else if (feedback == null)
                  _PlainTranscriptCard(spoken: spoken)
                else
                  staggered(
                    _DiffCard(
                      spoken: spoken,
                      corrected: feedback.corrected,
                      correctedTrailing: SpeakButton(
                        speaking: _speaking == feedback.corrected,
                        onPressed: () => _toggleSpeak(feedback.corrected),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              // 模範解答・添削コメント: 採点完了までスケルトン＋AI採点中バッジ
              if (feedback == null)
                const SkeletonSectionCard(title: '模範解答・添削コメント', badge: 'AI採点中')
              else ...[
                staggered(
                  _Section(
                    icon: Icons.menu_book_outlined,
                    title: '模範解答',
                    content: widget.sentence.target,
                    tips: widget.sentence.tips,
                    highlight: timedOut,
                    trailing: SpeakButton(
                      speaking: _speaking == widget.sentence.target,
                      onPressed: () => _toggleSpeak(widget.sentence.target),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                staggered(
                  _Section(
                    icon: Icons.lightbulb_outline,
                    title: '解説',
                    content: feedback.explanationJa,
                  ),
                ),
                if (feedback.comparisonJa.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  staggered(
                    _Section(
                      icon: Icons.compare_arrows,
                      title: '模範解答との比較',
                      content: feedback.comparisonJa,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        // フッターの次アクションは採点完了（stage 2）で出現する。
        // カードの段階表示とフッターのゲートは必ずセット（片方だけ隠さない）。
        if (feedback != null)
          BottomCtaBar(
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'もう一度',
                    onPressed: widget.onRetry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: widget.isLast ? '結果を見る' : '次の問題へ',
                    onPressed: widget.onNext,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// スコアリング＋判定＋総評のカード（stage 2）。
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.feedback});

  final CompositionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(feedback.score);
    // デザインの3段階判定。合否ライン（70点・SRS登録条件）はisAcceptableに従う
    final (verdict, verdictSurface, headline) = feedback.isAcceptable
        ? ('合格', AppColors.scoreGoodSurface, 'よくできました。この調子で次へ進みましょう。')
        : feedback.score >= 50
        ? ('あと少し', AppColors.scoreMediumSurface, '惜しい！解説を確認して仕上げましょう。')
        : ('要復習', AppColors.scoreLowSurface, '復習キューに登録されます。模範解答を確認しましょう。');
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ScoreRing(score: feedback.score, size: 116),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatBadge(
                  label: verdict,
                  surfaceColor: verdictSurface,
                  textColor: color,
                ),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// スコアカードのスケルトン（リング位置に円プレースホルダー）。
class _ScoreSkeletonCard extends StatelessWidget {
  const _ScoreSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEEF1),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(child: SkeletonParagraph(widths: [0.45, 1, 0.7])),
        ],
      ),
    );
  }
}

/// stage 1の文字起こしカード。素の認識テキストのみ（差分・凡例は出さない）。
class _PlainTranscriptCard extends StatelessWidget {
  const _PlainTranscriptCard({required this.spoken});

  final String spoken;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'あなたの発話（文字起こし）',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const ProgressBadge(label: 'AI採点中'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            spoken,
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// [delay]経過後に300msでフェード＋わずかな上方向スライドで出現するカード。
class _FadeInCard extends StatefulWidget {
  const _FadeInCard({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<_FadeInCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

/// アイコン＋ラベルの小見出し（14px bold、アイコンはオレンジ、8px間隔）。
///
/// [trailing]を渡すと行の右端に寄せて並べる（読み上げボタンなど）。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }
}

/// 出題された日本語文（問題文）のカード。
///
/// 添削結果を見ている間も何に対する回答だったのかが分かるように、
/// スコアカードのすぐ下に置く。
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.ja});

  final String ja;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(icon: Icons.help_outline, title: '問題文'),
          const SizedBox(height: 8),
          Text(
            ja,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「あなたの発話 → 修正版」を1枚のカードに統合した差分表示。
///
/// 上段に発話（削除/変更された語をグレー＋取り消し線）、下段に修正版
/// （primarySurface背景、追加/変更された語をオレンジ太字）を表示する。
/// 差分が無い（完全一致）場合は下段の代わりに「修正なし」メッセージを
/// good色（[AppColors.success]）で表示する。
class _DiffCard extends StatelessWidget {
  const _DiffCard({
    required this.spoken,
    required this.corrected,
    this.correctedTrailing,
  });

  final String spoken;
  final String corrected;

  /// 「修正版」見出しの右端に置くウィジェット（読み上げボタン）。
  /// 差分が無く修正版セクションを出さない場合は使わない。
  final Widget? correctedTrailing;

  @override
  Widget build(BuildContext context) {
    final diff = diffWords(spoken, corrected);
    final hasChanges = diff.any((s) => s.type != DiffSegmentType.same);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.record_voice_over_outlined,
            title: 'あなたの発話',
          ),
          const SizedBox(height: 8),
          _DiffText(
            segments: diff.where((s) => s.type != DiffSegmentType.added),
            changedColor: AppColors.scoreLow,
            changedBackground: AppColors.scoreLowSurface,
            changedDecoration: TextDecoration.lineThrough,
          ),
          const SizedBox(height: 16),
          if (hasChanges)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.edit,
                    title: '修正版',
                    trailing: correctedTrailing,
                  ),
                  const SizedBox(height: 8),
                  _DiffText(
                    segments: diff.where(
                      (s) => s.type != DiffSegmentType.removed,
                    ),
                    changedColor: AppColors.scoreGood,
                    changedBackground: AppColors.scoreGoodSurface,
                    changedWeight: FontWeight.bold,
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '修正なし！そのままでOKです 🎉',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendSwatch(
                fill: AppColors.scoreLowSurface,
                border: Color(0xFFF3B4B4),
                label: '削除・誤り',
              ),
              SizedBox(width: 14),
              _LegendSwatch(
                fill: AppColors.scoreGoodSurface,
                border: Color(0xFF9AD9BC),
                label: '修正版の表現',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 差分表示の凡例（色見本＋ラベル）。
class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.fill,
    required this.border,
    required this.label,
  });

  final Color fill;
  final Color border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// [DiffSegment]列を1つのテキストとして描画する。差分がある単語だけ
/// [changedColor]／[changedWeight]／[changedDecoration]を適用し、それ以外は
/// 通常のスタイルで表示する。単語間は半角スペース1つで繋ぐ。
class _DiffText extends StatelessWidget {
  const _DiffText({
    required this.segments,
    required this.changedColor,
    this.changedBackground,
    this.changedWeight = FontWeight.normal,
    this.changedDecoration,
  });

  final Iterable<DiffSegment> segments;
  final Color changedColor;
  final Color? changedBackground;
  final FontWeight changedWeight;
  final TextDecoration? changedDecoration;

  @override
  Widget build(BuildContext context) {
    final list = segments.toList();
    final spans = <InlineSpan>[];
    for (var i = 0; i < list.length; i++) {
      final segment = list[i];
      final changed = segment.type != DiffSegmentType.same;
      spans.add(
        TextSpan(
          text: segment.text,
          style: TextStyle(
            color: changed ? changedColor : AppColors.textPrimary,
            backgroundColor: changed ? changedBackground : null,
            fontWeight: changed ? changedWeight : FontWeight.normal,
            decoration: changed ? changedDecoration : null,
            decorationColor: changedColor,
          ),
        ),
      );
      if (i != list.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 15),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    this.tips,
    this.highlight = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String content;
  final String? tips;
  final bool highlight;

  /// 見出し行の右端に置くウィジェット（読み上げボタン）
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: highlight ? AppColors.primarySurface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: icon, title: title, trailing: trailing),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: highlight ? 17 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (tips != null && tips!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tips!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
