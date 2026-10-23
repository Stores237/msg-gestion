import 'package:flutter/material.dart';

/// Colour tokens from design/msg-theme.css (DESIGN.md is the decision log;
/// this file is the source of truth if the two ever disagree).
@immutable
class MsgColors extends ThemeExtension<MsgColors> {
  const MsgColors({
    required this.primary,
    required this.primaryText,
    required this.primaryTint,
    required this.surfaceBg,
    required this.surfaceCard,
    required this.surfaceSunken,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.alert,
    required this.alertTint,
    required this.warn,
    required this.warnText,
    required this.warnTint,
    required this.ink800,
    this.header = const Color(0xFF1C2A20),
  });

  final Color primary;
  final Color primaryText;
  final Color primaryTint;
  final Color surfaceBg;
  final Color surfaceCard;
  final Color surfaceSunken;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color alert;
  final Color alertTint;
  final Color warn;
  final Color warnText;
  final Color warnTint;
  final Color ink800;

  /// The dark band at the top of Accueil (a deep shade of [primary]).
  final Color header;

  static const light = MsgColors(
    primary: Color(0xFF2E7D46),
    primaryText: Color(0xFF256A3A),
    primaryTint: Color(0xFFDCEBE0),
    surfaceBg: Color(0xFFF6F3EE),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF1EDE6),
    borderSubtle: Color(0xFFE3DDD2),
    borderStrong: Color(0xFFCFC7B9),
    textPrimary: Color(0xFF262420),
    textSecondary: Color(0xFF5F5A52),
    textTertiary: Color(0xFF736C61),
    alert: Color(0xFFB3502B),
    alertTint: Color(0xFFF7E4DA),
    warn: Color(0xFFA57A1C),
    warnText: Color(0xFF7A5A12),
    warnTint: Color(0xFFF1E7CF),
    ink800: Color(0xFF3A3732),
  );

  static const dark = MsgColors(
    primary: Color(0xFF2E7D46),
    primaryText: Color(0xFF7CC795),
    primaryTint: Color(0xFF1E3426),
    surfaceBg: Color(0xFF151412),
    surfaceCard: Color(0xFF1F1D1A),
    surfaceSunken: Color(0xFF282521),
    borderSubtle: Color(0xFF35322D),
    borderStrong: Color(0xFF4A463F),
    textPrimary: Color(0xFFF1EDE6),
    textSecondary: Color(0xFFBDB6AA),
    textTertiary: Color(0xFFA39C90),
    alert: Color(0xFFE5845F),
    alertTint: Color(0xFF3D2219),
    warn: Color(0xFFD6A84A),
    warnText: Color(0xFFE0BE73),
    warnTint: Color(0xFF3A3020),
    ink800: Color(0xFF3A3732),
  );

  /// The tokens with [seed] as the main colour (ThemeController): the
  /// greens of the design are replaced by shades of the chosen colour.
  static MsgColors fromSeed(Color seed, Brightness brightness) {
    final base = brightness == Brightness.dark ? dark : light;
    final isDark = brightness == Brightness.dark;
    return MsgColors(
      primary: seed,
      primaryText: isDark
          ? Color.lerp(seed, Colors.white, 0.5)!
          : Color.lerp(seed, Colors.black, 0.15)!,
      primaryTint: isDark
          ? Color.lerp(base.surfaceCard, seed, 0.28)!
          : Color.lerp(Colors.white, seed, 0.16)!,
      surfaceBg: base.surfaceBg,
      surfaceCard: base.surfaceCard,
      surfaceSunken: base.surfaceSunken,
      borderSubtle: base.borderSubtle,
      borderStrong: base.borderStrong,
      textPrimary: base.textPrimary,
      textSecondary: base.textSecondary,
      textTertiary: base.textTertiary,
      alert: base.alert,
      alertTint: base.alertTint,
      warn: base.warn,
      warnText: base.warnText,
      warnTint: base.warnTint,
      ink800: base.ink800,
      header: Color.lerp(const Color(0xFF15120D), seed, 0.3)!,
    );
  }

  @override
  MsgColors copyWith() => this;

  @override
  MsgColors lerp(ThemeExtension<MsgColors>? other, double t) =>
      t < 0.5 || other is! MsgColors ? this : other;
}

/// Spacing (8-pt grid) and radii from design/docs.jsx.
abstract final class MsgSpace {
  static const double half = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double touch = 48;
}

abstract final class MsgRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 22;
}

extension MsgThemeX on BuildContext {
  MsgColors get msg => Theme.of(this).extension<MsgColors>()!;
}
