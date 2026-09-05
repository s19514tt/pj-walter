// コンストラクタの公開パラメータ名（例: drillResultsBox）と、内部実装用の
// プライベートフィールド名（_drillResultsBox）をあえて分けているため、
// initializing formalは使わない（使うとパラメータ名がprivateになり外部から渡せなくなる）。
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/drill_result.dart';
import '../models/monologue_result.dart';
import '../models/phrase.dart';
import '../models/srs_item.dart';

/// スコアがこの値未満だとSRSキューに登録される（不合格ライン）。
const _passingScore = 70;

/// SRSの段階(stage)ごとの復習間隔（日数）。stage5は卒業（キューから除外）。
const _srsIntervalDays = {0: 1, 1: 3, 2: 7, 3: 14, 4: 30};

/// 卒業（キューから除外）とみなすstage
const _graduationStage = 5;

/// 学習履歴（口頭英作文・独り言英会話の結果）、SRS復習キュー、フレーズ帳、
/// 日次学習統計を永続化するサービス。
///
/// テスト容易性のため、各Hive boxはコンストラクタ注入できる。
class HistoryService extends ChangeNotifier {
  HistoryService({
    required Box drillResultsBox,
    required Box monologueResultsBox,
    required Box srsItemsBox,
    required Box phrasesBox,
    required Box dailyStatsBox,
  }) : _drillResultsBox = drillResultsBox,
       _monologueResultsBox = monologueResultsBox,
       _srsItemsBox = srsItemsBox,
       _phrasesBox = phrasesBox,
       _dailyStatsBox = dailyStatsBox;

  final Box _drillResultsBox;
  final Box _monologueResultsBox;
  final Box _srsItemsBox;
  final Box _phrasesBox;
  final Box _dailyStatsBox;

  // --- 口頭作文 -----------------------------------------------------

  /// 口頭英作文の結果を保存する。日次統計を更新し、
  /// [updateSrs]がtrue（既定）かつスコアが70未満なら対象文をSRS復習キューに登録する。
  ///
  /// 復習ドリル（[updateSrs]がfalse）では、SRSの更新は呼び出し側が
  /// [applyReviewResult]で別途行うため、ここでは履歴・日次統計の記録のみ行う。
  Future<void> saveDrillResult(
    DrillResult result, {
    bool updateSrs = true,
  }) async {
    await _drillResultsBox.put(result.id, result.toJson());
    await _bumpDailyStats(language: result.language, drillCount: 1);
    if (updateSrs && result.feedback.score < _passingScore) {
      await _registerSrsFailure(
        sentenceId: result.sentenceId,
        language: result.language,
        level: result.level,
      );
    }
    notifyListeners();
  }

