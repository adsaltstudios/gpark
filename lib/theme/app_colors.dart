import 'package:flutter/material.dart';

/// gPark color system — light and dark palettes.
abstract final class AppColors {
  // ── Brand ──
  static const Color brandBlue = Color(0xFF1A6FE8);

  // ── Light palette ──
  static const Color lightSurface = Color(0xFFF8F9FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1A6FE8);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1D27);
  static const Color lightTextSecondary = Color(0xFF5F6875);
  static const Color lightTextTertiary = Color(0xFF8E95A2);
  static const Color lightDivider = Color(0xFFE2E5EB);
  static const Color lightSuccess = Color(0xFF1B873B);
  static const Color lightWarning = Color(0xFFE5960A);
  static const Color lightError = Color(0xFFD93025);

  // ── Dark palette ──
  static const Color darkSurface = Color(0xFF0F1117);
  static const Color darkCard = Color(0xFF1A1D27);
  static const Color darkPrimary = Color(0xFF4D9FFF);
  static const Color darkOnPrimary = Color(0xFF0F1117);
  static const Color darkTextPrimary = Color(0xFFF0F1F4);
  static const Color darkTextSecondary = Color(0xFF9BA1AD);
  static const Color darkTextTertiary = Color(0xFF5F6875);
  static const Color darkDivider = Color(0xFF2A2D38);
  static const Color darkSuccess = Color(0xFF3DDC84);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkError = Color(0xFFFF5252);

  // ── Semantic (resolve via theme) ──
  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSuccess
          : lightSuccess;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkWarning
          : lightWarning;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextTertiary
          : lightTextTertiary;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkDivider
          : lightDivider;
}

/// Consistent spacing scale.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
