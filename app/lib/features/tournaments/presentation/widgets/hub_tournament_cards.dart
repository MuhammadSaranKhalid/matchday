import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: layout.cardPadding,
        vertical: layout.cardPadding - 2,
      ),
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
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dashed ? scheme.outlineVariant : scheme.outline,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dashed ? scheme.onSurfaceVariant : scheme.onSurface,
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
                      style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: dashed ? scheme.onSurfaceVariant : scheme.onSurface,
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
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
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            const SizedBox(height: 11),
            section,
          ],
        ],
      ),
    );

    if (dashed) {
      return CkDashedBox(
        radius: layout.cardRadius,
        color: scheme.outline,
        fill: scheme.surface,
        onTap: onTap,
        child: body,
      );
    }

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(layout.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Status pill backed by [StatusBadge].
class HubStatusPill extends StatelessWidget {
  const HubStatusPill({super.key, required this.status, this.dashed = false});

  final TournamentStatus status;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      TournamentStatus.live => ('LIVE', StatusTone.live),
      TournamentStatus.registration => ('REG OPEN', StatusTone.warning),
      TournamentStatus.draft => ('DRAFT', StatusTone.neutral),
      TournamentStatus.completed => ('COMPLETED', StatusTone.neutral),
      TournamentStatus.cancelled || TournamentStatus.abandoned => (
          status.label.toUpperCase(),
          StatusTone.live,
        ),
      TournamentStatus.upcoming => ('UPCOMING', StatusTone.neutral),
    };

    return StatusBadge(
      label: label,
      tone: tone,
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
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

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
                style: textTokens.eyebrow.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$value / $total',
              style: textTokens.mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: scheme.onSurface,
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
            backgroundColor: scheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
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
    final status = context.statusColors;
    final textTokens = context.textTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.cream,
        borderRadius: BorderRadius.circular(Radii.card - 4),
        border: Border.all(color: status.creamBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: status.warning),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: textTokens.eyebrow.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: status.warning,
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
    final scheme = context.colorScheme;
    final status = context.statusColors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: good ? status.successSurface : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.card - 4),
        border: Border.all(
          color: good ? status.successBorder : scheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: good ? status.success : scheme.onSurfaceVariant,
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
    final scheme = context.colorScheme;
    final status = context.statusColors;
    final textTheme = context.textTheme;
    final textTokens = context.textTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.card - 4),
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
              style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                fontSize: 12,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: textTokens.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: status.live,
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
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            note,
            maxLines: 2,
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action!,
                style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              Icon(Icons.chevron_right, size: 15, color: scheme.onSurface),
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
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final textTokens = context.textTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YOUR NEXT MATCH',
          style: textTokens.eyebrow.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: scheme.onSurfaceVariant,
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
                    style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
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
    final scheme = context.colorScheme;
    final reg = entry.registration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Playing as ${reg.teamName ?? 'your team'}',
          style: (context.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
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
            if (reg.isApproved)
              const HubNeutralChip(label: 'Accepted', good: true)
            else
              const HubCreamChip(label: 'Pending decision'),
          ],
        ),
      ],
    );
  }
}
