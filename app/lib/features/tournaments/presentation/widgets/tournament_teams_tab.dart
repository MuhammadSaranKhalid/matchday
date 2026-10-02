import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_participant.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 15, left — the Teams tab.
///
/// **A ruled list, not a grid.** Displays publicly confirmed tournament participants
/// derived strictly from canonical accepted entries without exposing private
/// registration proposals, personal identities, or financial records.
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
    final participantsAsync =
        ref.watch(tournamentParticipantsProvider(widget.tournament.id));
    final board = ref.watch(tournamentLiveBoardProvider(widget.tournament.id));

    return switch (participantsAsync) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => _TeamsMessage(
          title: 'Teams did not load',
          body: '$error',
          onRetry: () => ref
              .invalidate(tournamentParticipantsProvider(widget.tournament.id)),
        ),
      AsyncData(value: final all) => _body(all, board.value ?? const []),
    };
  }

  Widget _body(
    List<TournamentParticipant> all,
    List<TournamentLiveMatch> board,
  ) {
    if (all.isEmpty) {
      return const _TeamsMessage(
        title: 'No teams confirmed yet',
        body: 'Teams appear here as the organiser approves them.',
      );
    }

    final sorted = [...all]
      ..sort((a, b) => a.teamName.compareTo(b.teamName));

    final shown = _expanded
        ? sorted
        : sorted.take(_initiallyShown).toList(growable: false);
    final hidden = sorted.length - shown.length;

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async => ref
          .invalidate(tournamentParticipantsProvider(widget.tournament.id)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '${sorted.length} teams'.toUpperCase(),
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
              participant: shown[i],
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
                  'Show all ${sorted.length} teams',
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
    TournamentParticipant participant,
    List<TournamentLiveMatch> board,
  ) {
    final theirs = board.where((m) =>
        m.teamAId == participant.teamId || m.teamBId == participant.teamId);
    if (theirs.isEmpty) return null;

    if (theirs.any((m) => m.status == 'live' || m.status == 'super_over')) {
      return const _TeamStatus('Live', live: true);
    }

    // A knockout exit: they lost a decided fixture and have nothing upcoming.
    final upcoming = theirs.any((m) => !m.isFinished);
    if (!upcoming) {
      for (final m in theirs) {
        if (m.winnerId != null && m.winnerId != participant.teamId) {
          return _TeamStatus('Out${m.round == null ? '' : ' · ${m.round}'}');
        }
      }
    }

    // A bye: a fixture where they are the only named side.
    for (final m in theirs) {
      final opponent =
          m.teamAId == participant.teamId ? m.teamBId : m.teamAId;
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
    required this.participant,
    required this.status,
    required this.onTap,
  });

  final int index;
  final TournamentParticipant participant;
  final _TeamStatus? status;
  final VoidCallback onTap;

  String get _monogram {
    final explicit = participant.logoMonogram?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit.toUpperCase();
    final name = participant.teamName;
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
                index.toString().padLeft(2, '0'),
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
              child: participant.logoUrl == null ||
                      participant.logoUrl!.isEmpty
                  ? Text(
                      _monogram,
                      style: CkType.display(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Image.network(
                      participant.logoUrl!,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    participant.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Confirmed team',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                      fontSize: 11.5,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (status case final s?) ...[
              const SizedBox(width: 8),
              _Chip(status: s),
            ],
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: CkColors.line,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.status});

  final _TeamStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CkColors.cream,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          border: Border.all(color: CkColors.creamBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CkColors.amberDark,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'LIVE',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.amberDark,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(color: CkColors.line),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

class _TeamsMessage extends StatelessWidget {
  const _TeamsMessage({
    required this.title,
    required this.body,
    this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: CkType.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                color: CkColors.muted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
