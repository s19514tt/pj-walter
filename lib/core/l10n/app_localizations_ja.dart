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
}
