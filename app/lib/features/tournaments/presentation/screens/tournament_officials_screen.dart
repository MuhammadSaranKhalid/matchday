import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match_official.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/assign_official_sheet.dart';

/// Artboard 27j — assign umpires & scorers for one fixture.
///
/// The screen's real payload is the **handover code**: scoring rights transfer
/// to a phone that isn't the organiser's, so the code gets the largest type
/// here. Confirmed is a green tick, pending is a cream pill, and nothing on
/// this screen is red — appointing an official is not destructive.
class TournamentOfficialsScreen extends ConsumerWidget {
  const TournamentOfficialsScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(tournamentLiveBoardProvider(tournamentId));
    final officials = ref.watch(matchOfficialsProvider(matchId));
    final tournament = ref.watch(tournamentDetailProvider(tournamentId)).value;

    final match = board.value
        ?.where((m) => m.matchId == matchId)
        .cast<TournamentLiveMatch?>()
        .firstOrNull;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _OfficialsTopBar(subtitle: tournament?.name ?? ''),
            Expanded(
              child: switch ((board, officials)) {
                (AsyncLoading(), _) || (_, AsyncLoading()) => const Center(
                    child: CircularProgressIndicator(color: CkColors.ink),
                  ),
                (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
                  _OfficialsError(
                    message: '$error',
                    onRetry: () {
                      ref.invalidate(matchOfficialsProvider(matchId));
                      ref.invalidate(tournamentLiveBoardProvider(tournamentId));
                    },
                  ),
                _ when match == null => const _OfficialsError(
                    message: 'That fixture is no longer on this tournament.',
                  ),
                _ => _OfficialsBody(
                    tournamentId: tournamentId,
                    match: match,
                    officials: officials.value ?? const [],
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialsBody extends ConsumerWidget {
  const _OfficialsBody({
    required this.tournamentId,
    required this.match,
    required this.officials,
  });

  final String tournamentId;
  final TournamentLiveMatch match;
  final List<MatchOfficial> officials;

  /// The two on-field roles the design shows. Third umpire and referee exist
  /// in the schema but no club cup appoints them, so they stay off the screen
  /// until something asks for them.
  static const _umpireRoles = [OfficialRole.umpireMain, OfficialRole.umpireLeg];

  MatchOfficial? _holderOf(OfficialRole role) =>
      officials.where((o) => o.role == role).firstOrNull;

  String get _matchLine =>
      '${match.teamAName ?? 'Team A'} v ${match.teamBName ?? 'Team B'}';

  String get _matchLabel => match.round ?? 'This match';

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    OfficialRole role,
  ) async {
    final chosen = await showAssignOfficialSheet(
      context,
      tournamentId: tournamentId,
      matchId: match.matchId,
      role: role,
      matchLine: '$_matchLabel · $_matchLine',
      alreadyAppointed: officials
          .where((o) => o.role != role && o.role != OfficialRole.scorer)
          .map((o) => o.userId)
          .toSet(),
    );
    if (chosen == null || !context.mounted) return;

    final ok = await ref.read(tournamentsControllerProvider.notifier).assignOfficial(
          tournamentId: tournamentId,
          matchId: match.matchId,
          userId: chosen.userId,
          role: role,
        );
    if (!context.mounted) return;
    _report(context, ref, ok, '${chosen.displayName} is on ${role.label}.');
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    OfficialRole role,
  ) async {
    final ok = await ref.read(tournamentsControllerProvider.notifier).removeOfficial(
          tournamentId: tournamentId,
          matchId: match.matchId,
          role: role,
        );
    if (!context.mounted) return;
    _report(context, ref, ok, '${role.label} cleared.');
  }

  static void _report(
    BuildContext context,
    WidgetRef ref,
    bool ok,
    String success,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
      return;
    }
    final state = ref.read(tournamentsControllerProvider);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: CkColors.redInk,
        content:
            Text(state.hasError ? '${state.error}' : 'That did not go through.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorer = _holderOf(OfficialRole.scorer);
    final neutralCount =
        _umpireRoles.map(_holderOf).nonNulls.where((o) => o.isNeutral).length;
    final assignedCount = _umpireRoles.map(_holderOf).nonNulls.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              _FixtureHeader(match: match),

              // ── On-field umpires ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionRule(
                      title: 'On-field umpires',
                      trailing: assignedCount == 0
                          ? 'None assigned'
                          : 'Neutral · $neutralCount of $assignedCount',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(CkRadii.md),
                        border: Border.all(color: CkColors.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < _umpireRoles.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: CkColors.hairline,
                              ),
                            _UmpireRow(
                              role: _umpireRoles[i],
                              index: i + 1,
                              official: _holderOf(_umpireRoles[i]),
                              onAssign: () =>
                                  _assign(context, ref, _umpireRoles[i]),
                              onRemove: () =>
                                  _remove(context, ref, _umpireRoles[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Official digital scorer ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionRule(title: 'Official digital scorer'),
                    const SizedBox(height: 10),
                    _ScorerCard(
                      match: match,
                      scorer: scorer,
                      tournamentId: tournamentId,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You keep organiser rights — the code grants scoring '
                      'only, and you can revoke it mid-match from Live Ops.',
                      style: CkType.body(
                        fontSize: 11,
                        height: 1.45,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ConfirmBar(
          label: 'Confirm Officials for $_matchLabel',
          onConfirm: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  assignedCount == 0
                      ? 'Nobody is appointed yet — the match can still start.'
                      : 'Officials confirmed for $_matchLabel.',
                ),
              ),
            );
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }
}

// ─── Pieces ───────────────────────────────────────────────────────────────────

class _OfficialsTopBar extends StatelessWidget {
  const _OfficialsTopBar({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Material(
            color: CkColors.paper2,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, size: 17, color: CkColors.ink),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Officials',
                  style: CkType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
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
        ],
      ),
    );
  }
}

class _FixtureHeader extends StatelessWidget {
  const _FixtureHeader({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    final start = match.scheduledStartTime;
    final toss = start.subtract(const Duration(minutes: 15));
    final isToday = DateUtils.isSameDay(start, DateTime.now());
    final day = isToday ? 'Today' : DateFormat('EEE d MMM').format(start);
    final time = DateFormat('HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (match.round case final r?) r,
              match.venue,
            ].join(' · ').toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${match.teamAName ?? 'Team A'} v ${match.teamBName ?? 'Team B'}',
            style: CkType.display(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$day ${time.format(start)} · toss ${time.format(toss)}',
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRule extends StatelessWidget {
  const _SectionRule({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: CkColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: CkColors.hairline)),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(
            trailing!.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _UmpireRow extends StatelessWidget {
  const _UmpireRow({
    required this.role,
    required this.index,
    required this.official,
    required this.onAssign,
    required this.onRemove,
  });

  final OfficialRole role;
  final int index;
  final MatchOfficial? official;
  final VoidCallback onAssign;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final holder = official;

    if (holder == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CkColors.paper,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CkColors.soft,
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_add_alt,
                size: 16,
                color: CkColors.soft,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Umpire $index · unassigned',
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Both umpires must be from neutral clubs',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _OutlineButton(label: '+ Assign', onTap: onAssign),
          ],
        ),
      );
    }

    final club = holder.clubName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: holder.avatarUrl == null || holder.avatarUrl!.isEmpty
                ? Text(
                    holder.monogram,
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Image.network(
                    holder.avatarUrl!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => Text(
                      holder.monogram,
                      style: CkType.display(
                        fontSize: 13,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        holder.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (holder.isNeutral) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_outlined,
                        size: 13,
                        color: CkColors.greenInk,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  holder.isNeutral
                      ? [
                          if (club != null && club.isNotEmpty) club,
                          'Neutral club',
                        ].join(' · ')
                      // Stated, not blocked: the organiser may have no other
                      // option, and the rule is theirs to apply.
                      : '${club ?? 'Their club'} is playing this match',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 11,
                    color:
                        holder.isNeutral ? CkColors.muted : CkColors.amberInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONFIRMED',
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.greenInk,
                ),
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: onAssign,
                onLongPress: onRemove,
                child: Text(
                  'Change',
                  style: CkType.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scorer card, and beneath it the handover code — the largest type on
/// the artboard, because scoring rights are moving to a phone that is not the
/// organiser's.
class _ScorerCard extends ConsumerWidget {
  const _ScorerCard({
    required this.match,
    required this.scorer,
    required this.tournamentId,
  });

  final TournamentLiveMatch match;
  final MatchOfficial? scorer;
  final String tournamentId;

  /// Derived from the match id so the same fixture always shows the same code
  /// on every organiser's phone. It unlocks scoring for a match the holder is
  /// already appointed to, so it is a handover convenience, not a secret.
  String get _code {
    final hash = match.matchId.hashCode.abs();
    return (hash % 9000 + 1000).toString();
  }

  Future<void> _assignScorer(BuildContext context, WidgetRef ref) async {
    final candidates =
        await ref.read(tournamentScorerCandidatesProvider(tournamentId).future);
    if (!context.mounted) return;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x5229251E),
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Who is scoring?',
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (_, i) {
                    final c = candidates[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: CkColors.paper2,
                        child: Text(
                          c.displayName.isEmpty
                              ? '?'
                              : c.displayName[0].toUpperCase(),
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        c.displayName,
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        c.roleLabel,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                        ),
                      ),
                      onTap: () => Navigator.of(ctx).pop(c.userId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !context.mounted) return;
    final ok = await ref.read(tournamentsControllerProvider.notifier).assignScorer(
          tournamentId: tournamentId,
          matchId: match.matchId,
          userId: chosen,
        );
    if (!context.mounted) return;
    ref.invalidate(matchOfficialsProvider(match.matchId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? null : CkColors.redInk,
        content: Text(ok ? 'Scorer assigned.' : 'That did not go through.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holder = scorer;

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.line),
                  ),
                  alignment: Alignment.center,
                  child: holder == null
                      ? const Icon(
                          Icons.edit_note,
                          size: 18,
                          color: CkColors.soft,
                        )
                      : Text(
                          holder.monogram,
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                        holder?.displayName ?? 'No scorer assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color:
                              holder == null ? CkColors.muted : CkColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        holder == null
                            ? 'Nobody can record a ball until this is set'
                            : [
                                if (holder.username case final u?) '@$u',
                                if (holder.clubName case final c?) c,
                              ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.02,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (holder == null)
                  _OutlineButton(
                    label: '+ Assign',
                    onTap: () => _assignScorer(context, ref),
                  )
                else
                  // Cream, not green: they hold the appointment but have not
                  // taken the code yet, which is urgent rather than settled.
                  GestureDetector(
                    onTap: () => _assignScorer(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CkColors.cream,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CkColors.creamBorder),
                      ),
                      child: Text(
                        'AWAITING CODE',
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.10,
                          color: CkColors.amberInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (holder != null) ...[
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            _HandoverCode(code: _code, match: match),
          ],
        ],
      ),
    );
  }
}

class _HandoverCode extends StatelessWidget {
  const _HandoverCode({required this.code, required this.match});

  final String code;
  final TournamentLiveMatch match;

  String get _shareText =>
      'Your matchday scoring code for '
      '${match.teamAName ?? 'Team A'} v ${match.teamBName ?? 'Team B'} '
      'is $code. Enter it in the app to start scoring. It expires at the toss.';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CkColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HANDOVER CODE',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: CkColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CkColors.creamBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      i < code.length ? code[i] : '•',
                      style: CkType.mono(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Scorer enters this 4-digit code on their Matchday app to unlock '
            'live ball-by-ball scoring for this match. Expires at the toss.',
            style: CkType.body(
              fontSize: 11.5,
              height: 1.5,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _CodeAction(
                  icon: Icons.copy_all_outlined,
                  label: 'Copy code',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Handover code copied.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CodeAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(text: _shareText),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: CkColors.ink),
              const SizedBox(width: 7),
              Text(
                label,
                style: CkType.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CkColors.ink),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.label, required this.onConfirm});

  final String label;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            foregroundColor: CkColors.paper,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialsError extends StatelessWidget {
  const _OfficialsError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 30,
              color: CkColors.soft,
            ),
            const SizedBox(height: 12),
            Text(
              message,
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
