import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/language/learning_language.dart';

part 'app_settings.freezed.dart';

/// 非秘匿の設定値（Hive `settings` box に保存する）。API キーは含まない。
@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    /// 現在の学習対象言語
    @Default(AppSettings.defaultLearningLanguage)
    LearningLanguage learningLanguage,

    /// 独り言トレーニングのデフォルト発話時間（秒）
    @Default(AppSettings.defaultMonologueSeconds) int monologueSeconds,
  }) = _AppSettings;

  static const defaultLearningLanguage = LearningLanguage.english;
  static const defaultMonologueSeconds = 60;

  /// 現在の学習言語に対応する設定一式
  LanguageProfile get languageProfile => LanguageProfile.of(learningLanguage);
}
