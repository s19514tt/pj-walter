import 'package:freezed_annotation/freezed_annotation.dart';

part 'sentence.freezed.dart';

/// 教材の1文（口頭作文で出題される日本語文と、学習言語の模範解答）。
@freezed
abstract class Sentence with _$Sentence {
  const factory Sentence({
    /// `s{level}-{連番3桁}` 形式のID（例: `s700-001`）
    required String id,

    /// 出題される日本語原文
    required String ja,

    /// 学習言語での模範解答
    required String target,

    /// テーマ（`daily` / `business` / `travel`）
    required String theme,

    /// 表現のヒント・解説
    required String tips,

    /// デッキのレベル（英語 700 / 800、中国語 3 / 4）
    required int level,

    /// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
    String? reading,
  }) = _Sentence;
}
