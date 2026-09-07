import 'daily_stats.dart';

/// 日次統計の全記録（`YYYY-MM-DD` → 学習言語コード → [DailyStats]）の読み取りビュー。
///
/// [StudyStatsRepository.log] が signal として公開する不変の値。ストリークや
/// 期間集計はここで計算する（Repository 実装に依存しない純粋なロジック）。
class StudyLog {
  const StudyLog(this._days);

  static const empty = StudyLog({});

  final Map<String, Map<String, DailyStats>> _days;

  /// 指定日の学習統計。[language]を渡すとその言語の分だけ、省略すると全言語の合計。
  DailyStats forDate(DateTime date, {String? language}) {
    final day = _days[dateKey(date)] ?? const {};
    if (language != null) return day[language] ?? DailyStats.zero;
    return day.values.fold(DailyStats.zero, (sum, s) => sum + s);
  }

  /// 指定日に学習した言語コードの一覧（学習していない日は空）。
  Set<String> languagesStudiedOn(DateTime date) {
    final day = _days[dateKey(date)] ?? const {};
    return {
      for (final entry in day.entries)
        if (entry.value.isStudyDay) entry.key,
    };
  }

  /// 連続学習日数（現在のストリーク）。
  ///
  /// drillCount+monologueCount>0の日を「学習日」とし、今日または昨日を起点に
  /// 過去へ連続する学習日数を数える。今日がまだ未学習でも、昨日までが連続して
  /// いればストリークは維持される。今日・昨日とも未学習ならストリークは0。
  ///
  /// [language]を渡すとその言語だけで数える。省略時は言語を問わず数えるので、
  /// 言語を切り替えても通算のストリークは途切れない。
  int currentStreak({String? language, DateTime? now}) {
    var cursor = _dateOnly(now ?? DateTime.now());
    if (!forDate(cursor, language: language).isStudyDay) {
      cursor = _addDays(cursor, -1);
      if (!forDate(cursor, language: language).isStudyDay) return 0;
    }

    var streak = 0;
    while (forDate(cursor, language: language).isStudyDay) {
      streak++;
      cursor = _addDays(cursor, -1);
    }
    return streak;
  }

  /// 累計の学習統計（総ドリル数・総独り言回数・総学習秒数）。
  DailyStats total({String? language}) {
    var sum = DailyStats.zero;
    for (final day in _days.values) {
      sum += language == null
          ? day.values.fold(DailyStats.zero, (a, b) => a + b)
          : (day[language] ?? DailyStats.zero);
    }
    return sum;
  }

  /// これまでに学習したことがある日数（[language]指定で言語別）。
  int studyDayCount({String? language}) {
    var days = 0;
    for (final day in _days.values) {
      final stats = language == null
          ? day.values.fold(DailyStats.zero, (a, b) => a + b)
          : (day[language] ?? DailyStats.zero);
      if (stats.isStudyDay) days++;
    }
    return days;
  }

  /// 直近[days]日分の日次統計を古い→新しい順で返す（欠損日は0埋め）。
  List<MapEntry<DateTime, DailyStats>> lastDays(
    int days, {
    String? language,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        MapEntry(
          _addDays(today, -i),
          forDate(_addDays(today, -i), language: language),
        ),
    ];
  }

  /// [date]に[language]の学習量[delta]を足した新しい [StudyLog]。
  StudyLog adding(DateTime date, String language, DailyStats delta) {
    final key = dateKey(date);
    final day = Map<String, DailyStats>.from(_days[key] ?? const {});
    day[language] = (day[language] ?? DailyStats.zero) + delta;
    return StudyLog({..._days, key: day});
  }

  /// `YYYY-MM-DD` 形式のキー（Hive box のキーにも使う）。
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
}
