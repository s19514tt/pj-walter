import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.xxx` で ARB の文言を引くための拡張。
///
/// UI 文言はすべて `app_ja.arb` に置き、`lib/` に直書きしない（DESIGN.md「i18n」）。
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// ARB のキーを組み合わせた、画面をまたいで使う整形。
extension L10nFormats on AppLocalizations {
  /// 秒数を「30秒」「1分」「1分30秒」のように整形する。
  String formatDuration(int seconds) {
    if (seconds < 60) return durationSeconds(seconds);
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0
        ? durationMinutes(minutes)
        : durationMinutesSeconds(minutes, rest);
  }

  /// デッキ名を「TOEIC700点台・TOEIC800点台」のように1行に繋ぐ。
  String deckLevelList(String languageCode, List<int> levels) => levels
      .map((level) => deckLevelLabel(languageCode, level))
      .join(listSeparator);
}
