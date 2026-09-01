import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 27f — co-organisers exist because the organiser is usually
/// scoring, not holding a phone.
class TournamentPeopleScreen extends ConsumerStatefulWidget {
  const TournamentPeopleScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentPeopleScreen> createState() =>
      _TournamentPeopleScreenState();
}

class _TournamentPeopleScreenState
    extends ConsumerState<TournamentPeopleScreen> {
  final _handle = TextEditingController();
  bool _looking = false;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  void _report(bool ok, String success) {
    if (!mounted) return;
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

  Future<void> _invite() async {
    final username = _handle.text.trim().replaceAll('@', '').toLowerCase();
    if (username.isEmpty) return;

    setState(() => _looking = true);
    final profile =
        await ref.read(profileByUsernameProvider(username).future).catchError(
              (_) => null,
            );
    if (!mounted) return;
    setState(() => _looking = false);

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text('No matchday account found for @$username.'),
        ),
      );
      return;
    }

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .setCoOrganizer(
          tournamentId: widget.tournamentId,
          userId: profile.userId.value,
          add: true,
        );
    if (ok) {
      _handle.clear();
      ref.invalidate(tournamentScorerCandidatesProvider(widget.tournamentId));
    }
    _report(ok, '${profile.displayName ?? username} can now help run the cup.');
  }

  Future<void> _remove(ScorerCandidate person) async {
    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .setCoOrganizer(
          tournamentId: widget.tournamentId,
          userId: person.userId,
          add: false,
        );
    if (ok) {
      ref.invalidate(tournamentScorerCandidatesProvider(widget.tournamentId));
    }
    _report(ok, '${person.displayName} removed.');
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final peopleAsync =
        ref.watch(tournamentScorerCandidatesProvider(widget.tournamentId));
    final me = ref.watch(currentUserStreamProvider).value;
    final tournament = tournamentAsync.value;
    final isOwner = tournament != null &&
        me != null &&
        tournament.createdBy == me.id.value;

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text('Co-organisers', style: CkType.display(fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.line),
            ),
            child: Text.rich(
              TextSpan(
                style: CkType.body(
                  fontSize: 12.5,
                  height: 1.55,
                  color: CkColors.ink2,
                ),
                children: [
                  const TextSpan(
                    text: 'Co-organisers can approve teams, assign scorers and '
                        'run live ops. They ',
                  ),
                  TextSpan(
                    text: 'cannot',
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                  const TextSpan(
                    text: ' cancel the tournament, edit the format, or add '
                        'other co-organisers.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          peopleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '$e',
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
            data: (people) {
              final organisers = people
                  .where((p) => p.roleLabel != 'Team manager')
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PEOPLE · ${organisers.length}',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final person in organisers)
                    _PersonRow(
                      person: person,
                      isOwner: person.roleLabel == 'Organiser',
                      canRemove:
                          isOwner && person.roleLabel == 'Co-organiser',
                      onRemove: () => _remove(person),
                    ),
                ],
              );
            },
          ),
          if (isOwner) ...[
            const SizedBox(height: 22),
            Text(
              'INVITE BY USERNAME',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _handle,
                    style: CkType.body(fontSize: 14),
                    onSubmitted: (_) => _invite(),
                    decoration: InputDecoration(
                      hintText: '@username',
                      hintStyle:
                          CkType.body(fontSize: 13.5, color: CkColors.soft),
                      filled: true,
                      fillColor: CkColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CkRadii.sm),
                        borderSide: const BorderSide(color: CkColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CkRadii.sm),
                        borderSide: const BorderSide(color: CkColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CkRadii.sm),
                        borderSide:
                            const BorderSide(color: CkColors.ink, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _looking ? null : _invite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    disabledBackgroundColor: CkColors.soft,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CkRadii.sm),
                    ),
                  ),
                  child: _looking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Add',
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'They need a matchday account. Ask them for their username if '
              'you are not sure.',
              style: CkType.body(
                fontSize: 11.5,
                height: 1.45,
                color: CkColors.muted,
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            Text(
              'Only the organiser who created this cup can add or remove '
              'co-organisers.',
              style: CkType.body(
                fontSize: 12,
                height: 1.5,
                color: CkColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.isOwner,
    required this.canRemove,
    required this.onRemove,
  });

  final ScorerCandidate person;
  final bool isOwner;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final parts = person.displayName.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts.first.characters.take(2).toString().toUpperCase()
        : (parts.first.characters.first + parts[1].characters.first)
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: CkType.display(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.username == null
                      ? person.roleLabel
                      : '@${person.username} · ${person.roleLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CkColors.line),
              ),
              child: Text(
                'OWNER',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.ink2,
                ),
              ),
            )
          else if (canRemove)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: CkColors.redInk),
              child: Text(
                'Remove',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.redInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
