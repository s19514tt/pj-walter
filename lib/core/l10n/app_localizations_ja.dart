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

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get listSeparator => '・';

  @override
  String durationSeconds(int count) {
    return '$count秒';
  }

  @override
  String durationMinutes(int count) {
    return '$count分';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLearningLanguageSection => '学習する言語';

  @override
  String settingsLanguageDescription(
    String levels,
    String composition,
    String monologue,
  ) {
    return '$levelsの教材で、$compositionと$monologueのトレーニングができます。';
  }

  @override
  String get settingsApiKeySection => 'Gemini APIキー';

  @override
  String get settingsApiKeyDescription =>
      'Google AI Studio（aistudio.google.com）でAPIキーを取得して入力してください。';

  @override
  String get settingsApiKeyConfigured => 'APIキーは設定済みです';

  @override
  String get settingsApiKeyHint => 'APIキーを入力';

  @override
  String get settingsDeleteApiKey => 'APIキーを削除';

  @override
  String get settingsApiKeySaved => 'APIキーを保存しました';

  @override
  String get settingsApiKeyDeleted => 'APIキーを削除しました';

  @override
  String get settingsModelSection => 'モデル・音声認識';

  @override
  String get settingsModelLabel => '使用モデル';

  @override
  String get settingsSttLabel => '音声認識';

  @override
  String get settingsSttValue => '話した音声をGeminiに送信して文字起こし';

  @override
  String get settingsModelNote => '添削・文字起こしは全てこのモデルで行い、APIキーの利用量を消費します。';

  @override
  String get settingsMonologueSecondsSection => '独り言のデフォルト時間';

  @override
  String themeLabel(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'daily': '日常',
      'business': 'ビジネス',
      'travel': '旅行',
      'other': '$theme',
    });
    return '$_temp0';
  }

  @override
  String get allThemes => 'すべて';

  @override
  String get listening => '聞き取り中';

  @override
  String get beforeListening => '聞き取り前';

  @override
  String get speak => '読み上げ';

  @override
  String get stopSpeaking => '停止';

  @override
  String get retry => '再試行';

  @override
  String get again => 'もう一度';

  @override
  String get continueLabel => '続ける';

  @override
  String get abortSessionTitle => 'トレーニングを中断しますか？';

  @override
  String get abortSessionBody => '一度中断すると、このセッションは再開できません。';

  @override
  String get abortSession => '中断する';

  @override
  String get skipQuestionTitle => 'この問題を飛ばしますか？';

  @override
  String get skipQuestionBody => '録音せずに模範解答と解説へ進みます。この問題は復習キューに登録されます。';

  @override
  String get skipQuestion => '飛ばす';

  @override
  String get apiKeyMissingTitle => 'APIキーが未設定です';

  @override
  String get apiKeyMissingBody => 'Gemini APIキーが設定されていません。設定画面から登録してください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get review => '復習';

  @override
  String get scoreOutOf => '/100';

  @override
  String get chooseLevel => 'レベルを選ぶ';

  @override
  String get chooseTheme => 'テーマを選ぶ';

  @override
  String get countingSentences => '対象文数を確認しています…';

  @override
  String sentenceCount(int count) {
    return '対象文数: $count文';
  }

  @override
  String get viewSentences => '教材を見る';

  @override
  String get startTraining => 'トレーニング開始';

  @override
  String get noSentencesForDeck => '対象の教材がありません';

  @override
  String sentenceListTitle(String deck, String theme) {
    return '教材一覧（$deck・$theme）';
  }

  @override
  String get noMatchingSentences => '該当する教材がありません';

  @override
  String questionProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String translateThisInto(String language) {
    return 'この日本語を$languageで';
  }

  @override
  String get answer => '答える';

  @override
  String get grade => '採点する';

  @override
  String get skipQuestionLink => 'わからないので飛ばす';

  @override
  String get emptyTranscript => '発話を聞き取れませんでした。もう一度話してください。';

  @override
  String get timeoutExplanation => '時間切れで回答できませんでした。模範解答を確認して復習しましょう。';

  @override
  String get skipExplanation => 'わからないので飛ばした問題です。模範解答を声に出して真似るところから始めましょう。';

  @override
  String get yourSpeechTranscript => 'あなたの発話（文字起こし）';

  @override
  String get recognizing => '認識中';

  @override
  String get grading => 'AI採点中';

  @override
  String get modelAnswerAndComments => '模範解答・添削コメント';

  @override
  String get modelAnswer => '模範解答';

  @override
  String get explanation => '解説';

  @override
  String get comparisonWithModel => '模範解答との比較';

  @override
  String get viewResults => '結果を見る';

  @override
  String get nextQuestion => '次の問題へ';

  @override
  String get verdictPass => '合格';

  @override
  String get verdictAlmost => 'あと少し';

  @override
  String get verdictReview => '要復習';

  @override
  String get headlinePass => 'よくできました。この調子で次へ進みましょう。';

  @override
  String get headlineAlmost => '惜しい！解説を確認して仕上げましょう。';

  @override
  String get headlineReview => '復習キューに登録されます。模範解答を確認しましょう。';

  @override
  String headlineToneNotes(int count) {
    return '声調が違って聞こえた音節が$countつあります。赤いルビを確認しましょう。';
  }

  @override
  String get notGraded => '未採点';

  @override
  String get skippedBadge => 'この問題は飛ばしました';

  @override
  String get skippedHeadline => '模範解答と解説を確認しましょう。この問題は復習キューに登録されました。';

  @override
  String get yourSpeech => 'あなたの発話';

  @override
  String get noRecordingNote =>
      '録音がないため、文字起こしと修正版はありません。次に同じ問題が出たときは、模範解答をまねて声に出すところから始めましょう。';

  @override
  String get questionText => '問題文';

  @override
  String get correctedVersion => '修正版';

  @override
  String get noCorrections => '修正なし！そのままでOKです 🎉';

  @override
  String get legendRemoved => '削除・誤り';

  @override
  String get legendCorrected => '修正版の表現';

  @override
  String get rubyToneLegend => '赤字のルビは上＝実際の声調（参考値）／下＝期待された声調';

  @override
  String get toneNotesTitle => '気づいた点';

  @override
  String get toneNotesNote =>
      '音声認識が聞き取った声調（参考値）が模範解答のピンインと違っていた音節です。聞き取りの誤差も含まれます。';

  @override
  String toneChange(int expected, int actual) {
    return '$expected声 → $actual声';
  }

  @override
  String get summaryTitle => '結果まとめ';

  @override
  String get sessionComplete => 'セッション完了';

  @override
  String averageScoreLine(int passing, int total) {
    return '平均スコア · 正答 $passing/$total';
  }

  @override
  String usageLine(String input, String output, String cost) {
    return '入力 $input · 出力 $output · $cost';
  }

  @override
  String tokensInOut(String input, String output) {
    return '入力 $input · 出力 $output';
  }

  @override
  String srsRegisteredNote(int passing, int count) {
    return 'スコア$passing未満の$count問を復習キューに登録しました。明日再出題されます。';
  }

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String get apiTokenUsage => 'APIトークン使用量';

  @override
  String get usageTranscription => '文字起こし';

  @override
  String get usageCorrection => '添削';

  @override
  String get usageSpeech => '読み上げ';

  @override
  String get usageTotal => '合計';

  @override
  String thoughtTokensNote(String count) {
    return '出力のうち思考トークン $count';
  }

  @override
  String rateDescription(String input, String output) {
    return '入力 $input / 出力 $output per 1M tokens';
  }

  @override
  String pricingTierLabel(String tier) {
    String _temp0 = intl.Intl.selectLogic(tier, {
      'introductory': '2026年12月31日までの導入価格',
      'standard': '2027年1月1日以降の標準価格',
      'tts': 'gemini-3.1-flash-tts-preview',
      'other': '$tier',
    });
    return '$_temp0';
  }

  @override
  String pricingNote(String rate, String tier, String speechNote) {
    return '単価: $rate（$tier）。${speechNote}Gemini APIの公開価格（Standardティア）から算出した概算で、無料枠は考慮していません。';
  }

  @override
  String pricingSpeechNote(String tier, String rate) {
    return '読み上げは$tierの$rate。';
  }

  @override
  String get noReviewSentences => '復習対象の教材が見つかりませんでした';
}
