import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../domain/settings_repository.dart';

/// 設定画面の Store。
///
/// 設定値そのものは [SettingsRepository] の signal が持ち、ここは画面用の
/// 派生値（computed）と入力状態（API キー欄のマスク表示）だけを持つ。
class SettingsStore extends Store {
  SettingsStore({required this._settings}) {
    learningLanguage = createComputed(
      () => _settings.settings.value.learningLanguage,
    );
    monologueSeconds = createComputed(
      () => _settings.settings.value.monologueSeconds,
    );
    hasApiKey = createComputed(() => (_settings.apiKey.value ?? '').isNotEmpty);
    obscureApiKey = createSignal(true);
  }

  /// 独り言のデフォルト時間として選べる秒数
  static const monologueSecondsCandidates = [30, 60, 120, 180];

  final SettingsRepository _settings;

  late final Computed<LearningLanguage> learningLanguage;
  late final Computed<int> monologueSeconds;
  late final Computed<bool> hasApiKey;

  /// API キー入力欄をマスク表示するかどうか
  late final Signal<bool> obscureApiKey;

  /// 選べる学習言語の一覧
  List<LanguageProfile> get languageProfiles => LanguageProfile.values;

  void toggleObscureApiKey() => obscureApiKey.value = !obscureApiKey.value;

  Future<void> setLearningLanguage(LearningLanguage language) =>
      _settings.setLearningLanguage(language);

  Future<void> setMonologueSeconds(int seconds) =>
      _settings.setMonologueSeconds(seconds);

  /// API キーを保存する。空文字（空白のみ）は保存せず false を返す。
  Future<bool> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    await _settings.setApiKey(trimmed);
    return true;
  }

  Future<void> deleteApiKey() => _settings.deleteApiKey();
}
