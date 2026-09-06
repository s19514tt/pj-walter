import 'package:freezed_annotation/freezed_annotation.dart';

import 'tone_note.dart';

part 'drill_result.freezed.dart';

/// 語区切り1件（中国語の添削応答が返す「単語」）。
///
/// 差分表示のハイライトを1文字ずつではなく単語ずつの箱にするために使う。
/// [reading]は修正版のみ（その語のピンイン）で、発話側は null。
@freezed
abstract class WordUnit with _$WordUnit {
  const factory WordUnit({
    /// 語の表記（句読点だけの語もある）
    required String text,

    /// その語の標準的なピンイン（音節ごとに半角スペース区切り）。発話側は null
    String? reading,
  }) = _WordUnit;
}

/// 口頭作文1問分の添削結果。
///
/// 解説文（[explanation] / [comparison]）は添削リクエストの `uiLocale` の言語で書かれる。
@freezed
abstract class CompositionFeedback with _$CompositionFeedback {
  const CompositionFeedback._();

  const factory CompositionFeedback({
    /// 伝わりやすさ・正確さの総合スコア（0-100）
    required int score,

    /// score>=70相当の合否
    required bool isAcceptable,

    /// 発話を最小修正した学習言語の文
    required String corrected,

    /// 誤りの解説（`uiLocale` の言語）
    required String explanation,

    /// 模範解答との違い・どちらでも良い点の解説（`uiLocale` の言語）
    required String comparison,

    /// [corrected]の標準的なピンイン（中国語のみ。修正版のルビ表示に使う）。
    /// 英語では null。[correctedWords]があるときはそれを繋いだもの。
    String? correctedReading,

    /// [corrected]の語区切り＋語ごとのピンイン（中国語のみ。英語では null）。
    ///
    /// 差分のハイライトを単語ずつの箱にするのと、ルビを語ごとに割り当てるのに使う
    /// （語ごとなら音節数が合わない語だけルビを落とせる）。
    List<WordUnit>? correctedWords,

    /// 生徒の発話（文字起こし）の語区切り（中国語のみ。ピンインは持たない）。
    List<WordUnit>? spokenWords,
  }) = _CompositionFeedback;

  /// 時間切れ・飛ばした問題など、採点せずにローカルで組み立てる未回答の結果。
  ///
  /// `corrected` が空であることが「回答が無かった」印になる。score<70 なので
  /// 既存ロジックのまま SRS 復習キューに載る。
  factory CompositionFeedback.unanswered({required String explanation}) =>
      CompositionFeedback(
        score: 0,
        isAcceptable: false,
        corrected: '',
        explanation: explanation,
        comparison: '',
      );

  /// 回答が無いまま（時間切れ・飛ばした）確定した結果かどうか
  bool get isUnanswered => corrected.isEmpty;
}

/// 口頭作文1問分の受験結果（発話内容＋添削結果）。
@freezed
abstract class DrillResult with _$DrillResult {
  const factory DrillResult({
    /// 結果のuuid
    required String id,

    /// 出題された [Sentence] のid
    required String sentenceId,

    /// 出題文の学習言語コード（[LanguageProfile.code]）
    required String language,

    /// 出題文のデッキレベル
    required int level,

    /// 音声認識で得られたユーザーの発話文
    required String spoken,

    /// 受験日時
    required DateTime timestamp,

    /// 添削結果
    required CompositionFeedback feedback,

    /// 声調の「気づいた点」（中国語のみ。DESIGN.md「声調フィードバック」参照）。
    ///
    /// null は判定していない（英語・模範解答にピンインが無い・音節列が模範解答と
    /// 一致しなかった）。空リストは判定したが指摘なし。スコアには一切影響しない。
    List<ToneNote>? toneNotes,
  }) = _DrillResult;
}
