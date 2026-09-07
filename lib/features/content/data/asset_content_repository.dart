import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/language/learning_language.dart';
import '../domain/content_repository.dart';
import '../domain/sentence.dart';
import '../domain/topic.dart';
import 'sentence_dto.dart';
import 'topic_dto.dart';

/// [ContentRepository] のアセット実装（`assets/data/{言語}/`）。
///
/// アセットのパスは[LanguageProfile]が決めるため、言語が増えても
/// このクラスに手を入れる必要はない。一度読み込んだ結果は
/// 言語×レベルごとにメモリへキャッシュする。
class AssetContentRepository implements ContentRepository {
  final Map<String, List<Sentence>> _sentenceCache = {};
  final Map<String, List<Topic>> _topicCache = {};

  @override
  Future<List<Sentence>> sentences({
    required LanguageProfile profile,
    required int level,
    String? theme,
  }) async {
    final sentences = await _loadSentences(profile, level);
    if (theme == null) return sentences;
    return sentences.where((s) => s.theme == theme).toList();
  }

  @override
  Future<List<Topic>> topics({
    required LanguageProfile profile,
    String? theme,
  }) async {
    final loaded = await _loadTopics(profile);
    if (theme == null) return loaded;
    return loaded.where((t) => t.theme == theme).toList();
  }

  Future<List<Sentence>> _loadSentences(
    LanguageProfile profile,
    int level,
  ) async {
    final cacheKey = '${profile.code}-$level';
    final cached = _sentenceCache[cacheKey];
    if (cached != null) return cached;

    if (!profile.hasLevel(level)) {
      throw ArgumentError.value(
        level,
        'level',
        'unknown level for ${profile.code}',
      );
    }

    final raw = await rootBundle.loadString(profile.sentencesAssetPath(level));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final jsonLevel = (json['level'] as num).toInt();
    // キャッシュを呼び出し側のin-place操作（シャッフル等）から守るためunmodifiableで保持する
    final list = List<Sentence>.unmodifiable(
      (json['sentences'] as List<dynamic>).map(
        (e) => SentenceDto.fromJson(
          e as Map<String, dynamic>,
        ).toEntity(level: jsonLevel),
      ),
    );

    _sentenceCache[cacheKey] = list;
    return list;
  }

  Future<List<Topic>> _loadTopics(LanguageProfile profile) async {
    final cached = _topicCache[profile.code];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(profile.topicsAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = List<Topic>.unmodifiable(
      (json['topics'] as List<dynamic>).map(
        (e) => TopicDto.fromJson(e as Map<String, dynamic>).toEntity(),
      ),
    );

    _topicCache[profile.code] = list;
    return list;
  }
}
