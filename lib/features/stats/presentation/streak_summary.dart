import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/daily_stats.dart';

/// ストリーク大表示（🔥＋N日連続）＋累計サマリー（総ドリル数/総独り言/総学習時間）。
class StreakSummary extends StatelessWidget {
  const StreakSummary({
    super.key,
    required this.streak,
    required this.totalStats,
  });

  /// 現在の連続学習日数
  final int streak;

  /// 累計の学習量
  final DailyStats totalStats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalMinutes = totalStats.studySeconds ~/ 60;
    return Row(
      children: [
        Expanded(
          child: _StatTile(value: '$streak', label: l10n.streakDaysLabel),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${totalStats.drillCount}',
            label: l10n.totalDrills,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$totalMinutes',
            label: l10n.totalStudyMinutes,
          ),
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
