import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/learning_language.dart';
import '../models/sentence.dart';
import '../models/topic.dart';

/// 教材JSON（`assets/data/{言語}/`）のロード・キャッシュ・フィルタを担うリポジトリ。
///
/// アセットのパスは[LanguageProfile]が決めるため、言語が増えても
/// このクラスに手を入れる必要はない。一度読み込んだ結果は
/// 言語×レベルごとにメモリへキャッシュする。
class SentenceRepository {
  final Map<String, List<Sentence>> _sentenceCache = {};
  final Map<String, List<Topic>> _topicCache = {};

  /// 指定言語・レベルの教材文一覧を取得する。
  ///
  /// [theme] を指定すると `daily` / `business` / `travel` でフィルタする。
  /// null または未指定の場合は全テーマを返す。
  Future<List<Sentence>> sentencesFor({
    required LanguageProfile profile,
    required int level,
    String? theme,
  }) async {
    final sentences = await _loadSentences(profile, level);
    if (theme == null) return sentences;
    return sentences.where((s) => s.theme == theme).toList();
  }

  /// 指定言語の独り言お題一覧を取得する。
  ///
  /// [theme] を指定すると `daily` / `business` / `travel` でフィルタする。
  /// null または未指定の場合は全テーマを返す。
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
      throw ArgumentError.value(level, 'level', '${profile.label}に存在しないレベルです');
    }

    final raw = await rootBundle.loadString(profile.sentencesAssetPath(level));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final jsonLevel = (json['level'] as num).toInt();
    // キャッシュを呼び出し側のin-place操作（シャッフル等）から守るためunmodifiableで保持する
    final list = List<Sentence>.unmodifiable(
      (json['sentences'] as List<dynamic>).map(
        (e) => Sentence.fromJson({
          ...e as Map<String, dynamic>,
          'level': jsonLevel,
        }),
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
        (e) => Topic.fromJson(e as Map<String, dynamic>),
      ),
    );

    _topicCache[profile.code] = list;
    return list;
  }
}
