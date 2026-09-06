// ウィジェットテスト共通の MaterialApp 組み立て。
//
// 画面は ARB の文言（context.l10n）を使うため、テストでも
// localizationsDelegates が必要。ロケールは ja に固定する（ゴールデンテストの
// 画像が翻訳の追加で変わらないようにするため。DESIGN.md「i18n」）。
//
// Store を使う画面は AppScope（StoreFactory）も必要。[scopedApp] に
// フェイクを登録した GetIt を渡す。

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pj_walter/core/di/get_it_store_factory.dart';
import 'package:pj_walter/core/di/store_factory.dart';
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

/// [getIt] に登録した依存で Store を組み立てる [AppScope] 付きの [localizedApp]。
///
/// [wrap] を渡すと MaterialApp をさらに包む（移行中の provider 配線用）。
Widget scopedApp({
  required GetIt getIt,
  Widget? home,
  ThemeData? theme,
  Widget Function(Widget app)? wrap,
}) {
  final app = localizedApp(home: home, theme: theme);
  return AppScope(
    stores: GetItStoreFactory(getIt),
    child: wrap == null ? app : wrap(app),
  );
}
