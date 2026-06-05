// Pavilion v2 — mappers: real feature view-models → Pv* widget models.
//
// This is the ONE place the Pavilion (a presentation-only aggregation view,
// CLAUDE.md §6.6) adapts other features' shapes into the widget models. It
// reads cross-feature *presentation* types only (the matches `MyMatchesView`
// and the teams `Team` + its relationship extension), never their data layers.
//
// Honesty notes (per the agreed wiring plan):
//   • lineupSet / live score / format spec / RSVP / head-to-head have no
//     surfaced source — left null / placeholder.
//   • Teams: record / next-fixture / invites / "needs" have no backend — the
//     subtitle carries the real type + city instead, needs is empty.
import '../../../../matches/domain/entities/match_role.dart';
import '../../../../matches/presentation/state/my_matches_view.dart';
import '../../../../onboarding/domain/entities/player_profile.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/domain/entities/team_relationship.dart';
import '../../../../teams/presentation/utils/team_display.dart';
import 'pv_v2_data.dart';

// ── Crests ──────────────────────────────────────────────────────────────────

PvCrest crestFromTeam(Team t) => PvCrest(
      short: (t.logoMonogram != null && t.logoMonogram!.isNotEmpty)
          ? t.logoMonogram!
          : teamMonogram(t.name),
      name: t.name,
      color: parseHexColor(t.primaryColor),
      logoUrl: t.logoUrl,
    );

// ── Matches ─────────────────────────────────────────────────────────────────

/// Flatten the composed [MyMatchesView] into the Pavilion's match cards.
/// [meFallback] stands in for the user's own crest on outbound challenges
/// (the request view carries only the opponent).
List<PvMatch> pvMatchesFromView(MyMatchesView v, {required PvCrest meFallback}) {
  final out = <PvMatch>[];

  for (final c in v.confirmed) {
    out.add(PvMatch(
      id: c.id,
      phase: c.live
          ? PvPhase.live
          : c.tossReady
              ? PvPhase.startsSoon
              : PvPhase.scheduled,
      me: PvCrest(short: c.homeShort, name: c.homeName, color: c.homeColor),
      them: PvCrest(short: c.awayShort, name: c.awayName, color: c.awayColor),
      role: c.roleKind == MatchRoleKind.captain ? 'captain' : 'player',
      when: c.when,
      venue: c.venue,
      sub: c.tag,
      // lineupSet / live score are not surfaced by the view → left null.
    ));
  }

  for (final r in v.sent) {
    out.add(PvMatch(
      id: r.requestId,
      phase: PvPhase.awaitingReply,
      me: meFallback,
      them: PvCrest(
        short: r.opponentShort,
        name: r.isOpen ? 'Open · ${r.shareCode ?? '——'}' : r.opponentName,
        color: r.opponentColor,
      ),
      role: 'captain',
      when: r.expiresLabel,
      venue: 'TBD',
      sub: r.statusLabel,
    ));
  }

  for (final p in v.past) {
    out.add(PvMatch(
      id: p.id,
      phase: PvPhase.completed,
      me: PvCrest(short: p.homeShort, name: p.homeName, color: p.homeColor),
      them: PvCrest(short: p.awayShort, name: p.awayName, color: p.awayColor),
      role: 'player',
      when: p.when,
      venue: '',
      sub: p.tag,
      scoreA: '${p.homeRuns}/${p.homeWkts}',
      scoreB: '${p.awayRuns}/${p.awayWkts}',
      result: p.homeWon ? 'W' : 'L',
    ));
  }

  return out;
}

// ── Teams ───────────────────────────────────────────────────────────────────

/// Map the user's teams (owner/manager teams — the only ones `watchMyTeams`
/// returns) into Pavilion team cards. Role comes from the canonical
/// [TeamRelationship]; subtitle is the real type + city. Record / next-fixture
/// / invites / needs have no backend and are intentionally omitted.
List<PvTeam> pvTeamsFromTeams(List<Team> teams, {required String? userId}) {
  return [
    for (final t in teams)
      PvTeam(
        id: t.id.value,
        crest: crestFromTeam(t),
        role: switch (t.relationshipFor(userId: userId)) {
          TeamRelationship.owner => 'owner',
          TeamRelationship.manager => 'captain', // closest leadership pill
          TeamRelationship.captain => 'captain',
          _ => 'player',
        },
        subtitle: [
          _teamTypeLabel(t.type),
          if (t.city != null && t.city!.isNotEmpty) t.city!,
        ].join(' · '),
      ),
  ];
}

String _teamTypeLabel(TeamType type) =>
    type.wire.isEmpty ? '' : '${type.wire[0].toUpperCase()}${type.wire.substring(1)}';

// ── Profile ─────────────────────────────────────────────────────────────────

String playerRoleLabel(PlayerRole? r) => switch (r) {
      PlayerRole.batter => 'Batter',
      PlayerRole.bowler => 'Bowler',
      PlayerRole.allRounder => 'All-rounder',
      PlayerRole.wicketKeeper => 'Wicket-keeper',
      null => '',
    };

/// Two-letter initials from a display name (for the header avatar).
String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '·';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
