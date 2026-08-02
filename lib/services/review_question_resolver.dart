import '../models/sentence.dart';
import '../models/srs_item.dart';

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

  /// [items]をdueDateが古い順に並べ替え、[sentencesByLevel]でレベルごとの
  /// 教材をロードしてsentenceIdから[Sentence]を解決する。
  ///
  /// レベルごとのロード結果はこの呼び出し内でキャッシュするため、
  /// 同じレベルのアイテムが複数あっても[sentencesByLevel]は1回しか呼ばれない。
  Future<List<Sentence>> resolve({
    required List<SrsItem> items,
    required Future<List<Sentence>> Function(int level) sentencesByLevel,
  }) async {
    final sorted = [...items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final cache = <int, List<Sentence>>{};
    final result = <Sentence>[];

    for (final item in sorted) {
      if (result.length >= limit) break;
      final sentences = cache[item.level] ??= await sentencesByLevel(
        item.level,
      );
      final match = sentences.where((s) => s.id == item.sentenceId);
      if (match.isNotEmpty) result.add(match.first);
    }
    return result;
  }
}
