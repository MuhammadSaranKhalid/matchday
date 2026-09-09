import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/challenges_view.dart';

/// One challenge in the queue — `Challenges.dc.html` artboards 01–04.
///
/// Same component in both tabs. What changes is the action row: an inbound row
/// offers Decline / Counter / Accept, an outbound one offers Withdraw.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.row,
    required this.onOpen,
    this.onAccept,
    this.onCounter,
    this.onDecline,
    this.onWithdraw,
  });

  final ChallengeRow row;
  final VoidCallback onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onCounter;
  final VoidCallback? onDecline;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final urgent = row.tier == ExpiryTier.urgent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          // Uniform border only. Flutter asserts "a borderRadius can only be
          // given on borders with uniform colors", so the design's 2px red TOP
          // rule cannot be expressed as a Border side — it is drawn as the
          // first child inside the clipped column instead, which the corner
          // radius trims identically.
          border: Border.all(
            color: urgent ? CkColors.redBorder : CkColors.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The card's whole urgency tell. Present only under 6h; above that
            // the card is indistinguishable from a calm one.
            if (urgent) Container(height: 2, color: CkColors.red),
            _head(),
            if (row.isCountered) _ledger() else _terms(),
            _actions(),
          ],
        ),
      ),
    );
  }

  // ─── Head: crest · name · status · timer ──────────────────────────────────

  Widget _head() => Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Crest(short: row.opponentShort, color: row.opponentColor),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.opponentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _statusLine(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ExpiryChip(row: row),
          ],
        ),
      );

  Widget _statusLine() {
    final label = Text(
      row.statusLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CkType.mono(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.09,
        color: row.isCountered ? CkColors.amberInk : CkColors.muted,
      ),
    );
    if (!row.onCounterClock) return label;
    // The tighter clock is named, not merely felt. Both labels flex: a long
    // team name plus "COUNTERED BY YOU · 24H CLOCK" overruns the column at
    // 393px otherwise (caught by challenges_screen_test).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: label),
        const SizedBox(width: 6),
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: CkColors.soft,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '24H CLOCK',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.07,
              color: CkColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  /// A plain (uncountered) row states ONE proposal.
  Widget _terms() => Padding(
        padding: const EdgeInsets.fromLTRB(60, 10, 13, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.whenLabel,
              style: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              row.metaLabel.toUpperCase(),
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.07,
                color: CkColors.muted,
              ),
            ),
            if ((row.message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CkColors.hairline),
                  ),
                ),
                child: Text(
                  '“${row.message!.trim()}”',
                  style: CkType.body(
                    fontSize: 12.5,
                    height: 1.45,
                    color: CkColors.ink2,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  /// A countered row states TWO proposals, and the difference between them is
  /// the whole decision — so it reads as a ledger rather than a card. The
  /// superseded terms are struck through in muted; the live ones are ink.
  Widget _ledger() => Container(
        margin: const EdgeInsets.fromLTRB(60, 10, 13, 0),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CkColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.isInbound ? 'YOU PROPOSED' : 'THEY PROPOSED',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row.supersededLabel ?? '—',
                    // Struck through: these terms are superseded. CkType.body
                    // has no decoration slot, so it is applied on the result.
                    style: CkType.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: CkColors.muted,
                    ).copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: CkColors.soft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: CkColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.isInbound ? 'THEY PROPOSED' : 'YOU PROPOSED',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.amberInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row.counterLabel ?? row.whenLabel,
                    style: CkType.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _actions() {
    // Waiting-on-them: one action, and it is destructive-adjacent, so it is
    // outlined rather than filled.
    //
    // Withdraw is offered ONLY on a challenge my team actually sent.
    // cancel_match_request enforces is_team_manager(from_team_id), so on a row
    // I merely countered the button would raise "Only managers of the
    // requesting team can cancel". The design shows Withdraw on every
    // waiting row; this is the one place the build diverges from it, and it
    // diverges because the server would refuse.
    if (!row.isInbound) {
      if (!row.canWithdraw) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
          child: Text(
            'THEIR MOVE — YOUR COUNTER IS WITH THEM',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08,
              color: CkColors.soft,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Withdraw',
                kind: _ActionKind.outlined,
                onTap: onWithdraw,
              ),
            ),
          ],
        ),
      );
    }
    // Needs-you: decline is quiet text, counter is outlined, accept is the one
    // filled control on the card.
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      child: Row(
        children: [
          _ActionButton(
            label: 'Decline',
            kind: _ActionKind.quiet,
            onTap: onDecline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Counter',
              kind: _ActionKind.outlined,
              onTap: onCounter,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Accept',
              kind: _ActionKind.filled,
              onTap: onAccept,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pieces ─────────────────────────────────────────────────────────────────

/// The expiry timer, in the design's three tiers. Colour arrives ONLY at
/// [ExpiryTier.urgent] — on a screen with nothing urgent there is no red.
class ExpiryChip extends StatefulWidget {
  const ExpiryChip({super.key, required this.row});

  final ChallengeRow row;

  @override
  State<ExpiryChip> createState() => _ExpiryChipState();
}

class _ExpiryChipState extends State<ExpiryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Created here rather than in a field initializer: the ticker mixin looks
    // up TickerMode from context, and building it before mount leaves a
    // dangling ancestor lookup at dispose ("Looking up a deactivated widget's
    // ancestor is unsafe" in challenges_screen_test).
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.row.tier == ExpiryTier.urgent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ExpiryChip old) {
    super.didUpdateWidget(old);
    final urgent = widget.row.tier == ExpiryTier.urgent;
    if (urgent && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!urgent && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final label = row.expiryLabel;
    if (label.isEmpty) return const SizedBox.shrink();

    switch (row.tier) {
      case ExpiryTier.calm:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Text(
            label,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
        );

      case ExpiryTier.soon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
              color: CkColors.ink2,
            ),
          ),
        );

      case ExpiryTier.urgent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: CkColors.redSurface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: CkColors.redBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.25).animate(_pulse),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: CkColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                  color: CkColors.redInk,
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Teams have a colour and a short code, never a logo.
class _Crest extends StatelessWidget {
  const _Crest({required this.short, required this.color});

  final String short;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          short.toUpperCase(),
          style: CkType.display(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

enum _ActionKind { quiet, outlined, filled }

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.kind, this.onTap});

  final String label;
  final _ActionKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: CkType.mono(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: switch (kind) {
          _ActionKind.quiet => CkColors.muted,
          _ActionKind.outlined => CkColors.ink,
          _ActionKind.filled => CkColors.paper,
        },
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: kind == _ActionKind.quiet
            ? const EdgeInsets.symmetric(horizontal: 14)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: kind == _ActionKind.filled ? CkColors.ink : null,
          borderRadius: BorderRadius.circular(10),
          border: kind == _ActionKind.outlined
              ? Border.all(color: CkColors.ink)
              : null,
        ),
        child: text,
      ),
    );
  }
}
