import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// ストリーク大表示（🔥＋N日連続）＋累計サマリー（総ドリル数/総独り言/総学習時間）。
class StreakSummary extends StatelessWidget {
  const StreakSummary({
    super.key,
    required this.streak,
    required this.totalStats,
  });

  /// 現在の連続学習日数
  final int streak;

  /// [HistoryService.totalStats]の戻り値（drillCount/monologueCount/studySeconds）
  final Map<String, int> totalStats;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (totalStats['studySeconds'] ?? 0) ~/ 60;
    return Row(
      children: [
        Expanded(
          child: _StatTile(value: '$streak', label: '連続日数'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${totalStats['drillCount'] ?? 0}',
            label: '総ドリル数',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(value: '$totalMinutes', label: '総学習分'),
        ),
      ],
    );
  }
}

/// 記録タブ上部の統計タイル（900ウェイトのオレンジ数値＋ラベル）。
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
