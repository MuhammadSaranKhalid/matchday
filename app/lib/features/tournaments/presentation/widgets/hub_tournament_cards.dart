import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/my_tournament_entry.dart';
import '../../domain/entities/tournament.dart';
import 'ck_pulse_dot.dart';
import 'tournament_wizard_kit.dart';

/// The hub's card family — artboards 02, 03, 04.
///
/// One shell, three payloads. The shell is identity: crest, name, one line of
/// meta, a status pill. What hangs below it depends on the relationship, and
/// the verbs do too: an organiser gets Manage Console, a manager gets their
/// own fixture and squad state, and a spectator gets **no verbs at all** —
/// hidden rather than disabled.

// ─── Shell ───────────────────────────────────────────────────────────────────

class HubCard extends StatelessWidget {
  const HubCard({
    super.key,
    required this.name,
    required this.meta,
    required this.pill,
    required this.sections,
    this.monogram,
    this.onTap,
    this.dashed = false,
  });

  final String name;
  final String? meta;
  final Widget pill;

  /// Rendered in order, separated by hairlines.
  final List<Widget> sections;
  final String? monogram;
  final VoidCallback? onTap;

  /// Drafts are dashed — they are not a cup yet.
  final bool dashed;

  String get _initials {
    if (monogram != null && monogram!.isNotEmpty) return monogram!;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dashed ? CkColors.soft : CkColors.line,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dashed ? CkColors.muted : CkColors.ink,
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
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(
                        fontSize: 17,
                        height: 1.2,
                        color: dashed ? CkColors.ink2 : CkColors.ink,
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(padding: const EdgeInsets.only(top: 2), child: pill),
            ],
          ),
          for (final section in sections) ...[
            const SizedBox(height: 11),
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            const SizedBox(height: 11),
            section,
          ],
        ],
      ),
    );

    if (dashed) {
      return CkDashedBox(
        radius: CkRadii.md,
        color: CkColors.line,
        fill: CkColors.paper,
        onTap: onTap,
        child: body,
      );
    }

    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(CkRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Status pill. Cream carries urgency, red carries live, and everything else
/// recedes to paper2.
class HubStatusPill extends StatelessWidget {
  const HubStatusPill({super.key, required this.status, this.dashed = false});

  final TournamentStatus status;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    Color? border;

    switch (status) {
      case TournamentStatus.live:
        label = 'Live';
        bg = CkColors.red;
        fg = Colors.white;
      case TournamentStatus.registration:
        label = 'Reg open';
        bg = CkColors.cream;
        fg = CkColors.amberDark;
        border = CkColors.creamBorder;
      case TournamentStatus.draft:
        label = 'Draft';
        bg = CkColors.paper2;
        fg = CkColors.muted;
        border = CkColors.soft;
      case TournamentStatus.completed:
        label = 'Completed';
        bg = CkColors.paper2;
        fg = CkColors.ink2;
        border = CkColors.line;
      case TournamentStatus.cancelled:
      case TournamentStatus.abandoned:
        label = status.label;
        bg = CkColors.redSurface;
        fg = CkColors.redInk;
        border = CkColors.redBorder;
      case TournamentStatus.upcoming:
        label = 'Upcoming';
        bg = CkColors.paper2;
        fg = CkColors.ink2;
        border = CkColors.line;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Sections ────────────────────────────────────────────────────────────────

/// "Teams approved · 6 / 8" over a 4pt rail.
class HubProgress extends StatelessWidget {
  const HubProgress({
    super.key,
    required this.label,
    required this.value,
    required this.total,
  });

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                ),
              ),
            ),
            Text(
              '$value / $total',
              style: CkType.mono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (value / total).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: CkColors.paper2,
            valueColor: const AlwaysStoppedAnimation<Color>(CkColors.ink),
          ),
        ),
      ],
    );
  }
}

/// Cream urgency chip — deadlines and things awaiting the organiser.
class HubCreamChip extends StatelessWidget {
  const HubCreamChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: CkColors.amber),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.amberDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral chip — squad and fee state on the Playing card.
class HubNeutralChip extends StatelessWidget {
  const HubNeutralChip({super.key, required this.label, this.good = false});

  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: good ? CkColors.greenSurface : CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(
          color: good ? CkColors.greenBorder : CkColors.line,
        ),
      ),
      child: Text(
        label,
        style: CkType.body(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: good ? CkColors.greenInk : CkColors.ink2,
        ),
      ),
    );
  }
}

/// The live strip: pulse, matchup, red score. One of the three places red is
/// allowed.
class HubLiveStrip extends StatelessWidget {
  const HubLiveStrip({super.key, required this.matchup, required this.score});

  final String matchup;
  final String score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.sm),
      ),
      child: Row(
        children: [
          const CkPulseDot(size: 7),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              matchup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 12, color: CkColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: CkType.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: CkColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

/// A footnote on the left and a chevroned verb on the right.
class HubFooter extends StatelessWidget {
  const HubFooter({super.key, required this.note, this.action});

  final String note;

  /// Omitted entirely for spectators — the verb is hidden, not disabled.
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            note,
            maxLines: 2,
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action!,
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.chevron_right, size: 15, color: CkColors.ink),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Your next match" — the Playing card's centrepiece.
class HubNextMatch extends StatelessWidget {
  const HubNextMatch({
    super.key,
    required this.matchup,
    required this.when,
    this.countdown,
  });

  final String matchup;
  final String when;
  final String? countdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YOUR NEXT MATCH',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    matchup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            if (countdown != null) ...[
              const SizedBox(width: 10),
              HubCreamChip(label: countdown!),
            ],
          ],
        ),
      ],
    );
  }
}

/// Formats a fee line: "Entry fee PKR 15,000 · 4 paid".
String hubFeeNote(Tournament t, {int? paidCount}) {
  if ((t.entryFee ?? 0) == 0) return 'Free entry';
  final money = NumberFormat.decimalPattern();
  final base = 'Entry fee PKR ${money.format(t.entryFee)}';
  return paidCount == null ? base : '$base · $paidCount paid';
}

/// "Playing as Lahore Lions" plus the squad/fee chips.
class HubPlayingBody extends StatelessWidget {
  const HubPlayingBody({super.key, required this.entry});

  final MyTournamentEntry entry;

  @override
  Widget build(BuildContext context) {
    final reg = entry.registration;
    final paid = (reg.paymentStatus ?? '').toLowerCase() == 'paid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Playing as ${reg.teamName ?? 'your team'}',
          style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            HubNeutralChip(
              label: reg.isApproved
                  ? 'Squad confirmed · ${reg.squad.length}'
                  : 'Squad of ${reg.squad.length} submitted',
              good: reg.isApproved,
            ),
            if (paid)
              const HubNeutralChip(label: 'Fee paid', good: true)
            else
              const HubCreamChip(label: 'Pending payment'),
          ],
        ),
      ],
    );
  }
}
