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
const PvCrest kPvUnknownCrest =
    PvCrest(short: '··', name: 'Your team', color: CkColors.muted);

// ── Matches ─────────────────────────────────────────────────────────────────

enum PvPhase { live, startsSoon, scheduled, awaitingReply, completed }

@immutable
class PvMatch {
  const PvMatch({
    required this.id,
    required this.phase,
    required this.me,
    required this.them,
    required this.role,
    required this.when,
    required this.venue,
    required this.sub,
    this.oversPerInnings,
    this.ballsPerOver,
    this.playersPerTeam,
    this.ballType,
    this.formatCode,
    this.lineupSet,
    this.scoreA,
    this.scoreB,
    this.result, // 'W' | 'L'
  });

  final String id;
  final PvPhase phase;
  final PvCrest me;
  final PvCrest them;
  final String role; // captain | owner | player
  final String when;
  final String venue;
  final String sub;
  final int? oversPerInnings;
  final int? ballsPerOver;
  final int? playersPerTeam;
  final String? ballType;
  final String? formatCode;
  final bool? lineupSet;
  final String? scoreA;
  final String? scoreB;
  final String? result;

  bool get isCaptain => role == 'captain' || role == 'owner';

  String get formatDisplay {
    final players = playersPerTeam ?? 11;
    final code = formatCode ??
        (oversPerInnings == 20
            ? 'T20'
            : (oversPerInnings != null && oversPerInnings! > 0
                ? '${oversPerInnings}O'
                : 'Cricket'));
    return '$code · $players-a-side';
  }

  String get oversDisplay {
    final overs = (oversPerInnings == null || oversPerInnings == 0)
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
