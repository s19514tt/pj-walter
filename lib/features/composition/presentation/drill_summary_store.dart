import '../../../core/domain/gemini_pricing.dart';
import '../../../core/state/store.dart';
import '../../content/domain/content_repository.dart';
import '../../content/domain/sentence.dart';
import '../../review/domain/srs_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/drill_question_selector.dart';
import '../domain/drill_session.dart';

/// まとめ画面の Store。平均スコア・正答数・トークン使用量を集計し、
/// 「もう一度」で同条件の新しい出題文を選ぶ。
class DrillSummaryStore extends Store {
  DrillSummaryStore({
    required this._content,
    required this._settings,
    required this.level,
    required this.theme,
    required List<DrillSummaryEntry> entries,
    GeminiPricing? pricing,
    this._selector = const DrillQuestionSelector(),
    DateTime Function()? now,
  }) : entries = List.unmodifiable(entries),
       pricing = pricing ?? GeminiPricing.forDate((now ?? DateTime.now)());

  final ContentRepository _content;
  final SettingsRepository _settings;
  final DrillQuestionSelector _selector;

  /// デッキレベル（「もう一度」の再出題に使用）
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）
  final String? theme;

  /// 問題ごとの結果一覧
  final List<DrillSummaryEntry> entries;

  /// コスト計算に使う単価
  final GeminiPricing pricing;

  DrillQuestionUsage get totalUsage =>
      entries.fold(DrillQuestionUsage.zero, (sum, entry) => sum + entry.usage);

  int get averageScore {
    if (entries.isEmpty) return 0;
    final total = entries.map((e) => e.score).reduce((a, b) => a + b);
    return (total / entries.length).round();
  }

  int get passingCount => entries.where((e) => e.score >= passingScore).length;

  /// 復習キューに登録された（スコアが合格ライン未満の）問題数
  int get srsCount => entries.where((e) => e.score < passingScore).length;

  /// 同じレベル・テーマで新しい出題文を選ぶ。
  Future<List<Sentence>> retry() async {
    final sentences = await _content.sentences(
      profile: _settings.settings.peek().languageProfile,
      level: level,
      theme: theme,
    );
    return _selector.select(sentences);
  }
}
