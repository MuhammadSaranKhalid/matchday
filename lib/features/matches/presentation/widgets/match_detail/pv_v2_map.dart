import '../../../../sports/cricket/domain/entities/cricket_player_profile.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/domain/entities/team_membership.dart';
import '../../../../teams/domain/entities/team_relationship.dart';
import '../../../../teams/presentation/utils/team_display.dart';
import '../../../domain/entities/match_role.dart';
import '../../state/my_matches_view.dart';
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

/// Flatten the composed [MyMatchesView] into the match cards.
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

/// Map the user's current memberships into the compact team cards.
/// Authority comes from [TeamMembership.relationship], never from fields on
/// the team profile itself.
List<PvTeam> pvTeamsFromMemberships(List<TeamMembership> memberships) {
  return [
    for (final membership in memberships)
      PvTeam(
        id: membership.team.id.value,
        crest: crestFromTeam(membership.team),
        role: switch (membership.relationship) {
          TeamRelationship.owner => 'owner',
          TeamRelationship.manager => 'manager',
          TeamRelationship.captain => 'captain',
          TeamRelationship.player => 'player',
          TeamRelationship.none => 'player',
        },
        subtitle: [
          _teamTypeLabel(membership.team.type),
          if (membership.team.homeGround != null &&
              membership.team.homeGround!.isNotEmpty)
            membership.team.homeGround!,
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
