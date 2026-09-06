import 'package:flutter/widgets.dart';

import '../../features/composition/domain/drill_session.dart';
import '../../features/composition/presentation/deck_select_store.dart';
import '../../features/composition/presentation/drill_store.dart';
import '../../features/composition/presentation/drill_summary_store.dart';
import '../../features/composition/presentation/sentence_list_store.dart';
import '../../features/content/domain/sentence.dart';
import '../../features/settings/presentation/settings_store.dart';
import '../domain/gemini_pricing.dart';

/// 画面が Store を組み立てるための入口（DESIGN.md「DI」）。
///
/// 画面は `State.initState` で `StoreFactory.of(context).xxx()` を呼んで Store を
/// 作り、`State.dispose` で `store.dispose()` する。Store の依存（Repository 等）は
/// ここの実装（[AppScope] に渡す `GetItStoreFactory`）がコンストラクタ注入する。
/// 画面・Store は get_it を知らない。
abstract interface class StoreFactory {
  SettingsStore settings();

  DeckSelectStore deckSelect();

  SentenceListStore sentenceList({required int level, String? theme});

  DrillStore drill({
    required List<Sentence> sentences,
    required int level,
    required String? theme,
    required bool isReview,
    required String uiLocale,
    required DrillTexts texts,
    int questionSeconds,
  });

  DrillSummaryStore drillSummary({
    required int level,
    required String? theme,
    required List<DrillSummaryEntry> entries,
    GeminiPricing? pricing,
  });

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
