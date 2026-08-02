import 'package:flutter/material.dart';

import '../../models/drill_result.dart';
import '../../models/sentence.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';

/// 口頭英作文1問分のGemini添削結果表示。
///
/// スコア・合否バッジ・発話内容・修正版・模範解答（tips込み）・解説・
/// 模範解答との比較を表示し、「次へ」で次問または結果まとめへ進む。
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

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(feedback.score);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '${feedback.score}',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  feedback.isAcceptable ? '合格' : '要復習',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Section(title: 'あなたの発話', content: spoken),
        const SizedBox(height: 12),
        _Section(title: '修正版', content: feedback.corrected, accent: true),
        const SizedBox(height: 12),
        _Section(title: '模範解答', content: sentence.en, footer: sentence.tips),
        const SizedBox(height: 12),
        _Section(title: '解説', content: feedback.explanationJa),
        const SizedBox(height: 12),
        _Section(title: '模範解答との比較', content: feedback.comparisonJa),
        const SizedBox(height: 24),
        PrimaryButton(label: '次へ', onPressed: onNext),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.content,
    this.footer,
    this.accent = false,
  });

  final String title;
  final String content;
  final String? footer;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: accent ? FontWeight.bold : FontWeight.normal,
              color: accent ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(
              footer!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
