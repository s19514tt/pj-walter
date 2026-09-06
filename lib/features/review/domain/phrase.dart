import 'package:freezed_annotation/freezed_annotation.dart';

part 'phrase.freezed.dart';

/// フレーズ帳の1エントリ。
@freezed
abstract class Phrase with _$Phrase {
  const factory Phrase({
    /// エントリのuuid
    required String id,

    /// 学習言語での表現
    required String target,

    /// 日本語訳
    required String ja,

    /// 追加元（例: お題ID）
    required String source,

    /// 追加日時
    required DateTime createdAt,
  }) = _Phrase;
}
