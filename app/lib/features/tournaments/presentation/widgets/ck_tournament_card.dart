import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';

enum TournamentCardVariant {
  standard,
  compact,
  hero,
}

/// The fundamental tournament card component across discovery, hub, and lists.
class CkTournamentCard extends StatelessWidget {
  const CkTournamentCard({
    super.key,
    required this.tournament,
    this.variant = TournamentCardVariant.standard,
    this.onTap,
    this.liveScoreText,
  });

  final Tournament tournament;
  final TournamentCardVariant variant;
  final VoidCallback? onTap;
  final String? liveScoreText;

  @override
  Widget build(BuildContext context) {
    if (variant == TournamentCardVariant.compact) {
      return _buildCompact(context);
    }
    if (variant == TournamentCardVariant.hero) {
      return _buildHero(context);
    }
    return _buildStandard(context);
  }

  Widget _buildStandard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: CkType.display(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildSubtitle(),
                            style: CkType.body(
                              fontSize: 12,
                              color: CkColors.ink2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(tournament.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: CkColors.hairline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: CkColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _buildDateString(),
                      style: CkType.mono(fontSize: 10.5, color: CkColors.muted),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: CkColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.approvedTeamsCount > 0 ? tournament.approvedTeamsCount : (tournament.maxTeams ?? 8)} Teams',
                      style: CkType.mono(fontSize: 10.5, color: CkColors.muted),
                    ),
                    if (tournament.city != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: CkColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tournament.city!,
                          style: CkType.body(
                            fontSize: 11.5,
                            color: CkColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (tournament.status == TournamentStatus.live &&
                    liveScoreText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CkColors.redSoft,
                      borderRadius: BorderRadius.circular(CkRadii.sm),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: CkColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            liveScoreText!,
                            style: CkType.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8C2218),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildLogo(28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${tournament.type.label} · ${tournament.city ?? "Cricket"}',
                        style: CkType.body(
                          fontSize: 11,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(tournament.status, compact: true),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: CkColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.lg),
        border: Border.all(color: CkColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(40, 30, 15, 0.07),
            offset: Offset(0, 8),
            blurRadius: 28,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CkRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tournament.bannerImageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(CkRadii.lg),
                  ),
                  child: Image.network(
                    tournament.bannerImageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(CkRadii.lg),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 36,
                      color: CkColors.soft,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildLogo(32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tournament.name,
                            style: CkType.display(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusPill(tournament.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _buildSubtitle(),
                      style: CkType.body(fontSize: 13, color: CkColors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double size) {
    final monogram = tournament.name.length >= 2
        ? tournament.name.substring(0, 2).toUpperCase()
        : 'TD';

    if (tournament.logoUrl != null && tournament.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.network(
          tournament.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Center(
        child: Text(
          monogram,
          style: CkType.display(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B5414),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(TournamentStatus status, {bool compact = false}) {
    Color bg;
    Color fg;
    Border? border;

    switch (status) {
      case TournamentStatus.live:
        bg = CkColors.red;
        fg = Colors.white;
        break;
      case TournamentStatus.registration:
        bg = CkColors.cream;
        fg = const Color(0xFF6B5414);
        border = Border.all(color: CkColors.creamBorder);
        break;
      case TournamentStatus.upcoming:
        bg = CkColors.paper2;
        fg = CkColors.ink2;
        border = Border.all(color: CkColors.line);
        break;
      case TournamentStatus.completed:
        bg = CkColors.greenSurface;
        fg = CkColors.greenInk;
        border = Border.all(color: CkColors.greenBorder);
        break;
      case TournamentStatus.draft:
        bg = CkColors.paper2;
        fg = CkColors.muted;
        border = Border.all(color: CkColors.soft);
        break;
      case TournamentStatus.cancelled:
      case TournamentStatus.abandoned:
        bg = CkColors.redSurface;
        fg = CkColors.redInk;
        border = Border.all(color: CkColors.redBorder);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: Text(
        status.label.toUpperCase(),
        style: CkType.mono(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    parts.add(tournament.type.label);
    if (tournament.format['max_overs'] != null) {
      parts.add('${tournament.format['max_overs']} Overs');
    }
    if (tournament.city != null) {
      parts.add(tournament.city!);
    }
    return parts.join(' · ');
  }

  String _buildDateString() {
    if (tournament.startDate == null) return 'Dates TBA';
    final start =
        '${tournament.startDate!.day}/${tournament.startDate!.month}';
    if (tournament.endDate == null) return start;
    final end = '${tournament.endDate!.day}/${tournament.endDate!.month}';
    return '$start – $end';
  }
}
