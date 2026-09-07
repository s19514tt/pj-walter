import '../../../core/language/learning_language.dart';
import '../../content/domain/content_repository.dart';
import '../../content/domain/sentence.dart';
import 'review_question_resolver.dart';
import 'srs_item.dart';

/// 「今日の復習」の出題文を解決する UseCase。
///
/// [SrsItem]は sentenceId しか持たないため、[ContentRepository]から言語×レベルごとの
/// 教材を引いて[Sentence]に解決する（[ReviewQuestionResolver]）。ホーム・復習タブの
/// 両方から使う。
class LoadReviewSession {
  const LoadReviewSession({
    required this.content,
    this.resolver = const ReviewQuestionResolver(),
  });

  final ContentRepository content;
  final ReviewQuestionResolver resolver;

  /// [dueItems]を dueDate が古い順に最大件数まで [Sentence] に解決する。
  /// 教材が見つからないアイテムは飛ばす。
  Future<List<Sentence>> call(List<SrsItem> dueItems) => resolver.resolve(
    items: dueItems,
    sentencesForDeck: (language, level) => content.sentences(
      profile: LanguageProfile.ofCode(language),
      level: level,
    ),
  );
}
