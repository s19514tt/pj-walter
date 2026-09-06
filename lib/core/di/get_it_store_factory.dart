import 'package:get_it/get_it.dart';

import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/settings_store.dart';
import 'store_factory.dart';

/// [StoreFactory] の get_it 実装。
///
/// get_it から Repository を取り出して Store のコンストラクタへ渡す**唯一の場所**。
/// 画面寿命のもの（録音・再生サービス、Timer）も Store と一緒にここで組み立て、
/// 破棄は Store に任せる。
class GetItStoreFactory implements StoreFactory {
  const GetItStoreFactory(this._getIt);

  final GetIt _getIt;

  @override
  SettingsStore settings() =>
      SettingsStore(settings: _getIt<SettingsRepository>());
}
