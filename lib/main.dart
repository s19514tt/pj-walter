import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/shell.dart';
import 'services/gemini_service.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

/// Hive boxを開き、初期化済みのサービス一式を返す。
///
/// [MyApp]に渡すことで、`main()`とテストの両方から同じ初期化手順を再利用できる。
Future<({SettingsService settings, HistoryService history})>
initializeServices() async {
  final settingsBox = await Hive.openBox('settings');
  final drillResultsBox = await Hive.openBox('drill_results');
  final monologueResultsBox = await Hive.openBox('monologue_results');
  final srsItemsBox = await Hive.openBox('srs_items');
  final phrasesBox = await Hive.openBox('phrases');
  final dailyStatsBox = await Hive.openBox('daily_stats');

  final settingsService = SettingsService(settingsBox: settingsBox);
  await settingsService.init();

  final historyService = HistoryService(
    drillResultsBox: drillResultsBox,
    monologueResultsBox: monologueResultsBox,
    srsItemsBox: srsItemsBox,
    phrasesBox: phrasesBox,
    dailyStatsBox: dailyStatsBox,
  );

  return (settings: settingsService, history: historyService);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final services = await initializeServices();

  runApp(
    MyApp(settingsService: services.settings, historyService: services.history),
  );
}

/// アプリのルートウィジェット。
///
/// 初期化済みの[SettingsService]・[HistoryService]を受け取り、
/// [MultiProvider]でアプリ全体に配布する。
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsService,
    required this.historyService,
  });

  final SettingsService settingsService;
  final HistoryService historyService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<HistoryService>.value(value: historyService),
        ProxyProvider<SettingsService, GeminiService>(
          update: (context, settings, previous) =>
              GeminiService(settingsService: settings),
        ),
      ],
      child: MaterialApp(
        title: 'pj-walter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Shell(),
      ),
    );
  }
}
