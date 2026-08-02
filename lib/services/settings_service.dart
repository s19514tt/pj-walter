import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// 音声認識方式。
enum SttMode {
  /// 端末のOS標準音声認識（speech_to_text）。無料・高速。
  device,

  /// 録音してGeminiに文字起こしさせる方式。高精度・APIキーを消費。
  gemini,
}

/// アプリ設定の読み書きを担うサービス。
///
/// - Gemini APIキーは`flutter_secure_storage`に安全に保存し、メモリにキャッシュする
/// - モデル名・音声認識方式・独り言デフォルト秒数はHiveの`settings` boxに保存する
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

  static const _modelNameKey = 'modelName';
  static const _sttModeKey = 'sttMode';
  static const _monologueSecondsKey = 'monologueSeconds';

  static const defaultModelName = 'gemini-2.5-flash';
  static const defaultSttMode = SttMode.device;
  static const defaultMonologueSeconds = 60;

  final FlutterSecureStorage _secureStorage;
  final Box _box;

  String? _apiKey;
  String _modelName = defaultModelName;
  SttMode _sttMode = defaultSttMode;
  int _monologueSeconds = defaultMonologueSeconds;

  /// 現在キャッシュされているAPIキー（未設定ならnull）
  String? get apiKey => _apiKey;

  /// APIキーが設定済みかどうか
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// 使用するGeminiモデル名
  String get modelName => _modelName;

  /// 音声認識方式
  SttMode get sttMode => _sttMode;

  /// 独り言英会話のデフォルト発話時間（秒）
  int get monologueSeconds => _monologueSeconds;

  /// secure storageとHive boxから設定をロードする。アプリ起動時に一度呼ぶ。
  Future<void> init() async {
    _apiKey = await _secureStorage.read(key: apiKeyStorageKey);
    _modelName = (_box.get(_modelNameKey) as String?) ?? defaultModelName;
    final sttModeName = _box.get(_sttModeKey) as String?;
    _sttMode = SttMode.values.firstWhere(
      (mode) => mode.name == sttModeName,
      orElse: () => defaultSttMode,
    );
    _monologueSeconds =
        (_box.get(_monologueSecondsKey) as int?) ?? defaultMonologueSeconds;
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

  /// 使用するGeminiモデル名を変更する。
  Future<void> setModelName(String name) async {
    _modelName = name;
    await _box.put(_modelNameKey, name);
    notifyListeners();
  }

  /// 音声認識方式を変更する。
  Future<void> setSttMode(SttMode mode) async {
    _sttMode = mode;
    await _box.put(_sttModeKey, mode.name);
    notifyListeners();
  }

  /// 独り言英会話のデフォルト発話時間（秒）を変更する。
  Future<void> setMonologueSeconds(int seconds) async {
    _monologueSeconds = seconds;
    await _box.put(_monologueSecondsKey, seconds);
    notifyListeners();
  }
}
