import 'package:freezed_annotation/freezed_annotation.dart';

part 'tone_note.freezed.dart';

/// 口頭中国語作文ドリルの「気づいた点」1件。
///
/// 模範解答のピンイン（[expected]）と音声認識が聞き取ったピンイン（[actual]）が
/// 綴りは同じで声調だけ違った音節を表す。`pinyin.dart` の決定的な比較で
/// 生成され、Geminiに声調の正誤を判定させたものではない（DESIGN.md
/// 「声調フィードバック」参照）。
@freezed
abstract class ToneNote with _$ToneNote {
  const factory ToneNote({
    /// 模範解答のピンインでの音節位置（0始まり）
    required int index,

    /// 聞き取られたピンインでの音節位置（0始まり）。語順や語数が模範解答と違うと
    /// [index]とはずれる（綴りでLCS整列した結果の対応先）
    required int spokenIndex,

    /// 模範解答の音節（声調記号つき、例: `shuǐ`）
    required String expected,

    /// 聞き取られた音節（声調記号つき、例: `shuì`）
    required String actual,

    /// 模範解答の声調番号（1〜4）
    required int expectedTone,

    /// 聞き取られた声調番号（1〜4）
    required int actualTone,

    /// 対応する漢字。模範解答の漢字数と音節数が一致しない（儿化など）場合はnull
    String? hanzi,
  }) = _ToneNote;
}
