import 'package:flutter/material.dart';

/// The authoritative Matchday color palette.
///
/// Encodes the neutral ramp, the brand red and seam cream, functional status
/// tones, and the Champion Moment dark ground.
abstract final class Palette {
  // Ink / text ramp — Matchday brand sheet
  static const ink = Color(0xFF29251E);
  static const ink2 = Color(0xFF4A4339);
  static const muted = Color(0xFF8A8170);
  static const soft = Color(0xFFB9B1A2);

  // Surfaces — warm paper
  static const paper = Color(0xFFFBFAF6);
  static const paper2 = Color(0xFFF3F0E9);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFE5E0D6);

  // Lines & borders
  static const line = Color(0xFFE6E2D9);
  static const hairline = Color(0xFFEEEBE3);

  // Brand Accents — Cricket Red is the earned accent; Seam Cream is the ball seam
  static const red = Color(0xFFDC4D32);
  static const redSoft = Color(0xFFF7E6E1);
  static const redInk = Color(0xFFB23A22);
  static const redSurface = Color(0xFFFBECE9);
  static const redBorder = Color(0xFFF0C4BC);

  // Status — Success / Green
  static const green = Color(0xFF338946);
  static const greenInk = Color(0xFF276B34);
  static const greenSoft = Color(0xFFCFEED2);
  static const greenSurface = Color(0xFFEAF4EC);
  static const greenBorder = Color(0xFFC4E2C9);

  // Status — Warning / Amber
  static const amber = Color(0xFFE6AC3D);
  static const amberInk = Color(0xFF8A6E2E);
  static const amberDark = Color(0xFF6B5414);
  static const cream = Color(0xFFF4ECDD);
  static const creamBorder = Color(0xFFDED0AC);

  // The Champion Moment (artboard 34) — the one dark surface in the app
  static const championGround = ink;
  static const championRaised = Color(0xFF332E26);
  static const championHairline = ink2;
  static const championGold = amberInk;

  // Dark-theme ink ramp
  static const onDarkPrimary = Color(0xFFFFFFFF);
  static const onDarkFigures = cream;
  static const onDarkSecondary = creamBorder;
  static const onDarkTertiary = Color(0xFFC4B9A4);
}
