import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/data/gemini_client.dart';
import 'core/di/get_it_store_factory.dart';
import 'core/di/injector.dart';
import 'core/di/store_factory.dart';
import 'core/l10n/l10n.dart';
import 'core/theme/app_theme.dart';
import 'features/composition/domain/drill_history_repository.dart';
import 'features/content/domain/content_repository.dart';
import 'features/monologue/domain/monologue_history_repository.dart';
import 'features/review/domain/phrase_repository.dart';
import 'features/review/domain/srs_repository.dart';
import 'features/settings/domain/settings_repository.dart';
import 'features/stats/domain/study_stats_repository.dart';
import 'screens/shell.dart';
import 'services/gemini_service.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await AppBoxes.open();
  await configureDependencies(GetIt.instance, boxes: boxes);

  runApp(App(getIt: GetIt.instance));
}

/// アプリのルートウィジェット。
///
/// [AppScope] で `StoreFactory` を配り、画面はそこから Store を組み立てる。
/// provider の `MultiProvider` は Store へ移行していない画面のための一時的な配線で、
/// 移行が終わったら削除する。
class App extends StatelessWidget {
  const App({super.key, required this.getIt});

  final GetIt getIt;

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService.of(getIt<SettingsRepository>());
    return AppScope(
      stores: GetItStoreFactory(getIt),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
          ChangeNotifierProvider<HistoryService>(
            create: (_) => HistoryService.of(
              drillHistoryRepository: getIt<DrillHistoryRepository>(),
              monologueHistoryRepository: getIt<MonologueHistoryRepository>(),
              srs: getIt<SrsRepository>(),
              phraseRepository: getIt<PhraseRepository>(),
              stats: getIt<StudyStatsRepository>(),
            ),
          ),
          Provider<GeminiService>(
            create: (_) => GeminiService.of(getIt<GeminiClient>()),
          ),
          Provider<ContentRepository>.value(value: getIt<ContentRepository>()),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Shell(),
        ),
      ),
    );
  }
}