  /// 口頭英作文の結果を新しい順に返す。
  List<DrillResult> get drillHistory {
    final list = _drillResultsBox.values
        .map((e) => DrillResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // --- 独り言英会話 -----------------------------------------------------

  /// 独り言英会話の結果を保存し、日次統計を更新する。
  Future<void> saveMonologueResult(MonologueResult result) async {
    await _monologueResultsBox.put(result.id, result.toJson());
    await _bumpDailyStats(
      language: result.language,
      monologueCount: 1,
      studySeconds: result.seconds,
    );
    notifyListeners();
  }

  /// 独り言英会話の結果を新しい順に返す。
  List<MonologueResult> get monologueHistory {
    final list = _monologueResultsBox.values
        .map(
          (e) => MonologueResult.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // --- SRS -----------------------------------------------------

  /// 今日復習すべきアイテム（dueDate <= 今日、日単位比較）を、
  /// dueDateが早い順に返す。
  /// [language]を渡すとその学習言語のアイテムだけに絞る。復習セッションは
  /// 現在の学習言語のプロンプトで採点するため、言語を混ぜると別言語の文が
  /// 誤った言語で採点されてしまう。呼び出し側は必ず言語を指定すること。
  List<SrsItem> dueSrsItems({String? language}) {
    final today = _dateOnly(DateTime.now());
    final list = _srsItemsBox.values
        .map((e) => SrsItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((item) => !_dateOnly(item.dueDate).isAfter(today))
        .where((item) => language == null || item.language == language)
        .toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// 全てのSRSアイテムを返す（順不同）。
  List<SrsItem> get allSrsItems => _srsItemsBox.values
      .map((e) => SrsItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  /// 復習結果を反映する。
  ///
  /// 正解ならstageを1つ進め、次回dueDateを更新する（stage5到達で卒業しキューから削除）。
  /// 不正解ならstageを0に戻し、翌日をdueDateとする。
  Future<void> applyReviewResult(String sentenceId, bool correct) async {
    final map = _srsItemsBox.get(sentenceId) as Map?;
    if (map == null) return;
    final item = SrsItem.fromJson(Map<String, dynamic>.from(map));

    if (correct) {
      final nextStage = item.stage + 1;
      if (nextStage >= _graduationStage) {
        await _srsItemsBox.delete(sentenceId);
        notifyListeners();
        return;
      }
      final updated = item.copyWith(
        stage: nextStage,
        dueDate: _addDays(
          _dateOnly(DateTime.now()),
          _srsIntervalDays[nextStage]!,
        ),
        lastResult: true,
      );
      await _srsItemsBox.put(sentenceId, updated.toJson());
    } else {
      final updated = item.copyWith(
        stage: 0,
        dueDate: _addDays(_dateOnly(DateTime.now()), _srsIntervalDays[0]!),
        lastResult: false,
      );
      await _srsItemsBox.put(sentenceId, updated.toJson());
    }
    notifyListeners();
  }

  Future<void> _registerSrsFailure({
    required String sentenceId,
    required String language,
    required int level,
  }) async {
    final existingMap = _srsItemsBox.get(sentenceId) as Map?;
    final lapses = existingMap != null
        ? SrsItem.fromJson(Map<String, dynamic>.from(existingMap)).lapses + 1
        : 0;
    final item = SrsItem(
      sentenceId: sentenceId,
      language: language,
      level: level,
      stage: 0,
      dueDate: _addDays(_dateOnly(DateTime.now()), _srsIntervalDays[0]!),
      lapses: lapses,
      lastResult: false,
    );
    await _srsItemsBox.put(sentenceId, item.toJson());
  }

  // --- フレーズ帳 -----------------------------------------------------

  /// フレーズ帳にフレーズを追加する。
  Future<void> addPhrase(Phrase phrase) async {
    await _phrasesBox.put(phrase.id, phrase.toJson());
    notifyListeners();
  }

  /// フレーズ帳の内容を新しい順に返す。
  List<Phrase> get phrases {
    final list = _phrasesBox.values
        .map((e) => Phrase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// フレーズ帳から指定のエントリを削除する。
  Future<void> deletePhrase(String id) async {
    await _phrasesBox.delete(id);
    notifyListeners();
  }

  // --- 日次統計 -----------------------------------------------------

  /// `daily_stats` の1日分。学習言語ごとに内訳を持つ。
  ///
  /// 中国語対応より前は言語の区別が無く、1日1個のフラットなMap
  /// （`{drillCount: 3, ...}`）を保存していた。その形が来たら英語の記録と
  /// みなして読む。保存は常に言語別の形で行う。
  static Map<String, Map<String, int>> _readDay(Object? raw) {
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(raw as Map);
    if (map.values.any((v) => v is int)) {
      return {'en': _readCounters(map)};
    }
    return {
      for (final entry in map.entries)
        entry.key: _readCounters(Map<String, dynamic>.from(entry.value as Map)),
    };
  }

  static Map<String, int> _readCounters(Map<String, dynamic> map) => {
    'drillCount': (map['drillCount'] as num?)?.toInt() ?? 0,
    'monologueCount': (map['monologueCount'] as num?)?.toInt() ?? 0,
    'studySeconds': (map['studySeconds'] as num?)?.toInt() ?? 0,
  };

  static Map<String, int> _emptyCounters() => {
    'drillCount': 0,
    'monologueCount': 0,
    'studySeconds': 0,
  };

  static Map<String, int> _sum(Iterable<Map<String, int>> parts) {
    final total = _emptyCounters();
    for (final part in parts) {
      for (final key in total.keys) {
        total[key] = total[key]! + (part[key] ?? 0);
      }
    }
    return total;
  }

  /// 指定日の学習統計（drillCount / monologueCount / studySeconds）を返す。
  ///
  /// [language]を渡すとその学習言語の分だけ、省略すると全言語の合計を返す。
  Map<String, int> statsForDate(DateTime date, {String? language}) {
    final day = _readDay(_dailyStatsBox.get(_dateKey(date)));
    if (language != null) return day[language] ?? _emptyCounters();
    return _sum(day.values);
  }

  /// 指定日に学習した言語コードの一覧（学習していない日は空）。
  Set<String> languagesStudiedOn(DateTime date) {
    final day = _readDay(_dailyStatsBox.get(_dateKey(date)));
    return {
      for (final entry in day.entries)
        if (entry.value['drillCount']! + entry.value['monologueCount']! > 0)
          entry.key,
    };
  }

  /// 連続学習日数（現在のストリーク）。
  ///
  /// drillCount+monologueCount>0の日を「学習日」とし、今日または昨日を起点に
  /// 過去へ連続する学習日数を数える。今日がまだ未学習でも、昨日までが連続して
  /// いればストリークは維持される（今日中に学習すればさらに伸びる）。
  /// 今日・昨日とも未学習ならストリークは0。
  ///
  /// [language]を渡すとその言語だけで数える。省略時は言語を問わず数えるので、
  /// 言語を切り替えても通算のストリークは途切れない。
  int currentStreak({String? language}) {
    var cursor = _dateOnly(DateTime.now());
    if (!_isStudyDay(cursor, language)) {
      cursor = _addDays(cursor, -1);
      if (!_isStudyDay(cursor, language)) return 0;
    }

    var streak = 0;
    while (_isStudyDay(cursor, language)) {
      streak++;
      cursor = _addDays(cursor, -1);
    }
    return streak;
  }

  bool _isStudyDay(DateTime date, String? language) {
    final stats = statsForDate(date, language: language);
    return stats['drillCount']! + stats['monologueCount']! > 0;
  }

  /// 累計の学習統計（総ドリル数・総独り言回数・総学習秒数）。
  ///
  /// [language]を渡すとその学習言語の分だけ集計する。
  Map<String, int> totalStats({String? language}) => _sum([
    for (final value in _dailyStatsBox.values)
      if (language == null)
        _sum(_readDay(value).values)
      else
        _readDay(value)[language] ?? _emptyCounters(),
  ]);

  /// これまでに学習したことがある日数（[language]指定で言語別）。
  int studyDayCount({String? language}) {
    var days = 0;
    for (final value in _dailyStatsBox.values) {
      final day = _readDay(value);
      final stats = language == null
          ? _sum(day.values)
          : (day[language] ?? _emptyCounters());
      if (stats['drillCount']! + stats['monologueCount']! > 0) days++;
    }
    return days;
  }

  /// 直近[days]日分の日次統計を古い→新しい順で返す（欠損日は0埋め）。
  List<MapEntry<DateTime, Map<String, int>>> statsForLastDays(
    int days, {
    String? language,
  }) {
    final today = _dateOnly(DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        MapEntry(
          _addDays(today, -i),
          statsForDate(_addDays(today, -i), language: language),
        ),
    ];
  }

  Future<void> _bumpDailyStats({
    required String language,
    int drillCount = 0,
    int monologueCount = 0,
    int studySeconds = 0,
  }) async {
    final key = _dateKey(DateTime.now());
    final day = _readDay(_dailyStatsBox.get(key));
    final current = day[language] ?? _emptyCounters();
    day[language] = {
      'drillCount': current['drillCount']! + drillCount,
      'monologueCount': current['monologueCount']! + monologueCount,
      'studySeconds': current['studySeconds']! + studySeconds,
    };
    await _dailyStatsBox.put(key, day);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
}
