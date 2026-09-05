import 'package:flutter/foundation.dart';

/// 学習対象の言語。
enum LearningLanguage {
  /// 英語（TOEIC 700/800 相当）
  english,

  /// 中国語（HSK 3/4 相当）
  chinese,
}

/// デッキ選択に出すレベル1件。
@immutable
class DeckLevel {
  const DeckLevel({required this.value, required this.label});

  /// [Sentence.level]と対応する数値（英語なら700/800、中国語なら3/4）
  final int value;

  /// 画面に出す表記（例: `TOEIC700点台` / `HSK3級`）
  final String label;
}

/// 学習言語ごとに変わる設定をまとめた値オブジェクト。
///
/// 言語で分岐する箇所（教材アセット・Geminiプロンプト・文字起こしの言語指定・
/// 差分表示のトークン化・画面の呼び名）はすべてここに集約する。
/// 3言語目を足すときは[values]に1件追加するだけで済むようにしている。
@immutable
class LanguageProfile {
  const LanguageProfile({
    required this.language,
    required this.code,
    required this.label,
    required this.compositionTitle,
    required this.monologueTitle,
    required this.assetDirectory,
    required this.levels,
    required this.readingLabel,
    required this.wordSeparated,
  });

  /// この設定が対象とする言語
  final LearningLanguage language;

  /// 永続化・教材IDに使う言語コード
  final String code;

  /// 設定画面などに出す言語名
  final String label;

  /// 口頭作文トレーニングの呼び名
  final String compositionTitle;

  /// 独り言トレーニングの呼び名
  final String monologueTitle;

  /// 教材JSONを置いているディレクトリ
  final String assetDirectory;

  /// デッキ選択に出すレベル一覧
  final List<DeckLevel> levels;

  /// [level]に対応する表示ラベル。未知のレベルはレベル値をそのまま返す。
  String levelLabel(int level) => levels
      .firstWhere(
        (deck) => deck.value == level,
        orElse: () => DeckLevel(value: level, label: '$level'),
      )
      .label;

  /// 読み仮名・発音表記のラベル（英語のように不要なら null）
  final String? readingLabel;

  /// 単語が空白で区切られる言語かどうか。
  ///
  /// falseの中国語では空白分割が使えないため、差分表示を文字単位で行う。
  final bool wordSeparated;

  static const english = LanguageProfile(
    language: LearningLanguage.english,
    code: 'en',
    label: '英語',
    compositionTitle: '口頭英作文',
    monologueTitle: '独り言英会話',
    assetDirectory: 'assets/data/en',
    levels: [
      DeckLevel(value: 700, label: 'TOEIC700点台'),
      DeckLevel(value: 800, label: 'TOEIC800点台'),
    ],
    readingLabel: null,
    wordSeparated: true,
  );

  static const chinese = LanguageProfile(
    language: LearningLanguage.chinese,
    code: 'zh',
    label: '中国語',
    compositionTitle: '口頭中国語作文',
    monologueTitle: '独り言中国語',
    assetDirectory: 'assets/data/zh',
    levels: [
      DeckLevel(value: 3, label: 'HSK3級'),
      DeckLevel(value: 4, label: 'HSK4級'),
    ],
    readingLabel: 'ピンイン',
    wordSeparated: false,
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
  bool hasLevel(int level) => levels.any((deck) => deck.value == level);
}
