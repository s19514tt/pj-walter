import 'package:get_it/get_it.dart';

import '../../features/composition/domain/correction_repository.dart';
import '../../features/composition/domain/drill_session.dart';
import '../../features/composition/domain/record_drill_result.dart';
import '../../features/composition/presentation/deck_select_store.dart';
import '../../features/composition/presentation/drill_store.dart';
import '../../features/composition/presentation/drill_summary_store.dart';
import '../../features/composition/presentation/sentence_list_store.dart';
import '../../features/content/domain/content_repository.dart';
import '../../features/content/domain/sentence.dart';
import '../../features/content/domain/topic.dart';
import '../../features/composition/domain/drill_history_repository.dart';
import '../../features/home/presentation/home_store.dart';
import '../../features/monologue/domain/monologue_history_repository.dart';
import '../../features/monologue/domain/monologue_result.dart';
import '../../features/monologue/domain/monologue_review_repository.dart';
import '../../features/monologue/domain/record_monologue_result.dart';
import '../../features/monologue/presentation/monologue_feedback_store.dart';
import '../../features/monologue/presentation/monologue_speak_store.dart';
import '../../features/monologue/presentation/topic_select_store.dart';
import '../../features/review/domain/load_review_session.dart';
import '../../features/review/domain/phrase_repository.dart';
import '../../features/review/domain/srs_repository.dart';
import '../../features/review/presentation/review_store.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/settings_store.dart';
import '../../features/speech/domain/speech_input_service.dart';
import '../../features/speech/speech_module.dart';
import '../../features/stats/domain/study_stats_repository.dart';
import '../../features/stats/presentation/stats_store.dart';
import '../domain/gemini_pricing.dart';
import 'store_factory.dart';

/// [StoreFactory] の get_it 実装。
///
/// get_it から Repository を取り出して Store のコンストラクタへ渡す**唯一の場所**。
/// 画面寿命のもの（録音・再生サービス、Timer）も Store と一緒にここで組み立て、
/// 破棄は Store に任せる。
class GetItStoreFactory implements StoreFactory {
  const GetItStoreFactory(this._getIt);

  final GetIt _getIt;

  @override
  SettingsStore settings() =>
      SettingsStore(settings: _getIt<SettingsRepository>());

  @override
  DeckSelectStore deckSelect() => DeckSelectStore(
    content: _getIt<ContentRepository>(),
    settings: _getIt<SettingsRepository>(),
  );

  @override
  SentenceListStore sentenceList({required int level, String? theme}) =>
      SentenceListStore(
        content: _getIt<ContentRepository>(),
        settings: _getIt<SettingsRepository>(),
        level: level,
        theme: theme,
      );

  @override
  DrillStore drill({
    required List<Sentence> sentences,
    required int level,
    required String? theme,
    required bool isReview,
    required String uiLocale,
    required DrillTexts texts,
    int questionSeconds = DrillStore.defaultQuestionSeconds,
  }) {
    final settings = _getIt<SettingsRepository>();
    final profile = settings.settings.peek().languageProfile;
    return DrillStore(
      sentences: sentences,
      level: level,
      theme: theme,
      isReview: isReview,
      uiLocale: uiLocale,
      texts: texts,
      speechInput: _getIt<SpeechInputServiceFactory>()(profile),
      tts: _getIt<TtsServiceFactory>()(profile),
      correction: _getIt<CorrectionRepository>(),
      recordResult: _getIt<RecordDrillResult>(),
      settings: settings,
      questionSeconds: questionSeconds,
    );
  }

  @override
  TopicSelectStore topicSelect() => TopicSelectStore(
    content: _getIt<ContentRepository>(),
    settings: _getIt<SettingsRepository>(),
  );

  @override
  MonologueSpeakStore monologueSpeak({
    required Topic topic,
    required int seconds,
  }) {
    final settings = _getIt<SettingsRepository>();
    return MonologueSpeakStore(
      topic: topic,
      seconds: seconds,
      speechInput: _getIt<SpeechInputServiceFactory>()(
        settings.settings.peek().languageProfile,
      ),
      settings: settings,
    );
  }

  @override
  MonologueFeedbackStore monologueFeedback({
    required Topic topic,
    required int seconds,
    required String uiLocale,
    MonologueResult? initialResult,
    SpeechInputService? speechInput,
  }) => MonologueFeedbackStore(
    topic: topic,
    seconds: seconds,
    uiLocale: uiLocale,
    review: _getIt<MonologueReviewRepository>(),
    recordResult: _getIt<RecordMonologueResult>(),
    phrases: _getIt<PhraseRepository>(),
    settings: _getIt<SettingsRepository>(),
    initialResult: initialResult,
    speechInput: speechInput,
  );

  @override
  ReviewStore review() => ReviewStore(
    srs: _getIt<SrsRepository>(),
    phrases: _getIt<PhraseRepository>(),
    settings: _getIt<SettingsRepository>(),
    loadReviewSession: _getIt<LoadReviewSession>(),
  );

  @override
  StatsStore stats() => StatsStore(
    stats: _getIt<StudyStatsRepository>(),
    drillHistory: _getIt<DrillHistoryRepository>(),
    monologueHistory: _getIt<MonologueHistoryRepository>(),
    content: _getIt<ContentRepository>(),
  );

  @override
  HomeStore home() => HomeStore(
    settings: _getIt<SettingsRepository>(),
    srs: _getIt<SrsRepository>(),
    stats: _getIt<StudyStatsRepository>(),
    drillHistory: _getIt<DrillHistoryRepository>(),
    monologueHistory: _getIt<MonologueHistoryRepository>(),
    loadReviewSession: _getIt<LoadReviewSession>(),
  );

  @override
  DrillSummaryStore drillSummary({
    required int level,
    required String? theme,
    required List<DrillSummaryEntry> entries,
    GeminiPricing? pricing,
  }) => DrillSummaryStore(
    content: _getIt<ContentRepository>(),
    settings: _getIt<SettingsRepository>(),
    level: level,
    theme: theme,
    entries: entries,
    pricing: pricing,
  );
}
