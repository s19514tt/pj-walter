import 'package:flutter/foundation.dart';

/// [DiffSegment]の種別。
enum DiffSegmentType {
  /// [from]・[to]の両方に共通して現れる単語
  same,

  /// [from]にのみ現れる単語（削除された）
  removed,

  /// [to]にのみ現れる単語（追加された）
  added,
}

/// [diffWords]が返す差分セグメント1件（1単語分）。
@immutable
class DiffSegment {
  const DiffSegment({required this.text, required this.type});

  /// 単語本体（元の表記のまま。大文字小文字はそのまま保持する）
  final String text;

  /// 差分種別
  final DiffSegmentType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiffSegment && text == other.text && type == other.type;

  @override
  int get hashCode => Object.hash(text, type);

  @override
  String toString() => 'DiffSegment(${type.name}, "$text")';
}

/// [from]と[to]をトークン列とみなし、トークンレベルの最長共通部分列
/// (LCS)に基づく差分を計算する。
///
/// トークン化は言語を問わず同じ規則で行う（[_tokenize]を参照）。中国語のように
/// 分かち書きしない言語では漢字1文字が1トークンになるため、空白分割のときの
/// ように「文全体が1トークン」になって差分が無意味になることがない。
///
/// 比較は大文字小文字を無視して行うが、返される[DiffSegment.text]は元の
/// 表記（大文字小文字）を保持する。
///
/// 返り値は編集スクリプト形式の単一リストで、[from]・[to]それぞれの単語順序を
/// 保ったまま並ぶ。呼び出し側は
/// - `type != DiffSegmentType.added`のセグメントだけを繋げば[from]相当の文
/// - `type != DiffSegmentType.removed`のセグメントだけを繋げば[to]相当の文
/// を再構築できる。
List<DiffSegment> diffWords(String from, String to) {
  final fromWords = _tokenize(from);
  final toWords = _tokenize(to);
  final n = fromWords.length;
  final m = toWords.length;

  // dp[i][j] = fromWords[i..] と toWords[j..] のLCS長（比較は大文字小文字無視）。
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (fromWords[i].toLowerCase() == toWords[j].toLowerCase()) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }

  final segments = <DiffSegment>[];
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (fromWords[i].toLowerCase() == toWords[j].toLowerCase()) {
      segments.add(DiffSegment(text: fromWords[i], type: DiffSegmentType.same));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      segments.add(
        DiffSegment(text: fromWords[i], type: DiffSegmentType.removed),
      );
      i++;
    } else {
      segments.add(DiffSegment(text: toWords[j], type: DiffSegmentType.added));
      j++;
    }
  }
  while (i < n) {
    segments.add(
      DiffSegment(text: fromWords[i], type: DiffSegmentType.removed),
    );
    i++;
  }
  while (j < m) {
    segments.add(DiffSegment(text: toWords[j], type: DiffSegmentType.added));
    j++;
  }
  return segments;
}

/// CJK文字は1文字を1トークン、それ以外は空白・CJK境界で区切った連続を
/// 1トークンとして切り出す。
///
/// 中国語には語の切れ目を示す空白が無いため、空白分割だけでは文全体が
/// 1トークンになってしまい差分が「全消し・全追加」になる。漢字を1文字単位で
/// 扱うことで、英語の挙動を変えずに中国語でも語レベルに近い差分が出る。
/// 句読点は前後のトークンから独立させ、記号の有無だけで差分が広がるのを防ぐ。
List<String> _tokenize(String text) {
  final tokens = <String>[];
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isEmpty) return;
    tokens.add(buffer.toString());
    buffer.clear();
  }

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_whitespace.hasMatch(char)) {
      flush();
    } else if (_standalone.hasMatch(char)) {
      flush();
      tokens.add(char);
    } else {
      buffer.write(char);
    }
  }
  flush();
  return tokens;
}

final _whitespace = RegExp(r'\s');

/// 単独で1トークンにする文字。CJK統合漢字・かな・ハングルと、全角の約物。
final _standalone = RegExp(
  r'[぀-ヿ㐀-䶿一-鿿豈-﫿가-힯]'
  r'|[　-〿！-／：-＠]',
);
