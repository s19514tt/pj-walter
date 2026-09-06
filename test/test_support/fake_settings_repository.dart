import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:signals_core/signals_core.dart';

/// メモリ上だけで動く [SettingsRepository]（Store / 画面のテスト用）。
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    AppSettings initial = const AppSettings(),
    String? apiKey,
  }) : _settings = signal(initial),
       _apiKey = signal(apiKey);

  final Signal<AppSettings> _settings;
  final Signal<String?> _apiKey;

  @override
  ReadonlySignal<AppSettings> get settings => _settings;

  @override
  ReadonlySignal<String?> get apiKey => _apiKey;

  @override
  Future<void> load() async {}

  @override
  Future<void> setLearningLanguage(LearningLanguage language) async {
    _settings.value = _settings.value.copyWith(learningLanguage: language);
  }

  @override
  Future<void> setMonologueSeconds(int seconds) async {
    _settings.value = _settings.value.copyWith(monologueSeconds: seconds);
  }

  @override
  Future<void> setApiKey(String key) async => _apiKey.value = key;

  @override
  Future<void> deleteApiKey() async => _apiKey.value = null;
}
