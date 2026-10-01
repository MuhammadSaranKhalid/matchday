import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import 'layout_tokens.dart';
import 'status_colors.dart';
import 'text_tokens.dart';

/// Context extension for direct access to Matchday theme and semantic extensions.
extension DesignSystemThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  LayoutTokens get layout {
    final value = Theme.of(this).extension<LayoutTokens>();
    assert(value != null, 'LayoutTokens missing from ThemeData');
    return value ?? LayoutTokens.light;
  }

  TextTokens get textTokens {
    final value = Theme.of(this).extension<TextTokens>();
    assert(value != null, 'TextTokens missing from ThemeData');
    return value ?? TextTokens.light;
  }

  StatusColors get statusColors {
    final value = Theme.of(this).extension<StatusColors>();
    assert(value != null, 'StatusColors missing from ThemeData');
    return value ?? StatusColors.light;
  }
}

/// The authoritative Matchday application theme.
abstract final class AppTheme {
  static ThemeData get light => buildAppTheme();
}

/// Builds the standardized Matchday [TextTheme].
TextTheme buildAppTextTheme() {
  return const TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.08,
      color: Palette.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: Palette.ink,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 1.45,
      color: Palette.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.45,
      color: Palette.ink,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      height: 1.4,
      color: Palette.ink,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
  );
}

/// Constructs the primary ThemeData configured with Matchday tokens and extensions.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: Palette.ink,
    onPrimary: Palette.paper,
    secondary: Palette.red,
    onSecondary: Palette.paper,
    surface: Palette.paper,
    onSurface: Palette.ink,
    error: Palette.red,
    onError: Palette.paper,
    outline: Palette.line,
    outlineVariant: Palette.hairline,
  );

  final textTheme = buildAppTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    textTheme: textTheme,
    extensions: const [
      LayoutTokens.light,
      TextTokens.light,
      StatusColors.light,
    ],
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.ink,
        foregroundColor: Palette.paper,
        disabledBackgroundColor: Palette.ink.withValues(alpha: 0.35),
        disabledForegroundColor: Palette.paper.withValues(alpha: 0.9),
        minimumSize: Size(0, LayoutTokens.light.controlLargeHeight),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Palette.paper,
        foregroundColor: Palette.ink,
        minimumSize: Size(0, LayoutTokens.light.controlLargeHeight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: Palette.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Palette.red),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: Palette.soft,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        borderSide: const BorderSide(color: Palette.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        borderSide: const BorderSide(color: Palette.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        borderSide: const BorderSide(color: Palette.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        borderSide: const BorderSide(color: Palette.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LayoutTokens.light.controlRadius),
        borderSide: const BorderSide(color: Palette.red, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.ink,
      contentTextStyle: TextStyle(color: Palette.paper),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
