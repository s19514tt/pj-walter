import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/content_repository.dart';
import '../../content/domain/sentence.dart';
import '../../settings/domain/settings_repository.dart';

/// 教材一覧画面の Store。選択レベル×テーマの教材文を読み込む。
class SentenceListStore extends Store {
  SentenceListStore({
    required ContentRepository content,
    required SettingsRepository settings,
    required this.level,
    this.theme,
  }) : profile = settings.settings.peek().languageProfile {
    sentences = createFutureSignal(
      () => content.sentences(profile: profile, level: level, theme: theme),
    );
  }

  final LanguageProfile profile;
  final int level;
  final String? theme;

  late final FutureSignal<List<Sentence>> sentences;
}
