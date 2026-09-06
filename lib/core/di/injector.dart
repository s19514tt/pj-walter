// コンポジションルート（DESIGN.md「DI」）。
//
// get_it への登録・参照を行ってよいのは、このディレクトリ・main.dart・各 feature の
// `<feature>_module.dart` だけ。UI・Store・Repository から GetIt を直接参照しない。

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../features/composition/composition_module.dart';
import '../../features/content/content_module.dart';
import '../../features/monologue/monologue_module.dart';
import '../../features/review/review_module.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/settings_module.dart';
import '../../features/speech/speech_module.dart';
import '../../features/stats/stats_module.dart';
import '../data/gemini_client.dart';

/// Hive の保存形式のバージョン。
///
/// 未リリースのため後方互換は取らない（docs/ROADMAP.md）。保存形式を変えたら
/// この値を上げる。起動時に保存されている値と違えば全 box を削除してから開く。
const dataSchemaVersion = 2;

/// アプリが使う Hive box 一式。
class AppBoxes {
  const AppBoxes({
    required this.settings,
    required this.drillResults,
    required this.monologueResults,
    required this.srsItems,
    required this.phrases,
    required this.dailyStats,
  });

  static const names = [
    'settings',
    'drill_results',
    'monologue_results',
    'srs_items',
    'phrases',
    'daily_stats',
  ];

  static const _schemaVersionKey = 'schemaVersion';

  final Box settings;
  final Box drillResults;
  final Box monologueResults;
  final Box srsItems;
  final Box phrases;
  final Box dailyStats;

  /// 全 box を開く。`Hive.init` / `Hive.initFlutter` 済みであること。
  ///
  /// 保存形式のバージョンが [dataSchemaVersion] と違えば、全 box を削除してから開く
  /// （移行コードは書かない）。
  static Future<AppBoxes> open() async {
    var settings = await Hive.openBox(names[0]);
    if (settings.get(_schemaVersionKey) != dataSchemaVersion) {
      await settings.close();
      for (final name in names) {
        await Hive.deleteBoxFromDisk(name);
      }
      settings = await Hive.openBox(names[0]);
      await settings.put(_schemaVersionKey, dataSchemaVersion);
    }
    return AppBoxes(
      settings: settings,
      drillResults: await Hive.openBox(names[1]),
      monologueResults: await Hive.openBox(names[2]),
      srsItems: await Hive.openBox(names[3]),
      phrases: await Hive.openBox(names[4]),
      dailyStats: await Hive.openBox(names[5]),
    );
  }
}

/// アプリ寿命の依存（Repository・クライアント）を [getIt] に登録する。
///
/// `main()` と、本番と同じ配線でテストしたいときだけが呼ぶ。テストで一部を
/// フェイクにするときは [GetIt.asNewInstance] に各 feature の登録関数を個別に
/// 呼び、必要なものだけ差し替える。
Future<void> configureDependencies(
  GetIt getIt, {
  required AppBoxes boxes,
  FlutterSecureStorage? secureStorage,
  http.Client? httpClient,
}) async {
  registerSettings(
    getIt,
    settingsBox: boxes.settings,
    secureStorage: secureStorage,
  );
  await getIt<SettingsRepository>().load();

  // Gemini 直叩きの共通トランスポート。次フェーズでサーバ実装に替わると消える。
  getIt.registerLazySingleton<GeminiClient>(
    () => GeminiClient(
      apiKey: () => getIt<SettingsRepository>().apiKey.peek(),
      client: httpClient,
    ),
  );

  registerContent(getIt);
  registerSpeech(getIt);
  registerComposition(getIt, drillResultsBox: boxes.drillResults);
  registerMonologue(getIt, monologueResultsBox: boxes.monologueResults);
  registerReview(getIt, srsItemsBox: boxes.srsItems, phrasesBox: boxes.phrases);
  registerStats(getIt, dailyStatsBox: boxes.dailyStats);
}
