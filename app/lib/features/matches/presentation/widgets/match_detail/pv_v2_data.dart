import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

// ── Crest ───────────────────────────────────────────────────────────────────

/// A side's crest: initials, full name, fill colour, and optional logo image.
@immutable
class PvCrest {
  const PvCrest({
    required this.short,
    required this.name,
    required this.color,
    this.logoUrl,
  });
  final String short;
  final String name;
  final Color color;
  final String? logoUrl;
}

/// Neutral fallback crest (e.g. the "me" side of an outbound challenge when the
/// user has no team to stand in for it).
const PvCrest kPvUnknownCrest = PvCrest(
  short: '··',
  name: 'Your team',
  color: CkColors.muted,
);

// ── Matches ─────────────────────────────────────────────────────────────────

enum PvPhase { live, startsSoon, scheduled, awaitingReply, completed }

@immutable
class PvMatch {
  const PvMatch({
    required this.id,
    required this.phase,
    required this.me,
    required this.them,
    // DISPLAY ONLY.
    //
    // Never use this field to authorize a privileged action.
    required this.role,
    required this.when,
    required this.venue,
    required this.sub,
    this.oversPerInnings,
    this.ballsPerOver,
    this.playersPerTeam,
    this.ballType,
    this.formatCode,
    // Authorization-derived UI capabilities.
    this.canStartMatch = false,
    this.canCancelMatch = false,
    // Explicit hero labels avoid assuming that "me" is always Team A.
    this.meSubtitle,
    this.themSubtitle,
    this.lineupSet,
    this.scoreA,
    this.scoreB,
    this.result,
  });

  final String id;
  final PvPhase phase;

  /// The side associated with the signed-in user where possible.
  ///
  /// Unlike the old mapper, this is NOT blindly Team A.
  final PvCrest me;

  /// The other side.
  final PvCrest them;

  /// Presentation relationship only:
  ///
  /// owner | manager | captain | player | official | viewer
  ///
  /// This value MUST NOT drive privileged actions.
  final String role;
  final String when;
  final String venue;
  final String sub;
  final int? oversPerInnings;
  final int? ballsPerOver;
  final int? playersPerTeam;
  final String? ballType;
  final String? formatCode;

  /// True only when effective `cricket.match.setup` allows the caller to
  /// enter/continue the CURRENT Match Start phase.
  final bool canStartMatch;

  /// True only when effective `match.cancel` allows cancellation and this is a
  /// cancellable non-tournament pre-live fixture.
  final bool canCancelMatch;

  /// Optional explicit labels for the hero.
  ///
  /// Examples:
  /// "you · manager"
  /// "you · captain"
  /// "opponent"
  /// "team"
  final String? meSubtitle;
  final String? themSubtitle;

  final bool? lineupSet;
  final String? scoreA;
  final String? scoreB;
  final String? result;

  /// Backward-compatible display getter.
  ///
  /// Do not use for RBAC.
  bool get isCaptain => role == 'captain' || role == 'owner';

  String get meSubtitleDisplay => meSubtitle ?? 'you · $role';
  String get themSubtitleDisplay => themSubtitle ?? 'opponent';

  String get formatDisplay {
    final players = playersPerTeam ?? 11;
    final code =
        formatCode ??
        (oversPerInnings == 20
            ? 'T20'
            : (oversPerInnings != null && oversPerInnings! > 0
                ? '${oversPerInnings}O'
                : 'Cricket'));
    return '$code · $players-a-side';
  }

  String get oversDisplay {
    final overs =
        (oversPerInnings == null || oversPerInnings == 0)
            ? 'Unlimited'
            : '$oversPerInnings';
    final balls = ballsPerOver ?? 6;
    return '$overs · $balls-ball';
  }

  String get ballDisplay {
    if (ballType == null || ballType!.isEmpty) return 'Tape';
    return ballType![0].toUpperCase() + ballType!.substring(1).toLowerCase();
  }
}

// ── Teams ───────────────────────────────────────────────────────────────────

@immutable
class PvTeam {
  const PvTeam({
    required this.id,
    required this.crest,
    required this.role, // captain | owner | player
    required this.subtitle,
    this.needs = const [],
  });

  final String id;
  final PvCrest crest;
  final String role;
  final String subtitle;
  final List<String> needs;
}
