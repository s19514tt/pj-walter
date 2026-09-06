/// 教材テーマ（`daily` / `business` / `travel`）の日本語表示名。
const Map<String, String> themeLabels = {
  'daily': '日常',
  'business': 'ビジネス',
  'travel': '旅行',
};

/// テーマ識別子を日本語表示名に変換する。未知のテーマはそのまま返す。
String themeLabel(String theme) => themeLabels[theme] ?? theme;
