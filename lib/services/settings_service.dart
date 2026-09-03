import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// アプリ設定の読み書きを担うサービス。
///
/// - Gemini APIキーは`flutter_secure_storage`に安全に保存し、メモリにキャッシュする
/// - 独り言デフォルト秒数はHiveの`settings` boxに保存する
///
/// 使用するGeminiモデルは[GeminiService.modelName]で固定（設定不可）、
/// 音声認識はGemini録音方式のみ（端末STTはPR11で廃止）。
///
/// テスト容易性のため、secure storageとHive boxはコンストラクタ注入できる。
class SettingsService extends ChangeNotifier {
  SettingsService({
    FlutterSecureStorage? secureStorage,
    required Box settingsBox,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _box = settingsBox;

  /// secure storageに保存するAPIキーのキー名
  static const apiKeyStorageKey = 'gemini_api_key';

  static const _monologueSecondsKey = 'monologueSeconds';

  /// 過去バージョンで使っていた設定キー。[init]時に削除する
  /// （モデル選択・音声認識方式の設定はPR11で廃止）。
  static const _legacyKeys = ['modelName', 'sttMode'];

  static const defaultMonologueSeconds = 60;

  final FlutterSecureStorage _secureStorage;
  final Box _box;

  String? _apiKey;
  int _monologueSeconds = defaultMonologueSeconds;

  /// 現在キャッシュされているAPIキー（未設定ならnull）
  String? get apiKey => _apiKey;

  /// APIキーが設定済みかどうか
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// 独り言英会話のデフォルト発話時間（秒）
  int get monologueSeconds => _monologueSeconds;

  /// secure storageとHive boxから設定をロードする。アプリ起動時に一度呼ぶ。
  Future<void> init() async {
    _apiKey = await _secureStorage.read(key: apiKeyStorageKey);
    _monologueSeconds =
        (_box.get(_monologueSecondsKey) as int?) ?? defaultMonologueSeconds;
    for (final key in _legacyKeys) {
      if (_box.containsKey(key)) await _box.delete(key);
    }
    notifyListeners();
  }

  /// APIキーを保存する。
  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: apiKeyStorageKey, value: key);
    _apiKey = key;
    notifyListeners();
  }

  /// APIキーを削除する。
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: apiKeyStorageKey);
    _apiKey = null;
    notifyListeners();
  }

  /// 独り言英会話のデフォルト発話時間（秒）を変更する。
  Future<void> setMonologueSeconds(int seconds) async {
    _monologueSeconds = seconds;
    await _box.put(_monologueSecondsKey, seconds);
    notifyListeners();
  }
}
