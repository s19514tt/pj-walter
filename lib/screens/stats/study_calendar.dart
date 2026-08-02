import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

const _weekdayHeaders = ['月', '火', '水', '木', '金', '土', '日'];

/// 当月の学習カレンダー（自作グリッド）。
///
/// 学習日はオレンジの丸背景、今日は枠線で強調する。前月/翌月への切替矢印付き。
class StudyCalendar extends StatelessWidget {
  const StudyCalendar({
    super.key,
    required this.displayedMonth,
    required this.isStudyDay,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  /// 表示中の月（dayは無視される）
  final DateTime displayedMonth;

  /// 指定日が学習日かどうかを判定する
  final bool Function(DateTime day) isStudyDay;

  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  List<DateTime?> _buildCells() {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month);
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    // weekday: 月=1...日=7。月曜始まりのグリッドにするための先頭の空白数。
    final leadingBlanks = firstDay.weekday - 1;

    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(displayedMonth.year, displayedMonth.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final cells = _buildCells();
    final today = DateTime.now();

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrevMonth,
                tooltip: '前月',
              ),
              Text(
                '${displayedMonth.year}年${displayedMonth.month}月',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth,
                tooltip: '翌月',
              ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final label in _weekdayHeaders)
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final cell in cells)
                cell == null
                    ? const SizedBox.shrink()
                    : Center(
                        child: _DayCell(
                          day: cell,
                          studied: isStudyDay(cell),
                          isToday: _isSameDay(cell, today),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.studied,
    required this.isToday,
  });

  final DateTime day;
  final bool studied;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: studied ? AppColors.primary : Colors.transparent,
        border: isToday
            ? Border.all(
                color: studied ? Colors.white : AppColors.primary,
                width: 1.5,
              )
            : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          color: studied ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
