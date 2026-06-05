// Pavilion v2 — view models.
//
// The widget-facing shapes the Pavilion v2 UI renders. Matches and Teams are
// now fed from REAL data (see pv_v2_map.dart, which maps the matches/teams
// feature view-models into these). Tournaments + the Account row list remain
// mock (no Flutter feature / no backend yet) — their seeds live here.
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
  final bool? lineupSet;
  final String? scoreA;
  final String? scoreB;
  final String? result;

  bool get isCaptain => role == 'captain' || role == 'owner';
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

// ── Tournaments (mock — no Flutter feature yet) ─────────────────────────────

enum PvTourKind { organizing, playing }

@immutable
class PvTournament {
  const PvTournament({
    required this.id,
    required this.name,
    required this.short,
    required this.color,
    required this.kind,
    required this.format,
    required this.stage,
    required this.sub,
    required this.needs,
    required this.progress,
  });

  final String id;
  final String name;
  final String short;
  final Color color;
  final PvTourKind kind;
  final String format;
  final String stage;
  final String sub;
  final int needs;
  final double progress;
}

/// Mock tournaments — the `tournaments` Supabase tables are deployed but there
/// is no Flutter feature yet, so this segment stays on seed data until one is
/// built.
List<PvTournament> seedTournaments() => const [
      PvTournament(
        id: 'tr_sc',
        name: "Spring Cup '26",
        short: 'SC',
        color: Color(0xFF6E2A22),
        kind: PvTourKind.organizing,
        format: 'Knockout · 8 teams',
        stage: 'Quarter-finals',
        sub: '3 fixtures to schedule',
        needs: 3,
        progress: 0.5,
      ),
      PvTournament(
        id: 'tr_rc',
        name: 'Ramadan Cup',
        short: 'RC',
        color: Color(0xFF2C7A50),
        kind: PvTourKind.organizing,
        format: 'Round-robin · 6 teams',
        stage: 'Group stage',
        sub: 'Round 2 of 5',
        needs: 0,
        progress: 0.4,
      ),
      PvTournament(
        id: 'tr_cl',
        name: 'City League',
        short: 'CL',
        color: Color(0xFF3E5C97),
        kind: PvTourKind.playing,
        format: 'League · 10 teams',
        stage: 'Matchday 4',
        sub: 'Lions 2nd · 9 pts',
        needs: 0,
        progress: 0.4,
      ),
    ];

// ── Account (mock row list — most items have no backend) ────────────────────

@immutable
class PvAccountItem {
  const PvAccountItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.sub,
  });
  final String id;
  final String icon; // PvIcons name
  final String title;
  final String sub;
}

@immutable
class PvAccountGroup {
  const PvAccountGroup({required this.group, required this.items});
  final String group;
  final List<PvAccountItem> items;
}

const List<PvAccountGroup> kPvAccount = [
  PvAccountGroup(group: 'YOU', items: [
    PvAccountItem(id: 'profile', icon: 'users', title: 'Profile', sub: 'View & edit your profile'),
    PvAccountItem(id: 'stats', icon: 'star', title: 'Stats', sub: 'Career · form · wagon wheel'),
    PvAccountItem(id: 'achievements', icon: 'trophy', title: 'Achievements', sub: 'Badges you’ve unlocked'),
  ]),
  PvAccountGroup(group: 'ACTIVITY', items: [
    PvAccountItem(id: 'wallet', icon: 'ticket', title: 'Wallet', sub: 'Entry fees · payouts'),
    PvAccountItem(id: 'saved', icon: 'flag', title: 'Saved', sub: 'Posts & matches you kept'),
    PvAccountItem(id: 'followed', icon: 'bell', title: 'Following', sub: 'Players · teams · tournaments'),
    PvAccountItem(id: 'scorer', icon: 'pencil', title: 'Scorer history', sub: 'Matches you’ve scored'),
  ]),
  PvAccountGroup(group: 'SETTINGS', items: [
    PvAccountItem(id: 'notif', icon: 'bell', title: 'Notifications', sub: 'Pushes & alerts'),
    PvAccountItem(id: 'disc', icon: 'search', title: 'Discoverability', sub: 'Who can find & challenge you'),
    PvAccountItem(id: 'privacy', icon: 'info', title: 'Privacy & blocking', sub: 'Visibility · blocked accounts'),
  ]),
];
