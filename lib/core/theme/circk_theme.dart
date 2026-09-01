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
  static const canvas = Color(0xFFE5E0D6);

  // Lines
  static const line = Color(0xFFE6E2D9);
  static const hairline = Color(0xFFEEEBE3);

  // Accents — Cricket Red is the one earned accent; Seam Cream is the ball seam
  static const red = Color(0xFFDC4D32); // Cricket Red
  static const redSoft = Color(0xFFF7E6E1);
  static const redInk = Color(0xFFB23A22);
  static const redSurface = Color(0xFFFBECE9);
  static const redBorder = Color(0xFFF0C4BC);

  static const green = Color(0xFF338946); // status only
  static const greenInk = Color(0xFF276B34);
  static const greenSoft = Color(0xFFCFEED2); // status only
  static const greenSurface = Color(0xFFEAF4EC);
  static const greenBorder = Color(0xFFC4E2C9);

  static const amber = Color(0xFFE6AC3D); // status only
  static const amberInk = Color(0xFF8A6E2E);
  static const amberDark = Color(0xFF6B5414);
  static const cream = Color(0xFFF4ECDD); // Seam Cream
  static const creamBorder = Color(0xFFDED0AC);

  // The Champion Moment (artboard 34) — the one dark surface in the app.
  //
  // The ground is `ink` itself, not a separate near-black: the canvas builds
  // the finale out of the same ink the rest of the app is drawn in, raising
  // fills and hairlines off it rather than introducing a new base hue.
  static const championGround = ink; // #29251E
  static const championRaised = Color(0xFF332E26);
  static const championHairline = ink2; // #4A4339
  static const championGold = amberInk; // #8A6E2E

  // Dark-theme ink ramp, with the contrast the canvas measured against the
  // ink ground: white 15.2:1, cream 13.0:1, creamBorder 10.0:1, tertiary 7.0:1.
  // The tertiary is deliberately NOT `muted` — on ink that measures 3.96:1 and
  // fails AA at 10–14px, the mirror of the ruling that darkened the status inks.
  static const onDarkPrimary = Color(0xFFFFFFFF);
  static const onDarkFigures = cream; // #F4ECDD
  static const onDarkSecondary = creamBorder; // #DED0AC
  static const onDarkTertiary = Color(0xFFC4B9A4);
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
        minimumSize: const Size(0, 52),
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
        minimumSize: const Size(0, 52),
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
