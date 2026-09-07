import 'package:get_it/get_it.dart';

import 'data/asset_content_repository.dart';
import 'domain/content_repository.dart';

/// content feature の依存を登録する（コンポジションルートから呼ぶ）。
///
/// 次フェーズでは [AssetContentRepository] をサーバ配信の実装に差し替える。
void registerContent(GetIt getIt) {
  getIt.registerLazySingleton<ContentRepository>(AssetContentRepository.new);
}
