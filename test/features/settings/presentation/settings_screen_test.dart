// SettingsScreen のウィジェットテスト（Store 経由・provider 不使用）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:pj_walter/features/settings/presentation/settings_screen.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/test_app.dart';

void main() {
  late GetIt getIt;
  late FakeSettingsRepository repository;

  setUp(() {
    getIt = GetIt.asNewInstance();
    repository = FakeSettingsRepository();
    getIt.registerSingleton<SettingsRepository>(repository);
  });

  testWidgets('言語・APIキー・デフォルト時間を表示し、操作が Repository に反映される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      scopedApp(getIt: getIt, home: const SettingsScreen()),
    );

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('英語'), findsOneWidget);
    expect(find.text('中国語'), findsOneWidget);
    expect(find.text('APIキーを入力'), findsOneWidget);
    expect(find.text('1分'), findsOneWidget);

    // 学習言語の切り替え
    await tester.tap(find.text('中国語'));
    await tester.pump();
    expect(
      repository.settings.value.learningLanguage,
      LearningLanguage.chinese,
    );

    // 独り言デフォルト時間
    await tester.tap(find.text('2分'));
    await tester.pump();
    expect(repository.settings.value.monologueSeconds, 120);

    // APIキーの保存 → 設定済み表示に切り替わる
    await tester.enterText(find.byType(TextField), ' my-key ');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(repository.apiKey.value, 'my-key');
    expect(find.text('APIキーは設定済みです'), findsOneWidget);
    expect(find.text('APIキーを保存しました'), findsOneWidget);

    // 削除で入力欄に戻る
    await tester.tap(find.text('APIキーを削除'));
    await tester.pump();
    expect(repository.apiKey.value, isNull);
    expect(find.text('APIキーを入力'), findsOneWidget);
  });
}
