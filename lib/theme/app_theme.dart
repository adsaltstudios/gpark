import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds light and dark ThemeData for gPark.
abstract final class AppTheme {
  static ThemeData light() {
    const primary = AppColors.lightPrimary;
    const surface = AppColors.lightSurface;
    const onSurface = AppColors.lightTextPrimary;
    const error = AppColors.lightError;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: AppColors.lightOnPrimary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
      outline: AppColors.lightDivider,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(onSurface, AppColors.lightTextSecondary),
      cardColor: AppColors.lightCard,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    const primary = AppColors.darkPrimary;
    const surface = AppColors.darkSurface;
    const onSurface = AppColors.darkTextPrimary;
    const error = AppColors.darkError;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: AppColors.darkOnPrimary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
      outline: AppColors.darkDivider,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(onSurface, AppColors.darkTextSecondary),
      cardColor: AppColors.darkCard,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Color cardColor,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: cardColor,
      dividerColor: colorScheme.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide(color: colorScheme.outline, width: 1)
              : BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isDark ? 2 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.outline.withValues(alpha: 0.3)
            : colorScheme.outline.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
