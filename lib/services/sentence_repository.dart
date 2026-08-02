import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/sentence.dart';
import '../models/topic.dart';

/// 教材JSON（`assets/data/`）のロード・キャッシュ・フィルタを担うリポジトリ。
///
/// `sentences_700.json` / `sentences_800.json` / `topics.json` を
/// `rootBundle` から読み込み、一度読み込んだ結果はメモリにキャッシュする。
class SentenceRepository {
  final Map<int, List<Sentence>> _sentenceCache = {};
  List<Topic>? _topicCache;

  static const _sentenceAssetPaths = {
    700: 'assets/data/sentences_700.json',
    800: 'assets/data/sentences_800.json',
  };

  static const _topicsAssetPath = 'assets/data/topics.json';

  /// 指定レベルの教材文一覧を取得する。
  ///
  /// [theme] を指定すると `daily` / `business` / `travel` でフィルタする。
  /// null または未指定の場合は全テーマを返す。
  Future<List<Sentence>> sentencesFor({
    required int level,
    String? theme,
  }) async {
    final sentences = await _loadSentences(level);
    if (theme == null) return sentences;
    return sentences.where((s) => s.theme == theme).toList();
  }

  /// 独り言英会話のお題一覧を取得する。
  ///
  /// [theme] を指定すると `daily` / `business` / `travel` でフィルタする。
  /// null または未指定の場合は全テーマを返す。
  Future<List<Topic>> topics({String? theme}) async {
    final loaded = await _loadTopics();
    if (theme == null) return loaded;
    return loaded.where((t) => t.theme == theme).toList();
  }

  Future<List<Sentence>> _loadSentences(int level) async {
    final cached = _sentenceCache[level];
    if (cached != null) return cached;

    final assetPath = _sentenceAssetPaths[level];
    if (assetPath == null) {
      throw ArgumentError.value(level, 'level', '対応していないレベルです');
    }

    final raw = await rootBundle.loadString(assetPath);
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

    _sentenceCache[level] = list;
    return list;
  }

  Future<List<Topic>> _loadTopics() async {
    final cached = _topicCache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_topicsAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = List<Topic>.unmodifiable(
      (json['topics'] as List<dynamic>).map(
        (e) => Topic.fromJson(e as Map<String, dynamic>),
      ),
    );

    _topicCache = list;
    return list;
  }
}
