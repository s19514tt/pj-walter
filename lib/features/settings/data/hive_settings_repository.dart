import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../../../core/language/learning_language.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// [SettingsRepository] の実装。
///
/// - API キーは `flutter_secure_storage` に安全に保存し、メモリにキャッシュする
/// - 学習言語・独り言デフォルト秒数は Hive の `settings` box に保存する
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository({
    required Box settingsBox,
    FlutterSecureStorage? secureStorage,
  }) : _box = settingsBox,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _settings = signal(const AppSettings()),
       _apiKey = signal(null);

  /// secure storageに保存するAPIキーのキー名
  static const apiKeyStorageKey = 'gemini_api_key';

  static const _monologueSecondsKey = 'monologueSeconds';
  static const _learningLanguageKey = 'learningLanguage';

  final Box _box;
  final FlutterSecureStorage _secureStorage;
  final Signal<AppSettings> _settings;
  final Signal<String?> _apiKey;

  @override
  ReadonlySignal<AppSettings> get settings => _settings;

  @override
  ReadonlySignal<String?> get apiKey => _apiKey;

  @override
  Future<void> load() async {
    _apiKey.value = await _secureStorage.read(key: apiKeyStorageKey);
    final languageName = _box.get(_learningLanguageKey) as String?;
    _settings.value = AppSettings(
      learningLanguage: LearningLanguage.values.firstWhere(
        (language) => language.name == languageName,
        orElse: () => AppSettings.defaultLearningLanguage,
      ),
      monologueSeconds:
          (_box.get(_monologueSecondsKey) as int?) ??
          AppSettings.defaultMonologueSeconds,
    );
  }

  @override
  Future<void> setLearningLanguage(LearningLanguage language) async {
    await _box.put(_learningLanguageKey, language.name);
    _settings.value = _settings.value.copyWith(learningLanguage: language);
  }

  @override
  Future<void> setMonologueSeconds(int seconds) async {
    await _box.put(_monologueSecondsKey, seconds);
    _settings.value = _settings.value.copyWith(monologueSeconds: seconds);
  }

  @override
  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: apiKeyStorageKey, value: key);
    _apiKey.value = key;
  }

  @override
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: apiKeyStorageKey);
    _apiKey.value = null;
  }
}
