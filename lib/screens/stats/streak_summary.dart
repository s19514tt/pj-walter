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
    return Column(
      children: [
        AppCard(
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak日連続',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak > 0 ? '学習を継続しています' : '今日から始めましょう',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatMiniCard(
                icon: Icons.edit_note,
                label: '総ドリル数',
                value: '${totalStats['drillCount'] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatMiniCard(
                icon: Icons.mic,
                label: '総独り言',
                value: '${totalStats['monologueCount'] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatMiniCard(
                icon: Icons.schedule,
                label: '総学習時間',
                value: '$totalMinutes分',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
