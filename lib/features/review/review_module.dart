import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../content/domain/content_repository.dart';
import 'data/hive_phrase_repository.dart';
import 'data/hive_srs_repository.dart';
import 'domain/load_review_session.dart';
import 'domain/phrase_repository.dart';
import 'domain/review_question_resolver.dart';
import 'domain/srs_repository.dart';

/// review feature の依存を登録する（コンポジションルートから呼ぶ）。
void registerReview(
  GetIt getIt, {
  required Box srsItemsBox,
  required Box phrasesBox,
}) {
  getIt.registerLazySingleton<SrsRepository>(
    () => HiveSrsRepository(srsItemsBox),
  );
  getIt.registerLazySingleton<PhraseRepository>(
    () => HivePhraseRepository(phrasesBox),
  );
  getIt.registerLazySingleton<ReviewQuestionResolver>(
    () => const ReviewQuestionResolver(),
  );
  getIt.registerLazySingleton<LoadReviewSession>(
    () => LoadReviewSession(
      content: getIt<ContentRepository>(),
      resolver: getIt<ReviewQuestionResolver>(),
    ),
  );
}
