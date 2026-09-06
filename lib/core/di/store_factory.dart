import 'package:flutter/widgets.dart';

import '../../features/settings/presentation/settings_store.dart';

/// 画面が Store を組み立てるための入口（DESIGN.md「DI」）。
///
/// 画面は `State.initState` で `StoreFactory.of(context).xxx()` を呼んで Store を
/// 作り、`State.dispose` で `store.dispose()` する。Store の依存（Repository 等）は
/// ここの実装（[AppScope] に渡す `GetItStoreFactory`）がコンストラクタ注入する。
/// 画面・Store は get_it を知らない。
abstract interface class StoreFactory {
  SettingsStore settings();

  static StoreFactory of(BuildContext context) => AppScope.of(context);
}

/// [StoreFactory] をウィジェットツリーに流す InheritedWidget。
///
/// `main.dart` が `MaterialApp` の外側に置く。テストは `GetIt.asNewInstance()` に
/// フェイクを登録した `GetItStoreFactory` を渡す。
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.stores, required super.child});

  final StoreFactory stores;

  static StoreFactory of(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AppScope>()
        ?.widget;
    assert(scope != null, 'AppScope が MaterialApp の外側に置かれていません');
    return (scope! as AppScope).stores;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => stores != oldWidget.stores;
}
