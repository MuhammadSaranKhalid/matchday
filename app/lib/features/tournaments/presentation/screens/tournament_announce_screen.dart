import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 27e — the rain-delay screen: the message a WhatsApp-fluent
/// organiser sends most.
class TournamentAnnounceScreen extends ConsumerStatefulWidget {
  const TournamentAnnounceScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentAnnounceScreen> createState() =>
      _TournamentAnnounceScreenState();
}

class _TournamentAnnounceScreenState
    extends ConsumerState<TournamentAnnounceScreen> {
  static const _maxLength = 300;

  final _message = TextEditingController();

  static const _presets = <String, String>{
    'Rain delay':
        'Rain at the ground. Today’s matches are pushed back 2 hours. '
            'Toss 15 minutes before the new start.',
    'Venue change':
        'Venue change for today’s fixtures. Please check the updated ground '
            'on the tournament page before you travel.',
    'Fee reminder':
        'A reminder to settle your team’s entry fee before the next round. '
            'Payment details are on the tournament page.',
    'Blank': '',
  };

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final count = await ref
        .read(tournamentsControllerProvider.notifier)
        .sendAnnouncement(
          tournamentId: widget.tournamentId,
          message: _message.text.trim(),
        );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (count == null) {
      final state = ref.read(tournamentsControllerProvider);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text(
            state.hasError ? '${state.error}' : 'The announcement failed.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == 1 ? 'Sent to 1 person.' : 'Sent to $count people.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final regsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));
    final busy = ref.watch(tournamentsControllerProvider).isLoading;

    final regs = regsAsync.value ?? const <TournamentRegistration>[];
    final approved = regs.where((r) => r.isApproved).toList();
    final managers = approved.length;
    final players = approved.fold<int>(0, (s, r) => s + r.squad.length);
    // Followers are not counted client-side — the RPC is the authority on who
    // actually receives it, and it returns the real number on send.
    final reachable = managers + players;

    final text = _message.text.trim();
    final canSend = text.isNotEmpty && text.length <= _maxLength && !busy;

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
        title: Text('Send an announcement', style: CkType.display(fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Eyebrow('Common messages'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _presets.entries)
                _PresetChip(
                  label: entry.key,
                  selected: _message.text == entry.value &&
                      (entry.value.isNotEmpty || _message.text.isEmpty),
                  onTap: () {
                    _message.text = entry.value;
                    _message.selection = TextSelection.fromPosition(
                      TextPosition(offset: _message.text.length),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _Eyebrow('Message'),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLines: 5,
            maxLength: _maxLength,
            style: CkType.body(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Rain at the ground. Today’s matches are pushed back '
                  '2 hours — the quarter-final now starts at 20:00.',
              hintStyle: CkType.body(
                fontSize: 13.5,
                height: 1.5,
                color: CkColors.soft,
              ),
              filled: true,
              fillColor: CkColors.surface,
              counterText: '${text.length} / $_maxLength',
              counterStyle: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
              ),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CkRadii.md),
                borderSide: const BorderSide(color: CkColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CkRadii.md),
                borderSide: const BorderSide(color: CkColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CkRadii.md),
                borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
              ),
            ),
          ),
          Text(
            'Sent as a push notification, not SMS.',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
          const SizedBox(height: 20),
          const _Eyebrow('Who receives it'),
          const SizedBox(height: 8),
          _AudienceRow(
            label: 'Team managers',
            sublabel: 'Owners and managers of approved teams',
            count: managers,
          ),
          _AudienceRow(
            label: 'Squad players',
            sublabel: 'Everyone locked into an approved squad',
            count: players,
          ),
          const _AudienceRow(
            label: 'Followers',
            sublabel: 'Spectators watching the cup',
            count: null,
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _Eyebrow('They will see'),
            const SizedBox(height: 8),
            _PreviewCard(
              tournamentName: tournamentAsync.value?.name ?? 'Tournament',
              message: text,
            ),
          ],
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: canSend ? _send : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CkColors.ink,
              disabledBackgroundColor: CkColors.soft,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CkRadii.sm),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    reachable > 0
                        ? 'Send to $reachable people and followers'
                        : 'Send announcement',
                    style: CkType.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
        ),
      );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CkColors.ink : CkColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.line,
            ),
          ),
          child: Text(
            label,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.paper : CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceRow extends StatelessWidget {
  const _AudienceRow({
    required this.label,
    required this.sublabel,
    required this.count,
  });

  final String label;
  final String sublabel;
  final int? count;

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          Text(
            count?.toString() ?? '—',
            style: CkType.mono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: count == null ? CkColors.soft : CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.tournamentName, required this.message});

  final String tournamentName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final initials = tournamentName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(CkRadii.sm),
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: CkType.display(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tournamentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 12,
                    height: 1.45,
                    color: CkColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
