import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../widgets/section_header.dart';
import 'stats/history_section.dart';
import 'stats/streak_summary.dart';
import 'stats/study_calendar.dart';
import 'stats/weekly_chart.dart';

const _weeklyChartDays = 7;

/// 記録タブ。ストリーク・累計サマリー・直近7日のグラフ・学習カレンダー・
/// 添削履歴を表示する。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
  }

  bool _isStudyDay(HistoryService history, DateTime day) {
    final stats = history.statsForDate(day);
    return (stats['drillCount'] ?? 0) + (stats['monologueCount'] ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();

    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreakSummary(
            streak: history.currentStreak(),
            totalStats: history.totalStats(),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '直近7日の学習量'),
          const SizedBox(height: 12),
          WeeklyChart(stats: history.statsForLastDays(_weeklyChartDays)),
          const SizedBox(height: 24),
          const SectionHeader(title: '学習カレンダー'),
          const SizedBox(height: 12),
          StudyCalendar(
            displayedMonth: _displayedMonth,
            isStudyDay: (day) => _isStudyDay(history, day),
            onPrevMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '添削履歴'),
          const SizedBox(height: 12),
          HistorySection(
            drillHistory: history.drillHistory,
            monologueHistory: history.monologueHistory,
          ),
        ],
      ),
    );
  }
}
