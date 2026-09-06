import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/section_header.dart';
import 'history_section.dart';
import 'stats_store.dart';
import 'streak_summary.dart';
import 'study_calendar.dart';
import 'weekly_chart.dart';

/// 記録タブ。ストリーク・累計サマリー・直近7日のグラフ・学習カレンダー・
/// 添削履歴を表示する。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).stats();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStats)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SignalBuilder(
            builder: (context) => StreakSummary(
              streak: _store.streak.value,
              totalStats: _store.totalStats.value,
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.last7Days),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) => WeeklyChart(stats: _store.lastWeek.value),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.studyCalendar),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) => StudyCalendar(
              displayedMonth: _store.displayedMonth.value,
              today: _store.today,
              isStudyDay: _store.isStudyDay,
              onPrevMonth: () => _store.changeMonth(-1),
              onNextMonth: () => _store.changeMonth(1),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.correctionHistory),
          const SizedBox(height: 12),
          HistorySection(store: _store),
        ],
      ),
    );
  }
}
