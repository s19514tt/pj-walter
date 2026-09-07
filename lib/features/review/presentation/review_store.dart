import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/sentence.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/load_review_session.dart';
import '../domain/phrase.dart';
import '../domain/phrase_repository.dart';
import '../domain/srs_item.dart';
import '../domain/srs_repository.dart';

/// 復習予定一覧で全件を個別表示する上限。超えた分は件数表示のみにする。
const upcomingListLimit = 8;

/// 復習予定（stage 0-4 の件数と、dueDate 順の先頭）。
class UpcomingReviews {
  const UpcomingReviews({
    required this.stageCounts,
    required this.shown,
    required this.remaining,
    required this.total,
  });

  /// stage 0-4（1日→3日→7日→14日→30日）ごとの件数
  final List<int> stageCounts;

  /// dueDate が早い順の先頭 [upcomingListLimit] 件
  final List<SrsItem> shown;

  /// 表示しきれなかった件数
  final int remaining;
  final int total;
}

/// 復習タブの Store。「今日の復習」「復習予定」「フレーズ帳」を派生する。
///
/// SRS・フレーズ帳・設定は Repository の signal から `computed` で派生するだけで、
/// コピーは持たない（他画面での更新が自動で反映される）。
class ReviewStore extends Store {
  ReviewStore({
    required this._srs,
    required this._phrases,
    required SettingsRepository settings,
    required this._loadReviewSession,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    profile = createComputed(() => settings.settings.value.languageProfile);
    // 復習は現在の学習言語だけを対象にする（別言語の文が現在の言語の
    // プロンプトで採点されるのを防ぐ）。
    dueItems = createComputed(() {
      _srs.items.value;
      return _srs.due(language: profile.value.code, now: _now());
    });
    allItems = createComputed(() => _srs.items.value);
    upcoming = createComputed(() {
      final items = allItems.value;
      // stage 0-4を「1日→3日→7日→14日→30日」の各間隔として件数表示する
      final counts = List<int>.filled(srsStageDays.length, 0);
      for (final item in items) {
        if (item.stage >= 0 && item.stage < counts.length) counts[item.stage]++;
      }
      final sorted = [...items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final shown = sorted.take(upcomingListLimit).toList();
      return UpcomingReviews(
        stageCounts: counts,
        shown: shown,
        remaining: sorted.length - shown.length,
        total: sorted.length,
      );
    });
    query = createSignal('');
    phraseCount = createComputed(() => _phrases.phrases.value.length);
    filteredPhrases = createComputed(() {
      final q = query.value.trim().toLowerCase();
      final all = _phrases.phrases.value;
      if (q.isEmpty) return all;
      return all
          .where(
            (p) =>
                p.target.toLowerCase().contains(q) ||
                p.ja.toLowerCase().contains(q),
          )
          .toList();
    });
    startingReview = createSignal(false);
  }

  /// stage 0-4 の復習間隔（日）。表示用
  static const srsStageDays = [1, 3, 7, 14, 30];

  final SrsRepository _srs;
  final PhraseRepository _phrases;
  final LoadReviewSession _loadReviewSession;
  final DateTime Function() _now;

  late final Computed<LanguageProfile> profile;
  late final Computed<List<SrsItem>> dueItems;
  late final Computed<List<SrsItem>> allItems;
  late final Computed<UpcomingReviews> upcoming;

  /// フレーズ帳の検索文字列
  late final Signal<String> query;
  late final Computed<int> phraseCount;
  late final Computed<List<Phrase>> filteredPhrases;

  /// 「今日の復習」の出題文を解決している最中かどうか
  late final Signal<bool> startingReview;

  void setQuery(String value) => query.value = value;

  /// 今日の復習の出題文を解決する。解決中は [startingReview] が true。
  /// 教材が見つからなければ空リスト。二重起動は空リストで弾く。
  Future<List<Sentence>> loadReviewSentences() async {
    if (startingReview.value) return const [];
    startingReview.value = true;
    try {
      return await _loadReviewSession(dueItems.peek());
    } finally {
      if (!disposed) startingReview.value = false;
    }
  }

  /// 復習セッションから戻ったら呼ぶ（開始中フラグを確実に戻す）。
  void reviewFinished() {
    if (!disposed) startingReview.value = false;
  }

  Future<void> deletePhrase(String id) => _phrases.delete(id);

  /// [dueDate]の今日からの相対日数（0 以下は「今日」扱い）。
  int daysUntil(DateTime dueDate) {
    final today = _now();
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
  }
}
