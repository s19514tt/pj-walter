import 'package:flutter/foundation.dart';

/// 口頭中国語作文ドリルの「気づいた点」1件。
///
/// 模範解答のピンイン（[expected]）と音声認識が聞き取ったピンイン（[actual]）が
/// 綴りは同じで声調だけ違った音節を表す。`utils/pinyin.dart` の決定的な比較で
/// 生成され、Geminiに声調の正誤を判定させたものではない（DESIGN.md
/// 「声調フィードバック」参照）。
@immutable
class ToneNote {
  const ToneNote({
    required this.index,
    required this.spokenIndex,
    required this.expected,
    required this.actual,
    required this.expectedTone,
    required this.actualTone,
    this.hanzi,
  });

  /// 模範解答のピンインでの音節位置（0始まり）
  final int index;

  /// 聞き取られたピンインでの音節位置（0始まり）。語順や語数が模範解答と違うと
  /// [index]とはずれる（綴りでLCS整列した結果の対応先）
  final int spokenIndex;

  /// 対応する漢字。模範解答の漢字数と音節数が一致しない（儿化など）場合はnull
  final String? hanzi;

  /// 模範解答の音節（声調記号つき、例: `shuǐ`）
  final String expected;

  /// 聞き取られた音節（声調記号つき、例: `shuì`）
  final String actual;

  /// 模範解答の声調番号（1〜4）
  final int expectedTone;

  /// 聞き取られた声調番号（1〜4）
  final int actualTone;

  factory ToneNote.fromJson(Map<String, dynamic> json) => ToneNote(
    index: (json['index'] as num).toInt(),
    spokenIndex: ((json['spokenIndex'] ?? json['index']) as num).toInt(),
    hanzi: json['hanzi'] as String?,
    expected: json['expected'] as String,
    actual: json['actual'] as String,
    expectedTone: (json['expectedTone'] as num).toInt(),
    actualTone: (json['actualTone'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'spokenIndex': spokenIndex,
    'hanzi': hanzi,
    'expected': expected,
    'actual': actual,
    'expectedTone': expectedTone,
    'actualTone': actualTone,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToneNote &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          spokenIndex == other.spokenIndex &&
          hanzi == other.hanzi &&
          expected == other.expected &&
          actual == other.actual &&
          expectedTone == other.expectedTone &&
          actualTone == other.actualTone;

  @override
  int get hashCode => Object.hash(
    index,
    spokenIndex,
    hanzi,
    expected,
    actual,
    expectedTone,
    actualTone,
  );

  @override
  String toString() =>
      'ToneNote(#$index ${hanzi ?? ''} $expected($expectedTone) → $actual($actualTone))';
}
