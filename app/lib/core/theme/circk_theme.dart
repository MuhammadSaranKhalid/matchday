import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Legacy color tokens compatibility facade.
///
/// Use [Palette] from `package:matchday/core/design_system/design_system.dart`
/// for canonical design tokens.
abstract final class CkColors {
  // Ink / text ramp — Matchday brand sheet
  static const ink = Palette.ink;
  static const ink2 = Palette.ink2;
  static const muted = Palette.muted;
  static const soft = Palette.soft;

  // Surfaces — warm paper
  static const paper = Palette.paper;
  static const paper2 = Palette.paper2;
  static const surface = Palette.surface;
  static const canvas = Palette.canvas;

  // Lines
  static const line = Palette.line;
  static const hairline = Palette.hairline;

  // Accents
  static const red = Palette.red;
  static const redSoft = Palette.redSoft;
  static const redInk = Palette.redInk;
  static const redSurface = Palette.redSurface;
  static const redBorder = Palette.redBorder;

  static const green = Palette.green;
  static const greenInk = Palette.greenInk;
  static const greenSoft = Palette.greenSoft;
  static const greenSurface = Palette.greenSurface;
  static const greenBorder = Palette.greenBorder;

  static const amber = Palette.amber;
  static const amberInk = Palette.amberInk;
  static const amberDark = Palette.amberDark;
  static const cream = Palette.cream;
  static const creamBorder = Palette.creamBorder;

  // The Champion Moment (artboard 34)
  static const championGround = Palette.championGround;
  static const championRaised = Palette.championRaised;
  static const championHairline = Palette.championHairline;
  static const championGold = Palette.championGold;

  // Dark-theme ink ramp
  static const onDarkPrimary = Palette.onDarkPrimary;
  static const onDarkFigures = Palette.onDarkFigures;
  static const onDarkSecondary = Palette.onDarkSecondary;
  static const onDarkTertiary = Palette.onDarkTertiary;
}

/// Legacy radii compatibility facade.
///
/// Use [Radii] from `package:matchday/core/design_system/design_system.dart`
/// for canonical design tokens.
abstract final class CkRadii {
  static const sm = Radii.sm;
  static const md = Radii.md;
  static const lg = Radii.lg;
  static const xl = Radii.xl;
}

/// Legacy typography helpers.
///
/// Prefer [ThemeData.textTheme] or [TextTokens] from the design system.
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
    Color color = Palette.ink,
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
    Color color = Palette.ink,
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
    Color color = Palette.muted,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing * fontSize,
    color: color,
  );
}

/// Legacy theme builder facade.
///
/// Delegates directly to [buildAppTheme].
@Deprecated('Use AppTheme.light or buildAppTheme()')
ThemeData buildCirckTheme() => buildAppTheme();
