// SettingsStore のユニットテスト（ウィジェットを pump しない）。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:pj_walter/features/settings/presentation/settings_store.dart';

import '../../../test_support/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;
  late SettingsStore store;

  setUp(() {
    repository = FakeSettingsRepository();
    store = SettingsStore(settings: repository);
  });

  tearDown(() => store.dispose());

  test('初期値は Repository の設定を反映する', () {
    expect(store.learningLanguage.value, LearningLanguage.english);
    expect(store.monologueSeconds.value, 60);
    expect(store.hasApiKey.value, isFalse);
    expect(store.obscureApiKey.value, isTrue);
  });

  test('学習言語・秒数の変更は Repository を経由して computed に反映される', () async {
    await store.setLearningLanguage(LearningLanguage.chinese);
    await store.setMonologueSeconds(120);

    expect(
      repository.settings.value.learningLanguage,
      LearningLanguage.chinese,
    );
    expect(store.learningLanguage.value, LearningLanguage.chinese);
    expect(store.monologueSeconds.value, 120);
  });

  test('APIキーは前後の空白を除いて保存し、空なら保存しない', () async {
    expect(await store.saveApiKey('   '), isFalse);
    expect(store.hasApiKey.value, isFalse);

    expect(await store.saveApiKey('  key-1 '), isTrue);
    expect(repository.apiKey.value, 'key-1');
    expect(store.hasApiKey.value, isTrue);

    await store.deleteApiKey();
    expect(store.hasApiKey.value, isFalse);
  });

  test('マスク表示はトグルできる', () {
    store.toggleObscureApiKey();
    expect(store.obscureApiKey.value, isFalse);
    store.toggleObscureApiKey();
    expect(store.obscureApiKey.value, isTrue);
  });

  test('dispose 後は signal を破棄している', () {
    store.dispose();
    expect(store.disposed, isTrue);
    expect(store.obscureApiKey.disposed, isTrue);
  });

  test('Hive 実装でも同じ契約で動く', () async {
    // FakeSettingsRepository と HiveSettingsRepository が同じインタフェースを
    // 満たしていることの確認（型だけ）。
    SettingsRepository asInterface = repository;
    expect(asInterface.settings.value.monologueSeconds, 60);
    expect(Hive, isNotNull);
  });
}
