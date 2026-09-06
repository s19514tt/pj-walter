import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.xxx` で ARB の文言を引くための拡張。
///
/// UI 文言はすべて `app_ja.arb` に置き、`lib/` に直書きしない（DESIGN.md「i18n」）。
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
