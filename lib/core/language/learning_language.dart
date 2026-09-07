import 'package:flutter/foundation.dart';

/// 学習対象の言語。
enum LearningLanguage {
  /// 英語（TOEIC 700/800 相当）
  english,

  /// 中国語（HSK 3/4 相当）
  chinese,
}

/// 読み表記（ルビ）の種類。表記を持たない言語（英語）は null。
enum ReadingSystem {
  /// 声調記号付きピンイン
  pinyin,
}

/// 言語ごとに変わる振る舞いをまとめたインタフェース。
///
/// 言語を追加するときの差分はここに閉じ込める（[LanguageProfile] は
/// このインタフェースを介してしか言語固有の振る舞いを知らない）。
/// 表示名（言語名・トレーニング名・デッキ名）は持たない。UI 言語ごとに
/// 変わるため、ARB の select キー（`languageName` 等）で引く。
abstract interface class LanguageSupport {
  /// 単語が空白で区切られる言語かどうか。
  ///
  /// false の言語（中国語）では空白分割が使えないため、差分表示を文字単位で行う。
  bool get wordSeparated;

  /// 読み表記の種類。不要な言語では null。
  ///
  /// 非 null の言語では、教材の `reading`・添削応答の語ごとの読み・
  /// 文字起こしの「聞こえたままの読み」を扱う。
  ReadingSystem? get reading;

  /// 読み上げ（TTS）に使うプリセット音声名。
  String get ttsVoice;

  /// プロンプト・TTS 指示文で使う英語の言語名（例: `English`）。
  ///
  /// モデルへの指示は英語で書くため、UI 言語に依存しない名前を持つ。
  String get englishName;
}

/// 分かち書きする言語（英語など）の既定実装。
class WordSeparatedLanguage implements LanguageSupport {
  const WordSeparatedLanguage({
    required this.englishName,
    this.ttsVoice = 'Kore',
  });

  @override
  bool get wordSeparated => true;

  @override
  ReadingSystem? get reading => null;

  @override
  final String ttsVoice;

  @override
  final String englishName;
}

/// 中国語（簡体字・ピンイン）の実装。
class MandarinLanguage implements LanguageSupport {
  const MandarinLanguage();

  @override
  bool get wordSeparated => false;

  @override
  ReadingSystem? get reading => ReadingSystem.pinyin;

  @override
  String get ttsVoice => 'Kore';

  @override
  String get englishName => 'Chinese (Mandarin)';
}

/// 学習言語ごとに変わる設定をまとめた値オブジェクト。
///
/// 言語で分岐する箇所（教材アセット・Geminiプロンプト・文字起こしの言語指定・
/// 差分表示のトークン化）はすべてここと [LanguageSupport] に集約する。
/// 3言語目を足すときは[values]に1件追加し、[LanguageSupport] の実装と
/// 教材アセット、ARB の select キーを足すだけで済むようにしている。
@immutable
class LanguageProfile {
  const LanguageProfile({
    required this.language,
    required this.code,
    required this.assetDirectory,
    required this.levels,
    required this.support,
  });

  /// この設定が対象とする言語
  final LearningLanguage language;

  /// 永続化・教材ID・ARB の select キー・`learningLanguage` リクエスト項目に使う言語コード
  final String code;

  /// 教材JSONを置いているディレクトリ
  final String assetDirectory;

  /// デッキ選択に出すレベル一覧（[Sentence.level]と対応する数値。表示名は ARB の `deckLevelLabel`）
  final List<int> levels;

  /// 言語固有の振る舞い
  final LanguageSupport support;

  /// 読み表記（ルビ）を扱う言語かどうか。
  bool get hasReading => support.reading != null;

  /// 単語が空白で区切られる言語かどうか（[LanguageSupport.wordSeparated]）。
  bool get wordSeparated => support.wordSeparated;

  static const english = LanguageProfile(
    language: LearningLanguage.english,
    code: 'en',
    assetDirectory: 'assets/data/en',
    levels: [700, 800],
    support: WordSeparatedLanguage(englishName: 'English'),
  );

  static const chinese = LanguageProfile(
    language: LearningLanguage.chinese,
    code: 'zh',
    assetDirectory: 'assets/data/zh',
    levels: [3, 4],
    support: MandarinLanguage(),
  );

  static const values = <LanguageProfile>[english, chinese];

  /// [LearningLanguage]に対応する設定を返す。
  static LanguageProfile of(LearningLanguage language) =>
      values.firstWhere((profile) => profile.language == language);

  /// 保存済みデータの言語コードから設定を引く。
  ///
  /// 未知のコード（教材構成が変わった場合など）は英語にフォールバックし、
  /// 履歴や復習キューの表示が壊れないようにする。
  static LanguageProfile ofCode(String code) => values.firstWhere(
    (profile) => profile.code == code,
    orElse: () => english,
  );

  /// 教材アセットのパスを組み立てる。
  String sentencesAssetPath(int level) =>
      '$assetDirectory/sentences_$level.json';

  /// 独り言お題アセットのパス。
  String get topicsAssetPath => '$assetDirectory/topics.json';

  /// このレベルがこの言語で扱えるかどうか。
  bool hasLevel(int level) => levels.contains(level);
}
