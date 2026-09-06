import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// pj-walter のデザインシステム（Klook風: 白基調＋オレンジ）で使う色定数。
///
/// 画面コードに生の [Color] を書かず、必ずここの定数を経由すること。
abstract final class AppColors {
  /// プライマリカラー（オレンジ）
  static const Color primary = Color(0xFFFF5B00);

  /// プライマリの押下時カラー
  static const Color primaryPressed = Color(0xFFE64F00);

  /// プライマリの薄背景（チップの選択状態などに使用）
  static const Color primarySurface = Color(0xFFFFF3EC);

  /// 主テキストカラー
  static const Color textPrimary = Color(0xFF212121);

  /// 副テキストカラー
  static const Color textSecondary = Color(0xFF757575);

  /// 背景（白）
  static const Color background = Color(0xFFFFFFFF);

  /// セクション区切り・ページ背景
  static const Color pageBackground = Color(0xFFF5F6F8);

  /// 成功・正解カラー
  static const Color success = Color(0xFF0BA05F);

  /// エラー・要復習カラー
  static const Color error = Color(0xFFD32F2F);

  /// スコア良（成功と同色）
  static const Color scoreGood = Color(0xFF0BA05F);

  /// スコア中
  static const Color scoreMedium = Color(0xFFF5A623);

  /// スコア低（エラーと同色）
  static const Color scoreLow = Color(0xFFD32F2F);

  /// カード・チップなどの枠線カラー
  static const Color border = Color(0xFFEEEEEE);

  /// ヒーローカード用のプライマリグラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7A2E), Color(0xFFFF5B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// スコア良のバッジ・ハイライト背景
  static const Color scoreGoodSurface = Color(0xFFE6F7EF);

  /// スコア中のバッジ・ハイライト背景
  static const Color scoreMediumSurface = Color(0xFFFEF3DC);

  /// スコア低のバッジ・ハイライト背景
  static const Color scoreLowSurface = Color(0xFFFDECEC);
}

/// アプリ全体のスタイル定数・[ThemeData] を定義する。
abstract final class AppTheme {
  /// カードの角丸
  static const double cardRadius = 16;

  /// ボタンの角丸
  static const double buttonRadius = 14;

  /// ピル型チップの角丸（実質的な円形）
  static const double pillRadius = 999;

  /// CTAボタンの高さ
  static const double buttonHeight = 52;

  static ThemeData get light => build();

  /// アプリのライトテーマを組み立てる。
  ///
  /// [webFonts] を false にすると Google Fonts（Noto Sans JP）を使わず
  /// システムフォントだけで組む。ゴールデンテストや Widgetbook のように
  /// ネットワークからフォントを取得できない・したくない環境向け。
  /// 色・余白・コンポーネントテーマはどちらでも同じ。
  static ThemeData build({bool webFonts = true}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.error,
    );

    // デザイン指定のNoto Sans JP（未取得環境ではシステムフォントにフォールバック）
    final baseTextTheme = webFonts
        ? GoogleFonts.notoSansJpTextTheme()
        : const TextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: webFonts ? GoogleFonts.notoSansJp().fontFamily : null,
      fontFamilyFallback: const [
        'Hiragino Sans',
        'Noto Sans CJK JP',
        'sans-serif',
      ],
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? AppColors.primaryPressed.withValues(alpha: 0.1)
                    : null,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(buttonHeight),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        bodyLarge: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        bodySmall: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
