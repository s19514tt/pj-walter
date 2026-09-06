/// Hive から読んだ Map（`Map<dynamic, dynamic>`。入れ子も同様）を
/// json_serializable が要求する `Map<String, dynamic>` に再帰的に変換する。
Map<String, dynamic> jsonMapFrom(Object raw) =>
    _convert(raw) as Map<String, dynamic>;

Object? _convert(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _convert(entry.value),
    };
  }
  if (value is List) return [for (final e in value) _convert(e)];
  return value;
}
