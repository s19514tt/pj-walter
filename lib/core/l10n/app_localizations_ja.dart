// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'pj-walter';

  @override
  String languageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': '英語',
      'zh': '中国語',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String compositionTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': '口頭英作文',
      'zh': '口頭中国語作文',
      'other': '口頭作文',
    });
    return '$_temp0';
  }

  @override
  String monologueTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': '独り言英会話',
      'zh': '独り言中国語',
      'other': '独り言',
    });
    return '$_temp0';
  }

  @override
  String deckLevelLabel(String code, int level) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': 'TOEIC$level点台',
      'zh': 'HSK$level級',
      'other': '$level',
    });
    return '$_temp0';
  }

  @override
  String readingLabel(String reading) {
    String _temp0 = intl.Intl.selectLogic(reading, {
      'pinyin': 'ピンイン',
      'other': '$reading',
    });
    return '$_temp0';
  }

  @override
  String failureMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'apiKeyMissing': 'APIキーが設定されていません。設定画面からAPIキーを登録してください。',
      'apiKeyInvalid': 'APIキーが無効です。設定画面で正しいAPIキーを設定してください。',
      'rateLimited': 'リクエストが多すぎます。しばらく待ってから再度お試しください。',
      'badRequest': 'リクエストが不正です。入力内容を確認してください。',
      'serverError': 'サーバーでエラーが発生しました。しばらくしてから再度お試しください。',
      'unexpectedStatus': '通信エラーが発生しました。しばらくしてから再度お試しください。',
      'timeout': '通信がタイムアウトしました。電波状況を確認して再度お試しください。',
      'network': '通信エラーが発生しました。ネットワーク接続を確認してください。',
      'invalidResponse': '応答を解析できませんでした。時間を置いて再度お試しください。',
      'emptyResponse': '文字起こし結果が返ってきませんでした。もう一度お試しください。',
      'noSpeech': '音声を聞き取れませんでした。もう一度お試しください。',
      'noAudio': '読み上げ音声を取得できませんでした。時間を置いて再度お試しください。',
      'micPermission': 'マイクの権限が許可されていません。設定でマイクを許可してください。',
      'playback': '音声を再生できませんでした。端末の音量・サイレントモードを確認してください。',
      'other': 'エラーが発生しました。もう一度お試しください。',
    });
    return '$_temp0';
  }
}
