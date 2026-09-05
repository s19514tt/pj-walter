// 添削画面のゴールデンテスト。
//
// widgetbook/fixtures/ の状態一覧を1件ずつ描画し、test/goldens/drill_feedback/
// のPNGと比較する。Widgetbook で目視する状態と CI が守る状態を同じにするため、
// 状態はフィクスチャにだけ書く。
//
// 画像の更新（意図した見た目の変更のとき）:
//   flutter test --update-goldens test/goldens
//
// 注意: flutter_test の既定フォントは実フォントではないため、漢字は四角
// （tofu）で描かれる。文字の形ではなくレイアウト（位置・サイズ・色）の
// 崩れを検出するためのもの。見た目の確認は Widgetbook で行う。
// CI（ubuntu）と同じ Linux で生成した画像をコミットすること。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/theme/app_theme.dart';

import '../../widgetbook/fixtures/drill_feedback_fixtures.dart';

void main() {
  for (final story in drillFeedbackStories) {
    testWidgets(story.name, (tester) async {
      // iPhone 13 相当の幅。縦は全カードが収まる高さにして ListView を全部構築する
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          // Google Fonts はネットワーク取得になるため、テストではシステムフォントで組む
          theme: AppTheme.build(webFonts: false),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: story.build(),
          ),
        ),
      );
      // スケルトンのシマーは無限アニメーションのため pumpAndSettle が収束しない。
      // 固定回数のフレームで、有限アニメーション（スコアリング 800ms・カードの
      // 段階フェードイン 60ms×N＋300ms）を流し切る。
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('drill_feedback/${story.slug}.png'),
      );
    });
  }
}
