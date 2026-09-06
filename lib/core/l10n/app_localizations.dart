import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'pj-walter'**
  String get appTitle;

  /// 学習言語の表示名
  ///
  /// In ja, this message translates to:
  /// **'{code, select, en{英語} zh{中国語} other{{code}}}'**
  String languageName(String code);

  /// 口頭作文トレーニングの呼び名（学習言語ごと）
  ///
  /// In ja, this message translates to:
  /// **'{code, select, en{口頭英作文} zh{口頭中国語作文} other{口頭作文}}'**
  String compositionTitle(String code);

  /// 独り言トレーニングの呼び名（学習言語ごと）
  ///
  /// In ja, this message translates to:
  /// **'{code, select, en{独り言英会話} zh{独り言中国語} other{独り言}}'**
  String monologueTitle(String code);

  /// デッキ選択に出すレベル名
  ///
  /// In ja, this message translates to:
  /// **'{code, select, en{TOEIC{level}点台} zh{HSK{level}級} other{{level}}}'**
  String deckLevelLabel(String code, int level);

  /// 読み表記の名前
  ///
  /// In ja, this message translates to:
  /// **'{reading, select, pinyin{ピンイン} other{{reading}}}'**
  String readingLabel(String reading);

  /// AppFailure.kind → ユーザー向け文言
  ///
  /// In ja, this message translates to:
  /// **'{kind, select, apiKeyMissing{APIキーが設定されていません。設定画面からAPIキーを登録してください。} apiKeyInvalid{APIキーが無効です。設定画面で正しいAPIキーを設定してください。} rateLimited{リクエストが多すぎます。しばらく待ってから再度お試しください。} badRequest{リクエストが不正です。入力内容を確認してください。} serverError{サーバーでエラーが発生しました。しばらくしてから再度お試しください。} unexpectedStatus{通信エラーが発生しました。しばらくしてから再度お試しください。} timeout{通信がタイムアウトしました。電波状況を確認して再度お試しください。} network{通信エラーが発生しました。ネットワーク接続を確認してください。} invalidResponse{応答を解析できませんでした。時間を置いて再度お試しください。} emptyResponse{文字起こし結果が返ってきませんでした。もう一度お試しください。} noSpeech{音声を聞き取れませんでした。もう一度お試しください。} noAudio{読み上げ音声を取得できませんでした。時間を置いて再度お試しください。} micPermission{マイクの権限が許可されていません。設定でマイクを許可してください。} playback{音声を再生できませんでした。端末の音量・サイレントモードを確認してください。} other{エラーが発生しました。もう一度お試しください。}}'**
  String failureMessage(String kind);

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// 箇条書きを1行に繋ぐときの区切り
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get listSeparator;

  /// 秒数の表示（60秒未満）
  ///
  /// In ja, this message translates to:
  /// **'{count}秒'**
  String durationSeconds(int count);

  /// 分の表示
  ///
  /// In ja, this message translates to:
  /// **'{count}分'**
  String durationMinutes(int count);

  /// 分と秒の表示
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分{seconds}秒'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsLearningLanguageSection.
  ///
  /// In ja, this message translates to:
  /// **'学習する言語'**
  String get settingsLearningLanguageSection;

  /// 学習言語の説明。levels はデッキ名を listSeparator で繋いだもの
  ///
  /// In ja, this message translates to:
  /// **'{levels}の教材で、{composition}と{monologue}のトレーニングができます。'**
  String settingsLanguageDescription(
    String levels,
    String composition,
    String monologue,
  );

  /// No description provided for @settingsApiKeySection.
  ///
  /// In ja, this message translates to:
  /// **'Gemini APIキー'**
  String get settingsApiKeySection;

  /// No description provided for @settingsApiKeyDescription.
  ///
  /// In ja, this message translates to:
  /// **'Google AI Studio（aistudio.google.com）でAPIキーを取得して入力してください。'**
  String get settingsApiKeyDescription;

  /// No description provided for @settingsApiKeyConfigured.
  ///
  /// In ja, this message translates to:
  /// **'APIキーは設定済みです'**
  String get settingsApiKeyConfigured;

  /// No description provided for @settingsApiKeyHint.
  ///
  /// In ja, this message translates to:
  /// **'APIキーを入力'**
  String get settingsApiKeyHint;

  /// No description provided for @settingsDeleteApiKey.
  ///
  /// In ja, this message translates to:
  /// **'APIキーを削除'**
  String get settingsDeleteApiKey;

  /// No description provided for @settingsApiKeySaved.
  ///
  /// In ja, this message translates to:
  /// **'APIキーを保存しました'**
  String get settingsApiKeySaved;

  /// No description provided for @settingsApiKeyDeleted.
  ///
  /// In ja, this message translates to:
  /// **'APIキーを削除しました'**
  String get settingsApiKeyDeleted;

  /// No description provided for @settingsModelSection.
  ///
  /// In ja, this message translates to:
  /// **'モデル・音声認識'**
  String get settingsModelSection;

  /// No description provided for @settingsModelLabel.
  ///
  /// In ja, this message translates to:
  /// **'使用モデル'**
  String get settingsModelLabel;

  /// No description provided for @settingsSttLabel.
  ///
  /// In ja, this message translates to:
  /// **'音声認識'**
  String get settingsSttLabel;

  /// No description provided for @settingsSttValue.
  ///
  /// In ja, this message translates to:
  /// **'話した音声をGeminiに送信して文字起こし'**
  String get settingsSttValue;

  /// No description provided for @settingsModelNote.
  ///
  /// In ja, this message translates to:
  /// **'添削・文字起こしは全てこのモデルで行い、APIキーの利用量を消費します。'**
  String get settingsModelNote;

  /// No description provided for @settingsMonologueSecondsSection.
  ///
  /// In ja, this message translates to:
  /// **'独り言のデフォルト時間'**
  String get settingsMonologueSecondsSection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
