import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Plus Jakarta Sans everywhere; tabular figures are applied per widget
/// (amounts, times, counters) via [tabular].
ThemeData buildTheme(
  Brightness brightness, [
  Color seed = const Color(0xFF2E7D46),
  Color? seed2,
]) {
  final c = MsgColors.fromSeed(seed, brightness, seed2);
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: c.surfaceBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      surface: c.surfaceBg,
      error: c.alert,
    ),
    extensions: [c],
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(
    base.textTheme,
  ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  return base.copyWith(
    textTheme: text.copyWith(
      // Design type scale (design/docs.jsx → Typographie).
      displaySmall: text.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(
        fontSize: 13,
        color: c.textSecondary,
        height: 1.4,
      ),
      labelSmall: text.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.72,
        color: c.textSecondary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primaryText,
        minimumSize: const Size(48, 48),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink800,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surfaceCard,
      indicatorColor: c.primaryTint,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? c.primaryText
              : c.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? c.primaryText
              : c.textSecondary,
        ),
      ),
    ),
  );
}

const tabular = [FontFeature.tabularFigures()];
