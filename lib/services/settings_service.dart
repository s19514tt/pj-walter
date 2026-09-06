import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../models/learning_language.dart';

/// アプリ設定の読み書きを担うサービス。
///
/// - Gemini APIキー・Cloud TTS APIキーは`flutter_secure_storage`に安全に保存し、
///   メモリにキャッシュする
/// - 学習言語・独り言デフォルト秒数はHiveの`settings` boxに保存する
///
/// 使用するGeminiモデルは[GeminiService.modelName]で固定（設定不可）、
/// 音声認識はGemini録音方式のみ（端末STTはPR17で廃止）。
///
/// テスト容易性のため、secure storageとHive boxはコンストラクタ注入できる。
class SettingsService extends ChangeNotifier {
  SettingsService({
    FlutterSecureStorage? secureStorage,
    required Box settingsBox,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _box = settingsBox;

  /// secure storageに保存するGemini APIキーのキー名
  static const apiKeyStorageKey = 'gemini_api_key';

  /// secure storageに保存するCloud TTS APIキーのキー名。
  ///
  /// 読み上げ（Cloud Text-to-Speech）はGeminiとは別のAPIなので、キーを分けて
  /// 登録できるようにしてある。同じGoogle CloudプロジェクトのキーでCloud TTS
  /// を有効化しているなら登録は不要（[ttsApiKey]がGeminiのキーを流用する）。
  static const ttsApiKeyStorageKey = 'cloud_tts_api_key';

  static const _monologueSecondsKey = 'monologueSeconds';
  static const _learningLanguageKey = 'learningLanguage';

  /// 過去バージョンで使っていた設定キー。[init]時に削除する
  /// （モデル選択・音声認識方式の設定はPR17で廃止）。
  static const _legacyKeys = ['modelName', 'sttMode'];

  static const defaultMonologueSeconds = 60;
  static const defaultLearningLanguage = LearningLanguage.english;

  final FlutterSecureStorage _secureStorage;
  final Box _box;

  String? _apiKey;
  String? _ttsApiKey;
  int _monologueSeconds = defaultMonologueSeconds;
  LearningLanguage _learningLanguage = defaultLearningLanguage;

  /// 現在キャッシュされているAPIキー（未設定ならnull）
  String? get apiKey => _apiKey;

  /// APIキーが設定済みかどうか
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// 読み上げ（Cloud TTS）専用に登録されたAPIキー（未設定ならnull）
  String? get cloudTtsApiKey => _ttsApiKey;

  /// 専用のCloud TTS APIキーが登録されているかどうか
  bool get hasCloudTtsApiKey => _ttsApiKey != null && _ttsApiKey!.isNotEmpty;

  /// 読み上げに使うAPIキー。専用キーが無ければGeminiのキーを流用する。
  ///
  /// AI StudioのキーとCloud TTSが同じGoogle Cloudプロジェクトにあるなら
  /// 1つで足りる。別プロジェクトのキーが必要な場合だけ設定画面で登録する。
  String? get ttsApiKey => hasCloudTtsApiKey ? _ttsApiKey : _apiKey;

  /// 独り言トレーニングのデフォルト発話時間（秒）
  int get monologueSeconds => _monologueSeconds;

  /// 現在の学習対象言語
  LearningLanguage get learningLanguage => _learningLanguage;

  /// 現在の学習言語に対応する設定一式
  LanguageProfile get languageProfile => LanguageProfile.of(_learningLanguage);

  /// secure storageとHive boxから設定をロードする。アプリ起動時に一度呼ぶ。
  Future<void> init() async {
    _apiKey = await _secureStorage.read(key: apiKeyStorageKey);
    _ttsApiKey = await _secureStorage.read(key: ttsApiKeyStorageKey);
    _monologueSeconds =
        (_box.get(_monologueSecondsKey) as int?) ?? defaultMonologueSeconds;
    final languageName = _box.get(_learningLanguageKey) as String?;
    _learningLanguage = LearningLanguage.values.firstWhere(
      (language) => language.name == languageName,
      orElse: () => defaultLearningLanguage,
    );
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

  /// 読み上げ（Cloud TTS）専用のAPIキーを保存する。
  Future<void> setCloudTtsApiKey(String key) async {
    await _secureStorage.write(key: ttsApiKeyStorageKey, value: key);
    _ttsApiKey = key;
    notifyListeners();
  }

  /// 読み上げ（Cloud TTS）専用のAPIキーを削除する。
  /// 削除後は[ttsApiKey]がGeminiのキーを流用する。
  Future<void> deleteCloudTtsApiKey() async {
    await _secureStorage.delete(key: ttsApiKeyStorageKey);
    _ttsApiKey = null;
    notifyListeners();
  }

  /// 独り言トレーニングのデフォルト発話時間（秒）を変更する。
  Future<void> setMonologueSeconds(int seconds) async {
    _monologueSeconds = seconds;
    await _box.put(_monologueSecondsKey, seconds);
    notifyListeners();
  }

  /// 学習対象言語を切り替える。
  Future<void> setLearningLanguage(LearningLanguage language) async {
    _learningLanguage = language;
    await _box.put(_learningLanguageKey, language.name);
    notifyListeners();
  }
}
