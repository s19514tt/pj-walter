import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic.freezed.dart';

/// 独り言トレーニングのお題。
@freezed
abstract class Topic with _$Topic {
  const factory Topic({
    /// `t-{連番3桁}` 形式のID（例: `t-001`）
    required String id,

    /// 日本語の指示文
    required String ja,

    /// 学習言語での指示文
    required String target,

    /// テーマ（`daily` / `business` / `travel`）
    required String theme,

    /// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
    String? reading,
  }) = _Topic;
}
