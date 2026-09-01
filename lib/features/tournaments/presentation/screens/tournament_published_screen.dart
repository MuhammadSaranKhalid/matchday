import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 22 — the moment after publishing.
///
/// Celebration without confetti: a seam-motif crest, one green tick, a cream
/// link row. WhatsApp is the first action because that is where Pakistani club
/// cricket actually lives.
class TournamentPublishedScreen extends ConsumerWidget {
  const TournamentPublishedScreen({super.key, required this.tournamentId});

  final String tournamentId;

  static const _linkBase = 'https://joinmatchday.com/t';

  String get _inviteLink => '$_linkBase/$tournamentId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '$e',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
            ),
          ),
          data: (t) => _Body(
            tournament: t,
            inviteLink: _inviteLink,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.tournament, required this.inviteLink});

  final Tournament tournament;
  final String inviteLink;

  String get _initials {
    final parts = tournament.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  String get _deadlineText {
    final d = tournament.registrationDeadline;
    if (d == null) return 'Managers can apply now.';
    return 'Managers can apply until ${DateFormat('d MMM').format(d)}.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
            child: TextButton(
              onPressed: () =>
                  context.pushReplacement('/tournaments/${tournament.id}'),
              style: TextButton.styleFrom(foregroundColor: CkColors.ink2),
              child: Text(
                'Done',
                style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: CkType.display(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: CkColors.greenInk),
                  const SizedBox(width: 6),
                  Text(
                    'REGISTRATIONS OPEN',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.12,
                      color: CkColors.greenInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${tournament.name} is live',
                textAlign: TextAlign.center,
                style: CkType.display(fontSize: 24, height: 1.22),
              ),
              const SizedBox(height: 8),
              Text(
                '$_deadlineText Share the link in your club groups to fill '
                'the draw faster.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 13,
                  height: 1.55,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 22),
              _InviteLinkRow(link: inviteLink),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: 'Share to WhatsApp',
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: '${tournament.name} is open for registration on '
                        'matchday.\n$inviteLink',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: 'Invite specific teams',
                onTap: () => context.push(
                  '/tournaments/${tournament.id}/console',
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'NEXT',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
              const SizedBox(height: 10),
              const _NextStep(n: 1, text: 'Approve teams as they apply'),
              const _NextStep(n: 2, text: 'Seed the draw and generate fixtures'),
              const _NextStep(n: 3, text: 'Assign scorers on matchday'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _PrimaryButton(
            label: 'Open Manage Console',
            onTap: () =>
                context.pushReplacement('/tournaments/${tournament.id}/console'),
          ),
        ),
      ],
    );
  }
}

class _InviteLinkRow extends StatelessWidget {
  const _InviteLinkRow({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INVITE LINK',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.amberDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  link.replaceFirst('https://', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: CkColors.ink,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: CkColors.amberDark),
            child: Text(
              'Copy',
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CkColors.amberDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.md),
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
      );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: CkColors.ink,
            side: const BorderSide(color: CkColors.line),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.md),
            ),
          ),
          child: Text(
            label,
            style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: CkType.body(fontSize: 13, color: CkColors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
