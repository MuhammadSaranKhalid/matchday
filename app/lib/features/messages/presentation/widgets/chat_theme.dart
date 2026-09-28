import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

/// Design tokens derived directly from the Matchday Stitch Design System
/// (Clubhouse Utility aesthetic).
abstract final class ChatTheme {
  // ─── Colors ─────────────────────────────────────────────────────────────
  /// Warm, organic off-white foundation canvas matching main pages (CkColors.paper #FBFAF6).
  static const clubhouseCanvas = CkColors.paper;

  /// Dense charcoal for primary text, titles, and self-sent bubbles (#24231F).
  static const charcoalInk = Color(0xFF24231F);

  /// Singular chromatic brand accent (#E94D3A) for unread badges, sends,
  /// selection highlights, and key icons.
  static const matchDayCoral = Color(0xFFE94D3A);

  /// Crisp white for incoming message bubbles and cards (#FFFFFF).
  static const pureSurface = Color(0xFFFFFFFF);

  /// 1px structural hairline border color (#E8E3DA).
  static const hairlineSand = Color(0xFFE8E3DA);

  /// Tinted fill for input fields, search background, and chips (#F1EEE7).
  static const softSandFill = Color(0xFFF1EEE7);

  /// Low-prominence captions, timestamps, and inactive icons (#7C776F).
  static const mutedStone = Color(0xFF7C776F);

  /// Status colors
  static const successMintBg = Color(0xFFE8F5EA);
  static const successMintText = Color(0xFF4E7D58);
  static const warningSandBg = Color(0xFFF8EFE1);
  static const warningSandText = Color(0xFF8A6132);
  static const destructiveCoralBg = Color(0xFFFCEBE8);
  static const destructiveCoralText = Color(0xFFC6382A);

  /// Container tones
  static const surfaceContainerHigh = Color(0xFFEAE8E3);
  static const surfaceContainerHighest = Color(0xFFE4E2DD);

  // ─── Typography ──────────────────────────────────────────────────────────
  static const _displayFont = 'Inter Tight';
  static const _bodyFont = 'Inter';
  static const _monoFont = 'JetBrains Mono';

  static TextStyle headlineLg({Color color = charcoalInk}) => TextStyle(
        fontFamily: _displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.27,
        color: color,
      );

  static TextStyle headlineMd({Color color = charcoalInk}) => TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: color,
      );

  static TextStyle headlineSm({Color color = charcoalInk}) => TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.35,
        color: color,
      );

  static TextStyle rowTitle({Color color = charcoalInk}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.33,
        color: color,
      );

  static TextStyle sectionHeader({Color color = mutedStone}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 1.35,
        color: color,
      );

  static TextStyle bodyMd({Color color = charcoalInk, FontWeight fontWeight = FontWeight.w400}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: fontWeight,
        height: 1.42,
        color: color,
      );

  static TextStyle bodySm({Color color = charcoalInk, FontWeight fontWeight = FontWeight.w400}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: fontWeight,
        height: 1.4,
        color: color,
      );

  static TextStyle button({Color color = charcoalInk}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.38,
        color: color,
      );

  static TextStyle badge({Color color = mutedStone}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.27,
        color: color,
      );

  static TextStyle metadata({Color color = mutedStone, FontWeight fontWeight = FontWeight.w500}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: fontWeight,
        height: 1.27,
        color: color,
      );

  static TextStyle timestamp({Color color = mutedStone}) => TextStyle(
        fontFamily: _monoFont,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.2,
        color: color,
      );

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static const whisperShadow = [
    BoxShadow(
      color: Color.fromRGBO(36, 35, 31, 0.05),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const floatingCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(36, 35, 31, 0.08),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const sendButtonShadow = [
    BoxShadow(
      color: Color.fromRGBO(233, 77, 58, 0.28),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
}
