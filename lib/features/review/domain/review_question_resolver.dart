import '../../content/domain/sentence.dart';
import 'srs_item.dart';

/// 復習セッションの出題文解決ロジック。
///
/// [SrsItem]はsentenceIdしか持たないため、実際に出題するには対応する
/// [Sentence]を教材から引き当てる必要がある。教材から見つからないアイテム
/// （教材が更新され該当文が削除された場合など）はスキップし、dueDateが
/// 古い順に最大[limit]件を返す。
class ReviewQuestionResolver {
  const ReviewQuestionResolver({this.limit = 10});

  /// 1回の復習セッションで出題する最大件数
  final int limit;

  /// [items]をdueDateが古い順に並べ替え、[sentencesForDeck]で言語×レベルごとの
  /// 教材をロードしてsentenceIdから[Sentence]を解決する。
  ///
  /// 言語×レベルごとのロード結果はこの呼び出し内でキャッシュするため、
  /// 同じデッキのアイテムが複数あっても[sentencesForDeck]は1回しか呼ばれない。
  /// 教材を読めないデッキ（アセットが無い言語など）は例外にせずスキップする。
  Future<List<Sentence>> resolve({
    required List<SrsItem> items,
    required Future<List<Sentence>> Function(String language, int level)
    sentencesForDeck,
  }) async {
    final sorted = [...items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final cache = <String, List<Sentence>>{};
    final result = <Sentence>[];

    for (final item in sorted) {
      if (result.length >= limit) break;
      final key = '${item.language}-${item.level}';
      final sentences = cache[key] ??= await _loadOrEmpty(
        sentencesForDeck,
        item.language,
        item.level,
      );
      final match = sentences.where((s) => s.id == item.sentenceId);
      if (match.isNotEmpty) result.add(match.first);
    }
    return result;
  }

  Future<List<Sentence>> _loadOrEmpty(
    Future<List<Sentence>> Function(String language, int level) load,
    String language,
    int level,
  ) async {
    try {
      return await load(language, level);
    } catch (_) {
      return const [];
    }
  }
}
