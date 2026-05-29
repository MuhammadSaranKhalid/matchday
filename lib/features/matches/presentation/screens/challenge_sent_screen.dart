import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/match_request.dart';
import '../providers/matches_providers.dart';

/// Confirmation screen shown immediately after the sender taps "Send
/// challenge". Surfaces the 48h countdown, the 6-digit share code, and a
/// Cancel CTA. Auto-rebuilds the countdown every minute.
class ChallengeSentScreen extends ConsumerStatefulWidget {
  const ChallengeSentScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ChallengeSentScreen> createState() =>
      _ChallengeSentScreenState();
}

class _ChallengeSentScreenState extends ConsumerState<ChallengeSentScreen> {
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchChallengeProvider(widget.requestId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (req) => req == null
              ? const Center(child: Text('Challenge not found'))
              : _body(req),
        ),
      ),
    );
  }

  Widget _body(MatchRequest req) {
    final expiresAt = req.proposalExpiresAt ?? req.codeExpiresAt;
    final remaining = expiresAt?.difference(DateTime.now());
    final remainingLabel = remaining == null
        ? null
        : _formatRemaining(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => context.go('/pavilion'),
                icon: const Icon(Icons.close, color: CkColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 30,
              color: CkColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'CHALLENGE SENT',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            req.toTeamId == null
                ? 'Anyone nearby can claim with the code below.'
                : 'They have ${remainingLabel ?? "48h"} to reply.',
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (req.shareCode != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _ShareCodeCard(
              code: req.shareCode!,
              expiresLabel: req.codeExpiresAt == null
                  ? null
                  : _formatRemaining(
                      req.codeExpiresAt!.difference(DateTime.now()),
                    ),
            ),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: CkButton(
            label: 'Go to My matches',
            onPressed: () => context.go('/pavilion'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: CkButton.ghost(
            label: 'Cancel challenge',
            busy: _busy,
            onPressed: _busy ? null : () => _withdraw(req),
          ),
        ),
      ],
    );
  }

  Future<void> _withdraw(MatchRequest req) async {
    setState(() => _busy = true);
    final result = await ref
        .read(matchesRepositoryProvider)
        .withdrawMatchChallenge(requestId: req.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        context.go('/pavilion');
      },
    );
  }
}

class _ShareCodeCard extends StatelessWidget {
  const _ShareCodeCard({required this.code, this.expiresLabel});
  final String code;
  final String? expiresLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(
          'IN-PERSON SHARE CODE',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          code.split('').join(' '),
          style: CkType.display(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.04 * 36,
          ),
        ),
        const SizedBox(height: 6),
        if (expiresLabel != null)
          Text(
            'EXPIRES IN $expiresLabel',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.amber,
            ),
          ),
      ]),
    );
  }
}

String _formatRemaining(Duration d) {
  if (d.isNegative) return 'expired';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inHours < 24) {
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  return '${d.inDays}d';
}
