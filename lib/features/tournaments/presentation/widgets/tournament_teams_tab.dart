import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 15, left — the Teams tab.
///
/// **A ruled list, not a grid.** A grid of monogram circles reads as
/// decoration and hides the captain and the squad count, which are the two
/// things a manager actually scans for.
class TournamentTeamsTab extends ConsumerStatefulWidget {
  const TournamentTeamsTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentTeamsTab> createState() => _TournamentTeamsTabState();
}

class _TournamentTeamsTabState extends ConsumerState<TournamentTeamsTab> {
  /// The list opens at eight and offers the rest — a 16-team cup is a long
  /// scroll before you reach anything else on the tab.
  static const _initiallyShown = 8;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final regs =
        ref.watch(tournamentRegistrationsProvider(widget.tournament.id));
    final board = ref.watch(tournamentLiveBoardProvider(widget.tournament.id));

    return switch (regs) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => _TeamsMessage(
          title: 'Teams did not load',
          body: '$error',
          onRetry: () => ref
              .invalidate(tournamentRegistrationsProvider(widget.tournament.id)),
        ),
      AsyncData(value: final all) => _body(all, board.value ?? const []),
    };
  }

  Widget _body(
    List<TournamentRegistration> all,
    List<TournamentLiveMatch> board,
  ) {
    final approved = all.where((r) => r.isApproved).toList()
      // Seeded order when the draw is locked; alphabetical before that.
      ..sort((a, b) {
        final sa = a.seedNumber, sb = b.seedNumber;
        if (sa != null && sb != null) return sa.compareTo(sb);
        if (sa != null) return -1;
        if (sb != null) return 1;
        return (a.teamName ?? '').compareTo(b.teamName ?? '');
      });

    if (approved.isEmpty) {
      return const _TeamsMessage(
        title: 'No teams confirmed yet',
        body: 'Teams appear here as the organiser approves them.',
      );
    }

    final seeded = approved.any((r) => r.seedNumber != null);
    final shown = _expanded
        ? approved
        : approved.take(_initiallyShown).toList(growable: false);
    final hidden = approved.length - shown.length;

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async => ref
          .invalidate(tournamentRegistrationsProvider(widget.tournament.id)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '${approved.length} teams${seeded ? ' · seeded' : ''}'
                  .toUpperCase(),
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: CkColors.muted,
              ),
            ),
          ),
          for (var i = 0; i < shown.length; i++)
            _TeamRow(
              index: i + 1,
              registration: shown[i],
              status: _statusFor(shown[i], board),
              onTap: () => context.push('/teams/${shown[i].teamId}'),
            ),
          if (hidden > 0)
            InkWell(
              onTap: () => setState(() => _expanded = true),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CkColors.hairline)),
                ),
                child: Text(
                  'Show all ${approved.length} teams',
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The trailing chip: what this team is doing in the cup right now. Derived
  /// from the board rather than stored, so it can never disagree with it.
  _TeamStatus? _statusFor(
    TournamentRegistration reg,
    List<TournamentLiveMatch> board,
  ) {
    final theirs =
        board.where((m) => m.teamAId == reg.teamId || m.teamBId == reg.teamId);
    if (theirs.isEmpty) return null;

    if (theirs.any((m) => m.status == 'live' || m.status == 'super_over')) {
      return const _TeamStatus('Live', live: true);
    }

    // A knockout exit: they lost a decided fixture and have nothing upcoming.
    final upcoming = theirs.any((m) => !m.isFinished);
    if (!upcoming) {
      for (final m in theirs) {
        if (m.winnerId != null && m.winnerId != reg.teamId) {
          return _TeamStatus('Out${m.round == null ? '' : ' · ${m.round}'}');
        }
      }
    }

    // A bye: a fixture where they are the only named side.
    for (final m in theirs) {
      final opponent = m.teamAId == reg.teamId ? m.teamBId : m.teamAId;
      if (opponent == null && !m.isFinished) return const _TeamStatus('Bye');
    }
    return null;
  }
}

class _TeamStatus {
  const _TeamStatus(this.label, {this.live = false});

  final String label;
  final bool live;
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.index,
    required this.registration,
    required this.status,
    required this.onTap,
  });

  final int index;
  final TournamentRegistration registration;
  final _TeamStatus? status;
  final VoidCallback onTap;

  String get _monogram {
    final explicit = registration.teamMonogram?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit.toUpperCase();
    final name = registration.teamName ?? '';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  /// "Capt. Shadab Khan · 15 players" — the two facts a manager scans for.
  String get _subtitle {
    final parts = <String>[];
    if (registration.captainName case final c? when c.isNotEmpty) {
      parts.add('Capt. $c');
    }
    final squad = registration.squad.length;
    if (squad > 0) parts.add('$squad player${squad == 1 ? '' : 's'}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final seed = registration.seedNumber ?? index;
    final subtitle = _subtitle;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                seed.toString().padLeft(2, '0'),
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CkColors.muted,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.line),
              ),
              alignment: Alignment.center,
              child: registration.teamLogoUrl == null ||
                      registration.teamLogoUrl!.isEmpty
                  ? Text(
                      _monogram,
                      style: CkType.display(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Image.network(
                      registration.teamLogoUrl!,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        _monogram,
                        style: CkType.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    registration.teamName ?? 'Team',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (status != null)
              _StatusChip(status: status!)
            else
              const Icon(Icons.chevron_right, size: 18, color: CkColors.soft),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _TeamStatus status;

  @override
  Widget build(BuildContext context) {
    // "Live" is the one red on this tab, and only while a ball is being
    // bowled. An exit is plain mono — it is history, not an alarm.
    if (status.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'LIVE',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: Colors.white,
          ),
        ),
      );
    }

    if (status.label == 'Bye') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CkColors.line),
        ),
        child: Text(
          'BYE',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: CkColors.ink2,
          ),
        ),
      );
    }

    return Text(
      status.label.toUpperCase(),
      style: CkType.mono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: CkColors.muted,
      ),
    );
  }
}

class _TeamsMessage extends StatelessWidget {
  const _TeamsMessage({required this.title, required this.body, this.onRetry});

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 30, color: CkColors.soft),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.55,
                color: CkColors.muted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CkColors.line),
                  foregroundColor: CkColors.ink,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
