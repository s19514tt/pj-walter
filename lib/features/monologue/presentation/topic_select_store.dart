import 'dart:math';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/content_repository.dart';
import '../../content/domain/topic.dart';
import '../../settings/domain/settings_repository.dart';

/// お題選択画面の Store。テーマでお題を絞り込み、発話時間を選ぶ。
class TopicSelectStore extends Store {
  TopicSelectStore({
    required this._content,
    required SettingsRepository settings,
    Random? random,
  }) : _random = random ?? Random(),
       profile = settings.settings.peek().languageProfile {
    final defaultSeconds = settings.settings.peek().monologueSeconds;
    theme = createSignal(null);
    seconds = createSignal(
      secondsOptions.contains(defaultSeconds)
          ? defaultSeconds
          : secondsOptions[1],
    );
    topics = createFutureSignal(
      () => _content.topics(profile: profile, theme: theme.peek()),
      dependencies: [theme],
    );
  }

  /// 選べるテーマ（null は「すべて」）
  static const themes = <String?>[null, 'daily', 'business', 'travel'];

  /// 選択できる発話時間（秒）
  static const secondsOptions = [30, 60, 120, 180];

  final ContentRepository _content;
  final Random _random;

  /// 学習言語（画面を開いた時点の設定）
  final LanguageProfile profile;

  late final Signal<String?> theme;
  late final Signal<int> seconds;
  late final FutureSignal<List<Topic>> topics;

  void selectTheme(String? value) => theme.value = value;

  void selectSeconds(int value) => seconds.value = value;

  /// 現在のテーマからランダムに1題選ぶ。該当が無ければ null。
  Future<Topic?> pickRandom() async {
    final list = await topics.future;
    if (list.isEmpty) return null;
    return list[_random.nextInt(list.length)];
  }
}
