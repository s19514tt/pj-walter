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

  /// 教材テーマの表示名
  ///
  /// In ja, this message translates to:
  /// **'{theme, select, daily{日常} business{ビジネス} travel{旅行} other{{theme}}}'**
  String themeLabel(String theme);

  /// No description provided for @allThemes.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get allThemes;

  /// 録音中の状態ラベル
  ///
  /// In ja, this message translates to:
  /// **'聞き取り中'**
  String get listening;

  /// 録音前の状態ラベル
  ///
  /// In ja, this message translates to:
  /// **'聞き取り前'**
  String get beforeListening;

  /// No description provided for @speak.
  ///
  /// In ja, this message translates to:
  /// **'読み上げ'**
  String get speak;

  /// No description provided for @stopSpeaking.
  ///
  /// In ja, this message translates to:
  /// **'停止'**
  String get stopSpeaking;

  /// No description provided for @retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// No description provided for @again.
  ///
  /// In ja, this message translates to:
  /// **'もう一度'**
  String get again;

  /// No description provided for @continueLabel.
  ///
  /// In ja, this message translates to:
  /// **'続ける'**
  String get continueLabel;

  /// No description provided for @abortSessionTitle.
  ///
  /// In ja, this message translates to:
  /// **'トレーニングを中断しますか？'**
  String get abortSessionTitle;

  /// No description provided for @abortSessionBody.
  ///
  /// In ja, this message translates to:
  /// **'一度中断すると、このセッションは再開できません。'**
  String get abortSessionBody;

  /// No description provided for @abortSession.
  ///
  /// In ja, this message translates to:
  /// **'中断する'**
  String get abortSession;

  /// No description provided for @skipQuestionTitle.
  ///
  /// In ja, this message translates to:
  /// **'この問題を飛ばしますか？'**
  String get skipQuestionTitle;

  /// No description provided for @skipQuestionBody.
  ///
  /// In ja, this message translates to:
  /// **'録音せずに模範解答と解説へ進みます。この問題は復習キューに登録されます。'**
  String get skipQuestionBody;

  /// No description provided for @skipQuestion.
  ///
  /// In ja, this message translates to:
  /// **'飛ばす'**
  String get skipQuestion;

  /// No description provided for @apiKeyMissingTitle.
  ///
  /// In ja, this message translates to:
  /// **'APIキーが未設定です'**
  String get apiKeyMissingTitle;

  /// No description provided for @apiKeyMissingBody.
  ///
  /// In ja, this message translates to:
  /// **'Gemini APIキーが設定されていません。設定画面から登録してください。'**
  String get apiKeyMissingBody;

  /// No description provided for @openSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get openSettings;

  /// No description provided for @review.
  ///
  /// In ja, this message translates to:
  /// **'復習'**
  String get review;

  /// スコアリングの分母
  ///
  /// In ja, this message translates to:
  /// **'/100'**
  String get scoreOutOf;

  /// No description provided for @chooseLevel.
  ///
  /// In ja, this message translates to:
  /// **'レベルを選ぶ'**
  String get chooseLevel;

  /// No description provided for @chooseTheme.
  ///
  /// In ja, this message translates to:
  /// **'テーマを選ぶ'**
  String get chooseTheme;

  /// No description provided for @countingSentences.
  ///
  /// In ja, this message translates to:
  /// **'対象文数を確認しています…'**
  String get countingSentences;

  /// 対象文数の表示
  ///
  /// In ja, this message translates to:
  /// **'対象文数: {count}文'**
  String sentenceCount(int count);

  /// No description provided for @viewSentences.
  ///
  /// In ja, this message translates to:
  /// **'教材を見る'**
  String get viewSentences;

  /// No description provided for @startTraining.
  ///
  /// In ja, this message translates to:
  /// **'トレーニング開始'**
  String get startTraining;

  /// No description provided for @noSentencesForDeck.
  ///
  /// In ja, this message translates to:
  /// **'対象の教材がありません'**
  String get noSentencesForDeck;

  /// 教材一覧のタイトル
  ///
  /// In ja, this message translates to:
  /// **'教材一覧（{deck}・{theme}）'**
  String sentenceListTitle(String deck, String theme);

  /// No description provided for @noMatchingSentences.
  ///
  /// In ja, this message translates to:
  /// **'該当する教材がありません'**
  String get noMatchingSentences;

  /// 問題番号
  ///
  /// In ja, this message translates to:
  /// **'{current} / {total}'**
  String questionProgress(int current, int total);

  /// 問題カードの見出し
  ///
  /// In ja, this message translates to:
  /// **'この日本語を{language}で'**
  String translateThisInto(String language);

  /// No description provided for @answer.
  ///
  /// In ja, this message translates to:
  /// **'答える'**
  String get answer;

  /// No description provided for @grade.
  ///
  /// In ja, this message translates to:
  /// **'採点する'**
  String get grade;

  /// No description provided for @skipQuestionLink.
  ///
  /// In ja, this message translates to:
  /// **'わからないので飛ばす'**
  String get skipQuestionLink;

  /// No description provided for @emptyTranscript.
  ///
  /// In ja, this message translates to:
  /// **'発話を聞き取れませんでした。もう一度話してください。'**
  String get emptyTranscript;

  /// No description provided for @timeoutExplanation.
  ///
  /// In ja, this message translates to:
  /// **'時間切れで回答できませんでした。模範解答を確認して復習しましょう。'**
  String get timeoutExplanation;

  /// No description provided for @skipExplanation.
  ///
  /// In ja, this message translates to:
  /// **'わからないので飛ばした問題です。模範解答を声に出して真似るところから始めましょう。'**
  String get skipExplanation;

  /// No description provided for @yourSpeechTranscript.
  ///
  /// In ja, this message translates to:
  /// **'あなたの発話（文字起こし）'**
  String get yourSpeechTranscript;

  /// No description provided for @recognizing.
  ///
  /// In ja, this message translates to:
  /// **'認識中'**
  String get recognizing;

  /// No description provided for @grading.
  ///
  /// In ja, this message translates to:
  /// **'AI採点中'**
  String get grading;

  /// No description provided for @modelAnswerAndComments.
  ///
  /// In ja, this message translates to:
  /// **'模範解答・添削コメント'**
  String get modelAnswerAndComments;

  /// No description provided for @modelAnswer.
  ///
  /// In ja, this message translates to:
  /// **'模範解答'**
  String get modelAnswer;

  /// No description provided for @explanation.
  ///
  /// In ja, this message translates to:
  /// **'解説'**
  String get explanation;

  /// No description provided for @comparisonWithModel.
  ///
  /// In ja, this message translates to:
  /// **'模範解答との比較'**
  String get comparisonWithModel;

  /// No description provided for @viewResults.
  ///
  /// In ja, this message translates to:
  /// **'結果を見る'**
  String get viewResults;

  /// No description provided for @nextQuestion.
  ///
  /// In ja, this message translates to:
  /// **'次の問題へ'**
  String get nextQuestion;

  /// No description provided for @verdictPass.
  ///
  /// In ja, this message translates to:
  /// **'合格'**
  String get verdictPass;

  /// No description provided for @verdictAlmost.
  ///
  /// In ja, this message translates to:
  /// **'あと少し'**
  String get verdictAlmost;

  /// No description provided for @verdictReview.
  ///
  /// In ja, this message translates to:
  /// **'要復習'**
  String get verdictReview;

  /// No description provided for @headlinePass.
  ///
  /// In ja, this message translates to:
  /// **'よくできました。この調子で次へ進みましょう。'**
  String get headlinePass;

  /// No description provided for @headlineAlmost.
  ///
  /// In ja, this message translates to:
  /// **'惜しい！解説を確認して仕上げましょう。'**
  String get headlineAlmost;

  /// No description provided for @headlineReview.
  ///
  /// In ja, this message translates to:
  /// **'復習キューに登録されます。模範解答を確認しましょう。'**
  String get headlineReview;

  /// 声調の気づきがあるときの総評
  ///
  /// In ja, this message translates to:
  /// **'声調が違って聞こえた音節が{count}つあります。赤いルビを確認しましょう。'**
  String headlineToneNotes(int count);

  /// No description provided for @notGraded.
  ///
  /// In ja, this message translates to:
  /// **'未採点'**
  String get notGraded;

  /// No description provided for @skippedBadge.
  ///
  /// In ja, this message translates to:
  /// **'この問題は飛ばしました'**
  String get skippedBadge;

  /// No description provided for @skippedHeadline.
  ///
  /// In ja, this message translates to:
  /// **'模範解答と解説を確認しましょう。この問題は復習キューに登録されました。'**
  String get skippedHeadline;

  /// No description provided for @yourSpeech.
  ///
  /// In ja, this message translates to:
  /// **'あなたの発話'**
  String get yourSpeech;

  /// No description provided for @noRecordingNote.
  ///
  /// In ja, this message translates to:
  /// **'録音がないため、文字起こしと修正版はありません。次に同じ問題が出たときは、模範解答をまねて声に出すところから始めましょう。'**
  String get noRecordingNote;

  /// No description provided for @questionText.
  ///
  /// In ja, this message translates to:
  /// **'問題文'**
  String get questionText;

  /// No description provided for @correctedVersion.
  ///
  /// In ja, this message translates to:
  /// **'修正版'**
  String get correctedVersion;

  /// No description provided for @noCorrections.
  ///
  /// In ja, this message translates to:
  /// **'修正なし！そのままでOKです 🎉'**
  String get noCorrections;

  /// No description provided for @legendRemoved.
  ///
  /// In ja, this message translates to:
  /// **'削除・誤り'**
  String get legendRemoved;

  /// No description provided for @legendCorrected.
  ///
  /// In ja, this message translates to:
  /// **'修正版の表現'**
  String get legendCorrected;

  /// No description provided for @rubyToneLegend.
  ///
  /// In ja, this message translates to:
  /// **'赤字のルビは上＝実際の声調（参考値）／下＝期待された声調'**
  String get rubyToneLegend;

  /// No description provided for @toneNotesTitle.
  ///
  /// In ja, this message translates to:
  /// **'気づいた点'**
  String get toneNotesTitle;

  /// No description provided for @toneNotesNote.
  ///
  /// In ja, this message translates to:
  /// **'音声認識が聞き取った声調（参考値）が模範解答のピンインと違っていた音節です。聞き取りの誤差も含まれます。'**
  String get toneNotesNote;

  /// 声調の気づきのピル
  ///
  /// In ja, this message translates to:
  /// **'{expected}声 → {actual}声'**
  String toneChange(int expected, int actual);

  /// No description provided for @summaryTitle.
  ///
  /// In ja, this message translates to:
  /// **'結果まとめ'**
  String get summaryTitle;

  /// No description provided for @sessionComplete.
  ///
  /// In ja, this message translates to:
  /// **'セッション完了'**
  String get sessionComplete;

  /// 平均スコア行
  ///
  /// In ja, this message translates to:
  /// **'平均スコア · 正答 {passing}/{total}'**
  String averageScoreLine(int passing, int total);

  /// 問ごとのトークン行
  ///
  /// In ja, this message translates to:
  /// **'入力 {input} · 出力 {output} · {cost}'**
  String usageLine(String input, String output, String cost);

  /// 入力・出力トークン
  ///
  /// In ja, this message translates to:
  /// **'入力 {input} · 出力 {output}'**
  String tokensInOut(String input, String output);

  /// 復習キュー登録の案内
  ///
  /// In ja, this message translates to:
  /// **'スコア{passing}未満の{count}問を復習キューに登録しました。明日再出題されます。'**
  String srsRegisteredNote(int passing, int count);

  /// No description provided for @backToHome.
  ///
  /// In ja, this message translates to:
  /// **'ホームに戻る'**
  String get backToHome;

  /// No description provided for @apiTokenUsage.
  ///
  /// In ja, this message translates to:
  /// **'APIトークン使用量'**
  String get apiTokenUsage;

  /// No description provided for @usageTranscription.
  ///
  /// In ja, this message translates to:
  /// **'文字起こし'**
  String get usageTranscription;

  /// No description provided for @usageCorrection.
  ///
  /// In ja, this message translates to:
  /// **'添削'**
  String get usageCorrection;

  /// No description provided for @usageSpeech.
  ///
  /// In ja, this message translates to:
  /// **'読み上げ'**
  String get usageSpeech;

  /// No description provided for @usageTotal.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get usageTotal;

  /// 思考トークン数
  ///
  /// In ja, this message translates to:
  /// **'出力のうち思考トークン {count}'**
  String thoughtTokensNote(String count);

  /// 単価の説明
  ///
  /// In ja, this message translates to:
  /// **'入力 {input} / 出力 {output} per 1M tokens'**
  String rateDescription(String input, String output);

  /// 単価の適用区分
  ///
  /// In ja, this message translates to:
  /// **'{tier, select, introductory{2026年12月31日までの導入価格} standard{2027年1月1日以降の標準価格} tts{gemini-3.1-flash-tts-preview} other{{tier}}}'**
  String pricingTierLabel(String tier);

  /// 単価の注記
  ///
  /// In ja, this message translates to:
  /// **'単価: {rate}（{tier}）。{speechNote}Gemini APIの公開価格（Standardティア）から算出した概算で、無料枠は考慮していません。'**
  String pricingNote(String rate, String tier, String speechNote);

  /// 読み上げ単価の注記
  ///
  /// In ja, this message translates to:
  /// **'読み上げは{tier}の{rate}。'**
  String pricingSpeechNote(String tier, String rate);

  /// No description provided for @noReviewSentences.
  ///
  /// In ja, this message translates to:
  /// **'復習対象の教材が見つかりませんでした'**
  String get noReviewSentences;
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
