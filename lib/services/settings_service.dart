// 旧 provider ベースの画面のための一時的なファサード。
// 画面が Store（signals）へ移行し終わったら削除する。

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../core/language/learning_language.dart';
import '../features/settings/data/hive_settings_repository.dart';
import '../features/settings/domain/settings_repository.dart';

/// [SettingsRepository] を `ChangeNotifier` として見せる移行用ファサード。
class SettingsService extends ChangeNotifier {
  SettingsService({
    FlutterSecureStorage? secureStorage,
    required Box settingsBox,
  }) : this.of(
         HiveSettingsRepository(
           settingsBox: settingsBox,
           secureStorage: secureStorage,
         ),
       );

  SettingsService.of(this.repository) {
    _cleanups = [
      repository.settings.subscribe((_) => notifyListeners()),
      repository.apiKey.subscribe((_) => notifyListeners()),
    ];
  }

  final SettingsRepository repository;
  late final List<void Function()> _cleanups;

  String? get apiKey => repository.apiKey.value;
  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;
  int get monologueSeconds => repository.settings.value.monologueSeconds;
  LearningLanguage get learningLanguage =>
      repository.settings.value.learningLanguage;
  LanguageProfile get languageProfile =>
      repository.settings.value.languageProfile;

  Future<void> init() => repository.load();
  Future<void> setApiKey(String key) => repository.setApiKey(key);
  Future<void> deleteApiKey() => repository.deleteApiKey();
  Future<void> setMonologueSeconds(int seconds) =>
      repository.setMonologueSeconds(seconds);
  Future<void> setLearningLanguage(LearningLanguage language) =>
      repository.setLearningLanguage(language);

  @override
  void dispose() {
    for (final cleanup in _cleanups) {
      cleanup();
    }
    super.dispose();
  }
}
