import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team_search_result.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/player_result.dart';
import 'explore_atoms.dart';

/// A team result row: crest, name (+ verified tick), meta line, chevron.
class TeamRow extends StatelessWidget {
  const TeamRow({
    super.key,
    required this.team,
    this.query = '',
    this.onTap,
  });

  final TeamSearchResult team;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => RuledRow(
        onTap: onTap,
        child: Row(
          children: [
            Crest(
              short: team.logoMonogram?.isNotEmpty == true
                  ? team.logoMonogram!
                  : ckInitials(team.name),
              color: ckParseColor(team.primaryColor),
              logoUrl: team.logoUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: HighlightedName(
                          text: team.name,
                          query: query,
                          style: CkType.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      if (team.isVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedTick(),
                      ],
                    ],
                  ),
                  if (team.metaLine.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    ExploreMetaLine(team.metaLine),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // v1 has no coordinates, so distanceKm is always null and no
            // distance is rendered. The branch stays so the row lights up
            // unchanged when capture ships.
            if (team.distanceKm != null) ...[
              Text(
                '${team.distanceKm!.toStringAsFixed(1)} km',
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, size: 16, color: CkColors.soft),
          ],
        ),
      );
}

/// A player result row: avatar, name (+ verified / unclaimed badge), meta
/// line, follower count.
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    this.query = '',
    this.onTap,
  });

  final PlayerResult player;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => RuledRow(
        onTap: onTap,
        child: Row(
          children: [
            Avatar(
              mono: ckInitials(player.name),
              imageUrl: player.photoUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: HighlightedName(
                          text: player.name,
                          query: query,
                          style: CkType.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      if (player.isVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedTick(),
                      ],
                      if (player.isUnclaimed) ...[
                        const SizedBox(width: 6),
                        const _UnclaimedBadge(),
                      ],
                    ],
                  ),
                  if (player.metaLine.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    ExploreMetaLine(player.metaLine),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  // An unclaimed player has no followers by definition — an
                  // em dash reads more honestly than a zero.
                  player.isUnclaimed ? '—' : _compact(player.followerCount),
                  style: CkType.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink2,
                  ),
                ),
                Text(
                  'FOLLOWERS',
                  style: CkType.mono(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08,
                    color: CkColors.soft,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// 1240 → "1,240"; 12400 → "12.4k". Keeps the column narrow enough that a
  /// long name still gets its ellipsis rather than being squeezed out.
  static String _compact(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '${(n / 1000).toStringAsFixed(1)}k';
  }
}

class _UnclaimedBadge extends StatelessWidget {
  const _UnclaimedBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CkColors.line),
        ),
        child: Text(
          'UNCLAIMED',
          style: CkType.mono(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
            color: CkColors.muted,
          ),
        ),
      );
}

/// A match result row: stacked team crests, "A v B", venue · tournament, and
/// a live score pill (or a status pill for non-live matches).
class MatchRow extends StatelessWidget {
  const MatchRow({
    super.key,
    required this.match,
    this.query = '',
    this.onTap,
  });

  final MatchResult match;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (match.venue?.isNotEmpty == true) match.venue!,
      if (match.tournamentName?.isNotEmpty == true) match.tournamentName!,
    ].join(' · ');

    return RuledRow(
      onTap: onTap,
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Crest(
                short: ckInitials(match.teamAName ?? 'TBD'),
                color: ckParseColor(match.teamAColor),
                logoUrl: match.teamALogoUrl,
                size: 22,
                radius: 6,
              ),
              const SizedBox(height: 3),
              Crest(
                short: ckInitials(match.teamBName ?? 'TBD'),
                color: ckParseColor(match.teamBColor),
                logoUrl: match.teamBLogoUrl,
                size: 22,
                radius: 6,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HighlightedName(
                  text: match.title,
                  query: query,
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  ExploreMetaLine(meta),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MatchStatusPill(match: match),
        ],
      ),
    );
  }
}

/// Live matches get the red pulsing pill carrying the score — the one place
/// on this screen the accent is spent. Everything else gets a neutral status.
class _MatchStatusPill extends StatelessWidget {
  const _MatchStatusPill({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    if (match.isLive) {
      return _LivePill(label: match.scoreLine ?? 'LIVE');
    }
    final label = switch (match.status) {
      'completed' => 'RESULT',
      'scheduled' => 'UPCOMING',
      'toss' => 'TOSS',
      'rescheduled' => 'MOVED',
      _ => match.status.replaceAll('_', ' ').toUpperCase(),
    };
    return Pill(label: label);
  }
}

/// Red pill with a pulsing dot, matching the design's LIVE treatment.
class _LivePill extends StatefulWidget {
  const _LivePill({required this.label});

  final String label;

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}
