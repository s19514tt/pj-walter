import '../../../core/language/learning_language.dart';
import 'sentence.dart';
import 'topic.dart';

/// 教材（口頭作文の文）と独り言のお題を取得する Repository。
///
/// **次フェーズでサーバ実装に差し替わる継ぎ目。** 現在の実装は
/// `AssetContentRepository`（アプリ同梱の JSON アセット）。
/// 返すリストは変更不可（呼び出し側でシャッフルするときはコピーする）。
abstract interface class ContentRepository {
  /// 指定言語・レベルの教材文一覧。
  ///
  /// [theme] を指定すると `daily` / `business` / `travel` でフィルタする。
  /// その言語に無いレベルは [ArgumentError]。
  Future<List<Sentence>> sentences({
    required LanguageProfile profile,
    required int level,
    String? theme,
  });

  /// 指定言語の独り言お題一覧。[theme] でフィルタできる。
  Future<List<Topic>> topics({required LanguageProfile profile, String? theme});
}
