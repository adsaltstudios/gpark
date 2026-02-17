import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// gPark type scale using Space Mono (display/numbers) and DM Sans (body).
abstract final class AppTypography {
  /// Brand wordmark style.
  static TextStyle brand(BuildContext context) => GoogleFonts.spaceMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: -1,
      );

  /// Large ticket number display.
  static TextStyle ticketLarge(BuildContext context) => GoogleFonts.spaceMono(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 2,
      );

  /// Medium ticket number.
  static TextStyle ticketMedium(BuildContext context) => GoogleFonts.spaceMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 2,
      );

  /// Ticket number in input fields.
  static TextStyle ticketInput(BuildContext context) => GoogleFonts.spaceMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );

  /// Build full text theme with DM Sans.
  static TextTheme textTheme(Color onSurface, Color secondary) {
    final base = GoogleFonts.dmSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: onSurface,
        fontSize: 16,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 14,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: secondary,
        fontSize: 13,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondary,
        fontSize: 12,
      ),
    );
  }
}
