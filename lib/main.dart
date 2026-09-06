import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/get_it_store_factory.dart';
import 'core/di/injector.dart';
import 'core/di/store_factory.dart';
import 'core/l10n/l10n.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await AppBoxes.open();
  await configureDependencies(GetIt.instance, boxes: boxes);

  runApp(App(getIt: GetIt.instance));
}

/// アプリのルートウィジェット。
///
/// [AppScope] で `StoreFactory` を配り、画面はそこから Store を組み立てる
/// （DESIGN.md「DI」）。get_it を参照するのはここと `core/di/`、各 feature の
/// `*_module.dart` だけ。
class App extends StatelessWidget {
  const App({super.key, required this.getIt});

  final GetIt getIt;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      stores: GetItStoreFactory(getIt),
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Shell(),
      ),
    );
  }
}
