import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'data/hive_settings_repository.dart';
import 'domain/settings_repository.dart';

/// settings feature の依存を登録する（コンポジションルートから呼ぶ）。
void registerSettings(
  GetIt getIt, {
  required Box settingsBox,
  FlutterSecureStorage? secureStorage,
}) {
  getIt.registerLazySingleton<SettingsRepository>(
    () => HiveSettingsRepository(
      settingsBox: settingsBox,
      secureStorage: secureStorage,
    ),
  );
}
