import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/content_repository.dart';
import '../../content/domain/sentence.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/drill_question_selector.dart';

/// デッキ選択画面の Store。
///
/// レベル（英語ならTOEIC、中国語ならHSK）とテーマを選び、対象文数を数え、
/// トレーニング開始時に出題文を選ぶ。学習言語は画面を開いた時点の設定で固定する。
class DeckSelectStore extends Store {
  DeckSelectStore({
    required this._content,
    required SettingsRepository settings,
    this._selector = const DrillQuestionSelector(),
  }) : profile = settings.settings.peek().languageProfile {
    level = createSignal(profile.levels.first);
    theme = createSignal(null);
    count = createFutureSignal(
      () async => (await _loadSentences()).length,
      dependencies: [level, theme],
    );
  }

  /// 選べるテーマ（null は「すべて」）
  static const themes = <String?>[null, 'daily', 'business', 'travel'];

  final ContentRepository _content;
  final DrillQuestionSelector _selector;

  /// 学習言語（画面を開いた時点の設定）
  final LanguageProfile profile;

  late final Signal<int> level;
  late final Signal<String?> theme;

  /// 現在の選択に該当する教材文の数
  late final FutureSignal<int> count;

  void selectLevel(int value) => level.value = value;

  void selectTheme(String? value) => theme.value = value;

  /// 現在の選択から1セッション分の出題文を選ぶ。該当が無ければ空リスト。
  Future<List<Sentence>> startTraining() async =>
      _selector.select(await _loadSentences());

  Future<List<Sentence>> _loadSentences() => _content.sentences(
    profile: profile,
    level: level.peek(),
    theme: theme.peek(),
  );
}
