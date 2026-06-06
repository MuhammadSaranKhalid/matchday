import 'package:flutter/material.dart';

/// matchday design tokens.
///
/// The neutral ramp + the brand red/cream are the exact values from the
/// **matchday Brand Sheet** ("One ink · one earned red · warm paper"). The
/// functional status colors (green/amber and their soft tints) are not part of
/// the brand palette, so they're kept as-is.
abstract final class CkColors {
  // Ink / text ramp — matchday brand sheet
  static const ink = Color(0xFF29251E);
  static const ink2 = Color(0xFF4A4339);
  static const muted = Color(0xFF8A8170);
  static const soft = Color(0xFFB9B1A2);

  // Surfaces — warm paper
  static const paper = Color(0xFFFBFAF6);
  static const paper2 = Color(0xFFF3F0E9);
  static const surface = Color(0xFFFFFFFF);

  // Lines
  static const line = Color(0xFFE6E2D9);
  static const hairline = Color(0xFFEEEBE3);

  // Accents — Cricket Red is the one earned accent; Seam Cream is the ball seam
  static const red = Color(0xFFDC4D32); // Cricket Red
  static const redSoft = Color(0xFFF7E6E1);
  static const green = Color(0xFF338946); // status only (not in brand sheet)
  static const greenSoft = Color(0xFFCFEED2); // status only
  static const amber = Color(0xFFE6AC3D); // status only
  static const cream = Color(0xFFF4ECDD); // Seam Cream
  static const creamBorder = Color(0xFFDED0AC);
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
