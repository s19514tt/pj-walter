import 'package:flutter/material.dart';

import '../../models/drill_result.dart';
import '../../models/sentence.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../utils/word_diff.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/stat_badge.dart';

/// 口頭英作文1問分のGemini添削結果表示。
///
/// スコアリング・合否バッジ・修正版（最重要）・発話内容・模範解答（tips込み）・
/// 解説・模範解答との比較を表示し、「次へ」で次問または結果まとめへ進む。
///
/// [feedback.corrected]が空文字（時間切れで回答できなかった場合）は
/// 「あなたの発話」「修正版」セクションを非表示にし、模範解答＋tipsを
/// 主役として表示する。
class DrillFeedbackView extends StatelessWidget {
  const DrillFeedbackView({
    super.key,
    required this.sentence,
    required this.spoken,
    required this.feedback,
    required this.onNext,
  });

  /// 出題されたSentence
  final Sentence sentence;

  /// ユーザーが回答として提出した発話（音声認識結果 or 手入力）
  final String spoken;

  /// Geminiによる添削結果
  final CompositionFeedback feedback;

  /// 「次へ」タップ時のコールバック
  final VoidCallback onNext;

  bool get _timedOut => feedback.corrected.isEmpty;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(feedback.score);
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
              Center(
                child: Column(
                  children: [
                    ScoreRing(score: feedback.score),
                    const SizedBox(height: 12),
                    StatBadge(
                      label: feedback.isAcceptable ? '合格 🎉' : '要復習',
                      surfaceColor: feedback.isAcceptable
                          ? AppColors.scoreGoodSurface
                          : AppColors.scoreMediumSurface,
                      textColor: color,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_timedOut) ...[
                staggered(
                  _DiffCard(spoken: spoken, corrected: feedback.corrected),
                ),
                const SizedBox(height: 12),
              ],
              staggered(
                _Section(
                  icon: Icons.menu_book_outlined,
                  title: '模範解答',
                  content: sentence.target,
                  reading: sentence.reading,
                  tips: sentence.tips,
                  highlight: _timedOut,
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
          ),
        ),
        BottomCtaBar(
          child: PrimaryButton(label: '次へ', onPressed: onNext),
        ),
      ],
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
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
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
      ],
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
  const _DiffCard({required this.spoken, required this.corrected});

  final String spoken;
  final String corrected;

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
            changedColor: AppColors.textSecondary,
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
                  const _SectionLabel(icon: Icons.edit, title: '修正版'),
                  const SizedBox(height: 8),
                  _DiffText(
                    segments: diff.where(
                      (s) => s.type != DiffSegmentType.removed,
                    ),
                    changedColor: AppColors.primary,
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
        ],
      ),
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
    this.changedWeight = FontWeight.normal,
    this.changedDecoration,
  });

  final Iterable<DiffSegment> segments;
  final Color changedColor;
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
    this.reading,
    this.tips,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String content;

  /// [content]の発音表記（中国語のピンインなど）。無い言語ではnull。
  final String? reading;
  final String? tips;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: highlight ? AppColors.primarySurface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: icon, title: title),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: highlight ? 17 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (reading != null && reading!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reading!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
