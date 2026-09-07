// Widgetbook（Flutter版Storybook）のエントリポイント。本番アプリには含まれない。
//
//   flutter run -d chrome -t widgetbook/main.dart
//   flutter build web -t widgetbook/main.dart   # 静的サイトとして配布する場合
//
// ストーリー（状態一覧）は widgetbook/fixtures/ に置く。同じ一覧を
// test/goldens/ のゴールデンテストが使い、CIで崩れを検出する。
// 新しい状態を足すときは fixtures に1件追加するだけでよい
// （Widgetbook とゴールデンの両方に出る。ゴールデン画像は
// `flutter test --update-goldens test/goldens` で生成する）。

import 'package:flutter/material.dart';
import 'package:pj_walter/core/l10n/l10n.dart';
import 'package:pj_walter/core/theme/app_theme.dart';
import 'package:pj_walter/core/widgets/countdown_ring.dart';
import 'package:pj_walter/core/widgets/score_ring.dart';
import 'package:widgetbook/widgetbook.dart';

import 'fixtures/drill_feedback_fixtures.dart';

void main() {
  runApp(const PjWalterWidgetbook());
}

class PjWalterWidgetbook extends StatelessWidget {
  const PjWalterWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        // 画面・ウィジェットは ARB の文言を使うため、ロケールを ja に固定して描く
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialLocale: const Locale('ja'),
        ),
        ViewportAddon([
          IosViewports.iPhone13,
          IosViewports.iPhone12Mini,
          AndroidViewports.samsungGalaxyS20,
        ]),
        MaterialThemeAddon(
          themes: [WidgetbookTheme(name: 'Light', data: AppTheme.light)],
        ),
        TextScaleAddon(),
      ],
      directories: [
        WidgetbookFolder(
          name: '口頭作文',
          children: [
            WidgetbookComponent(
              name: 'DrillFeedbackView（添削画面）',
              useCases: [
                for (final story in drillFeedbackStories)
                  WidgetbookUseCase(
                    name: story.name,
                    builder: (context) => Scaffold(
                      backgroundColor: AppColors.pageBackground,
                      body: SafeArea(child: story.build()),
                    ),
                  ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: '共通ウィジェット',
          children: [
            WidgetbookComponent(
              name: 'ScoreRing',
              useCases: [
                for (final score in const [100, 85, 72, 55, 20, 0])
                  WidgetbookUseCase(
                    name: 'スコア $score',
                    builder: (context) =>
                        Center(child: ScoreRing(score: score)),
                  ),
              ],
            ),
            WidgetbookComponent(
              name: 'CountdownRing',
              useCases: [
                WidgetbookUseCase(
                  name: 'pre（録音前）',
                  builder: (context) => const Center(
                    child: CountdownRing(
                      progress: 1,
                      label: '30',
                      recording: false,
                      idleLabel: '聞き取り前',
                      dimmed: true,
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'rec（録音中）',
                  builder: (context) => const Center(
                    child: CountdownRing(
                      progress: 0.6,
                      label: '18',
                      recording: true,
                      idleLabel: '聞き取り前',
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'rec 残り5秒以下',
                  builder: (context) => const Center(
                    child: CountdownRing(
                      progress: 0.1,
                      label: '3',
                      recording: true,
                      idleLabel: '聞き取り前',
                      urgent: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
