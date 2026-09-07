import 'package:signals_core/signals_core.dart';

import '../../../core/language/learning_language.dart';
import 'app_settings.dart';

/// アプリ設定の読み書き。
///
/// [settings] / [apiKey] はアプリ寿命の signal で、書き込みのたびに更新される。
/// 現在の実装は Hive + `flutter_secure_storage`。**API キーは次フェーズで
/// サーバ側に集約され、[apiKey] とその操作はこのインタフェースから消える。**
abstract interface class SettingsRepository {
  /// 非秘匿の設定（学習言語・独り言デフォルト秒数）
  ReadonlySignal<AppSettings> get settings;

  /// Gemini API キー（未設定なら null）
  ReadonlySignal<String?> get apiKey;

  /// 永続化先から読み込む。アプリ起動時に一度呼ぶ。
  Future<void> load();

  Future<void> setLearningLanguage(LearningLanguage language);

  Future<void> setMonologueSeconds(int seconds);

  Future<void> setApiKey(String key);

  Future<void> deleteApiKey();
}
