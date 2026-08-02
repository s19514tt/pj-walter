import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/drill_question_selector.dart';
import '../../services/sentence_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import 'drill_screen.dart';

/// ドリル1問分の結果概要（まとめ画面表示用）。
class DrillSummaryEntry {
  const DrillSummaryEntry({required this.ja, required this.score});

  /// 出題された日本語文
  final String ja;

  /// その問のスコア
  final int score;
}

/// 口頭英作文ドリルのセッション終了後のまとめ画面。
///
/// 平均スコアと問題ごとの結果一覧を表示し、「もう一度」で同条件の
/// 新しい10問へ、「終了」でデッキ選択画面へ戻る。
class DrillSummaryScreen extends StatelessWidget {
  const DrillSummaryScreen({
    super.key,
    required this.level,
    required this.theme,
    required this.entries,
  });

  /// TOEICレベル（「もう一度」の再出題に使用）
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）
  final String? theme;

  /// 問題ごとの結果一覧
  final List<DrillSummaryEntry> entries;

  double get _averageScore {
    if (entries.isEmpty) return 0;
    final total = entries.map((e) => e.score).reduce((a, b) => a + b);
    return total / entries.length;
  }

  Future<void> _retry(BuildContext context) async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(level: level, theme: theme);
    const selector = DrillQuestionSelector();
    final selected = selector.select(sentences);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            DrillScreen(sentences: selected, level: level, theme: theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final average = _averageScore.round();
    return Scaffold(
      appBar: AppBar(title: const Text('結果まとめ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const Text(
                  '平均スコア',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '$average',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: scoreColor(average),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < entries.length; i++) ...[
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i + 1}. ${entries[i].ja}',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entries[i].score}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scoreColor(entries[i].score),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'もう一度', onPressed: () => _retry(context)),
          const SizedBox(height: 12),
          SecondaryButton(
            label: '終了',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
