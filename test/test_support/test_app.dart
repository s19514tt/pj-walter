// ウィジェットテスト共通の MaterialApp 組み立て。
//
// 画面は ARB の文言（context.l10n）を使うため、テストでも
// localizationsDelegates が必要。ロケールは ja に固定する（ゴールデンテストの
// 画像が翻訳の追加で変わらないようにするため。DESIGN.md「i18n」）。

import 'package:flutter/material.dart';
import 'package:pj_walter/core/l10n/l10n.dart';

/// テスト用のロケール。翻訳を足しても画像・文言の検証が変わらないよう固定する。
const testLocale = Locale('ja');

/// ロケールを [testLocale] に固定した [MaterialApp]。
///
/// [home] を渡すと `home:` に置く。[builder] を渡すと `MaterialApp.builder` に渡す。
MaterialApp localizedApp({
  Widget? home,
  ThemeData? theme,
  TransitionBuilder? builder,
}) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    debugShowCheckedModeBanner: false,
    home: home,
    builder: builder,
  );
}
