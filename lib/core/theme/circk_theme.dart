import 'package:flutter/material.dart';

/// Circk / matchday design tokens.
///
/// Ported from the design bundle's `styles.css` (`:root` custom properties).
/// The source values are authored in oklch; they are converted here to the
/// nearest sRGB and exposed as [Color]s so the whole app can share one palette.
abstract final class CkColors {
  // Ink / text ramp
  static const ink = Color(0xFF161107); // oklch(0.18 0.02 80)
  static const ink2 = Color(0xFF332D23); // oklch(0.30 0.02 80)
  static const muted = Color(0xFF6F685C); // oklch(0.52 0.02 80)
  static const soft = Color(0xFFA8A49E); // oklch(0.72 0.01 80)

  // Surfaces
  static const paper = Color(0xFFFDFAF4); // oklch(0.985 0.008 85)
  static const paper2 = Color(0xFFF6F3EC); // oklch(0.965 0.010 85)
  static const surface = Color(0xFFFDFCF8); // oklch(0.99 0.005 85)

  // Lines
  static const line = Color(0xFFE0DED8); // oklch(0.90 0.008 85)
  static const hairline = Color(0xFFEAE7E2); // oklch(0.93 0.008 85)

  // Accents
  static const red = Color(0xFFE24A3F); // oklch(0.62 0.19 28)
  static const redSoft = Color(0xFFFFD9D2); // oklch(0.92 0.05 28)
  static const green = Color(0xFF338946); // oklch(0.56 0.13 148)
  static const greenSoft = Color(0xFFCFEED2); // oklch(0.92 0.05 148)
  static const amber = Color(0xFFE6AC3D); // oklch(0.78 0.14 80)
  static const cream = Color(0xFFF8EAC6); // oklch(0.94 0.05 90)
  static const creamBorder = Color(0xFFDED0AC); // oklch(0.86 0.05 90)
}

/// Radii from styles.css (`--r-*`).
abstract final class CkRadii {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

/// Typography helpers.
///
/// `Inter Tight` is the display face (wordmark, headlines), `Inter` is the body
/// face, `JetBrains Mono` is the mono face (eyebrows, OR divider, tabular nums).
///
/// Fonts are bundled as variable assets (see `pubspec.yaml` → `flutter: fonts`),
/// so these are plain [TextStyle]s with a `fontFamily` — no network fetch.
abstract final class CkType {
  // Family names MUST match the `family:` entries declared in pubspec.yaml.
  static const _display = 'Inter Tight';
  static const _body = 'Inter';
  static const _mono = 'JetBrains Mono';

  static TextStyle display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = -0.02,
    double? height,
    Color color = CkColors.ink,
  }) => TextStyle(
    fontFamily: _display,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing * fontSize,
    height: height,
    color: color,
  );

  static TextStyle body({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color color = CkColors.ink,
  }) => TextStyle(
    fontFamily: _body,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  static TextStyle mono({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.14,
    Color color = CkColors.muted,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing * fontSize,
    color: color,
  );
}

/// The app-wide light theme built from the Circk tokens.
ThemeData buildCirckTheme() {
  const scheme = ColorScheme.light(
    primary: CkColors.ink,
    onPrimary: CkColors.paper,
    secondary: CkColors.red,
    onSecondary: CkColors.paper,
    surface: CkColors.paper,
    onSurface: CkColors.ink,
    error: CkColors.red,
    onError: CkColors.paper,
    outline: CkColors.line,
    outlineVariant: CkColors.hairline,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CkColors.paper,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: CkColors.ink,
      displayColor: CkColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CkColors.ink,
        foregroundColor: CkColors.paper,
        disabledBackgroundColor: CkColors.ink.withValues(alpha: 0.35),
        disabledForegroundColor: CkColors.paper.withValues(alpha: 0.9),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CkRadii.md),
        ),
        textStyle: CkType.body(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: CkColors.paper,
        foregroundColor: CkColors.ink,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: CkColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CkRadii.md),
        ),
        textStyle: CkType.body(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: CkColors.red),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CkColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: CkType.body(fontSize: 16, color: CkColors.soft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CkColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CkColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: CkColors.ink,
      contentTextStyle: TextStyle(color: CkColors.paper),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
