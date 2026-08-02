import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

/// 直近N日間の学習量（ドリル＋独り言の合計件数）を表す棒グラフカード。
///
/// データが全て0でも落ちないよう[maxY]を最低4に固定する。
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.stats});

  /// 古い→新しい順の(日付, 統計)。[HistoryService.statsForLastDays]の戻り値。
  final List<MapEntry<DateTime, Map<String, int>>> stats;

  @override
  Widget build(BuildContext context) {
    final counts = [
      for (final entry in stats)
        (entry.value['drillCount'] ?? 0) + (entry.value['monologueCount'] ?? 0),
    ];
    final maxCount = counts.isEmpty
        ? 0
        : counts.reduce((a, b) => a > b ? a : b);
    final maxY = maxCount < 4 ? 4.0 : (maxCount + 1).toDouble();

    return AppCard(
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: const BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => _bottomTitle(value, meta),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < counts.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: counts[i].toDouble(),
                      color: AppColors.primary,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= stats.length) return const SizedBox.shrink();
    final label = _weekdayLabels[stats[index].key.weekday - 1];
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
