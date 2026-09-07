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

  @override
  String get chooseDuration => '発話時間を選ぶ';

  @override
  String get pickRandomTopic => 'ランダムに選ぶ';

  @override
  String get chooseTopic => 'お題を選ぶ';

  @override
  String get noMatchingTopics => '該当するお題がありません';

  @override
  String get speakAboutThisTopic => 'このお題について話す';

  @override
  String get startSpeaking => '話しはじめる';

  @override
  String get seeFeedback => 'フィードバックを見る';

  @override
  String get timeUpBeforeSpeaking => '時間切れになりました。「話しはじめる」で開始してください。';

  @override
  String get feedbackTitle => 'フィードバック';

  @override
  String get transcript => '文字起こし';

  @override
  String transcriptWithDuration(String duration) {
    return '文字起こし（$duration）';
  }

  @override
  String get correctionSuggestions => '修正提案';

  @override
  String get usefulPhrases => '使えるフレーズ';

  @override
  String get overallFeedback => '総評';

  @override
  String get done => '完了';

  @override
  String get fluency => '流暢さ';

  @override
  String get speechAmount => '発話量';

  @override
  String wordCount(int count) {
    return '$count語';
  }

  @override
  String get correctionCount => '修正点';

  @override
  String itemCount(int count) {
    return '$count件';
  }

  @override
  String get phraseCount => 'フレーズ';

  @override
  String pieceCount(int count) {
    return '$count個';
  }

  @override
  String get savePhrase => '＋保存';

  @override
  String get phraseSaved => '保存済';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabTraining => '学習';

  @override
  String get tabStats => '記録';

  @override
  String greeting(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'morning': 'おはよう',
      'afternoon': 'こんにちは',
      'other': 'こんばんは',
    });
    return '$_temp0';
  }

  @override
  String greetingWave(String greeting) {
    return '$greeting👋';
  }

  @override
  String todayLetsSpeak(String language) {
    return '今日も$languageを話そう';
  }

  @override
  String get setApiKeyBanner => 'APIキーを設定してください';

  @override
  String get streakDays => '日連続';

  @override
  String thisWeekDays(int count) {
    return '今週 $count/7日';
  }

  @override
  String todayProgress(int drills, int monologues) {
    return '今日はドリル$drills問・独り言$monologues回。いい調子です！';
  }

  @override
  String get todayNothingYet => '今日はまだ練習していません。3分だけ話してみましょう。';

  @override
  String weekdayShort(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': '月',
      '2': '火',
      '3': '水',
      '4': '木',
      '5': '金',
      '6': '土',
      '7': '日',
      'other': '$weekday',
    });
    return '$_temp0';
  }

  @override
  String get noReviewToday => '今日の復習はありません🎉';

  @override
  String get todayReview => '今日の復習';

  @override
  String reviewQueueCount(int count) {
    return '間隔反復キューに$count件たまっています';
  }

  @override
  String get trainingSection => 'トレーニング';

  @override
  String get compositionShortcutDesc => '制限時間内に発話';

  @override
  String get monologueShortcutDesc => 'お題を30秒〜3分';

  @override
  String get recentStudy => '最近の学習';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get tomorrow => '明日';

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String daysLater(int days) {
    return '$days日後';
  }

  @override
  String drillRecentMeta(String deck, int score) {
    return '$deck · $score点';
  }

  @override
  String monologueRecentMeta(String duration, int score) {
    return '$duration · 流暢さ$score';
  }

  @override
  String get chooseTraining => 'トレーニングを選ぶ';

  @override
  String compositionMenuDesc(String language) {
    return '日本語文を見て制限時間内に$languageで発話し、AIが添削します。';
  }

  @override
  String get monologueMenuDesc => 'お題について自由に話し、AIがフィードバックします。';

  @override
  String get srsIntervalNote => '1日→3日→7日→14日→30日の間隔で再出題されます';

  @override
  String daysLabel(int count) {
    return '$count日';
  }

  @override
  String startReviewBatch(int count) {
    return '$count件を一括で開始';
  }

  @override
  String get upcomingReviews => '復習予定';

  @override
  String get noUpcomingReviews => '復習予定の文はまだありません';

  @override
  String totalCount(int count) {
    return '合計$count件';
  }

  @override
  String sentenceOfDeck(String deck) {
    return '$deckの文';
  }

  @override
  String andMore(int count) {
    return 'ほか$count件';
  }

  @override
  String get phraseBook => 'フレーズ帳';

  @override
  String phraseSearchHint(String language) {
    return '$language・日本語で検索';
  }

  @override
  String get noPhrases => 'フレーズはまだ登録されていません';

  @override
  String get noMatchingPhrases => '一致するフレーズがありません';

  @override
  String get delete => '削除';

  @override
  String get deleted => '削除しました';

  @override
  String get streakDaysLabel => '連続日数';

  @override
  String get totalDrills => '総ドリル数';

  @override
  String get totalStudyMinutes => '総学習分';

  @override
  String get last7Days => '直近7日の学習量';

  @override
  String get studyCalendar => '学習カレンダー';

  @override
  String get correctionHistory => '添削履歴';

  @override
  String get noHistory => 'まだ添削履歴がありません';

  @override
  String showMore(int count) {
    return 'もっと見る（残り$count件）';
  }

  @override
  String get compositionGeneric => '口頭作文';

  @override
  String get monologueGeneric => '独り言';

  @override
  String get loading => '読み込み中…';

  @override
  String get sentenceNotFound => '（教材が見つかりません）';

  @override
  String get sourceText => '原文';

  @override
  String get topicLabel => 'お題';

  @override
  String get transcriptRaw => 'トランスクリプト';

  @override
  String scoreLabel(int score) {
    return 'スコア $score';
  }

  @override
  String get prevMonth => '前月';

  @override
  String get nextMonth => '翌月';

  @override
  String yearMonth(int year, int month) {
    return '$year年$month月';
  }
}
