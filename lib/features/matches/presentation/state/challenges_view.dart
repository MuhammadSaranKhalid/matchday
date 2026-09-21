import 'package:flutter/material.dart';

import '../../domain/entities/match_request.dart';

/// View-model for the Challenges screen (`Challenges.dc.html`, artboards 01–12).
///
/// Split by OBLIGATION, not provenance. The design is explicit about why:
/// "Received/Sent" describes where a challenge came from, but a challenge you
/// sent that has been countered is now waiting on *you* again — under
/// Received/Sent it sorts into the wrong tab. `needsYou` / `waitingOnThem`
/// always answers the only question the manager is asking.
@immutable
class ChallengesView {
  const ChallengesView({required this.needsYou, required this.waitingOnThem});

  const ChallengesView.empty() : needsYou = const [], waitingOnThem = const [];

  /// Sorted nearest-to-expiry first. Position carries the urgency, which is
  /// what lets the screen stay calm when nothing is urgent (design rationale 1).
  final List<ChallengeRow> needsYou;
  final List<ChallengeRow> waitingOnThem;

  bool get isEmpty => needsYou.isEmpty && waitingOnThem.isEmpty;

  /// The red clause in the header line — "1 EXPIRES IN 2H". Null when nothing
  /// on this tab is inside the urgent tier, and then there is no red on screen.
  int get urgentCount =>
      needsYou.where((r) => r.tier == ExpiryTier.urgent).length;

  /// "OLDEST 46H AGO" — how long the most patient challenger has waited.
  Duration? get oldestWait {
    if (needsYou.isEmpty) return null;
    final now = DateTime.now();
    return needsYou
        .map((r) => now.difference(r.createdAt))
        .reduce((a, b) => a > b ? a : b);
  }
}

/// How close a row is to expiring. Drives colour, and colour ONLY arrives at
/// [urgent] — see the design's "expiry is a rank first and a colour last".
enum ExpiryTier {
  /// Over 24h left. Muted mono, no chip fill. "Expires 41h".
  calm,

  /// 6–24h. Steps up to ink-2 on a paper-2 chip. "9h".
  soon,

  /// Under 6h, and only under 6h. Red ink on red surface, pulsing dot, and the
  /// card grows a 2px red top rule. "2h 10m".
  urgent,
}

@immutable
class ChallengeRow {
  const ChallengeRow({
    required this.requestId,
    required this.isInbound,
    required this.opponentName,
    required this.opponentShort,
    required this.opponentColor,
    required this.status,
    required this.createdAt,
    required this.whenLabel,
    required this.metaLabel,
    required this.canWithdraw,
    this.expiresAt,
    this.message,
    this.supersededLabel,
    this.counterLabel,
  });

  final String requestId;

  /// True when the other team sent it. Governs the status label and, with
  /// [status], which tab the row lands in.
  final bool isInbound;

  final String opponentName;
  final String opponentShort;
  final Color opponentColor;

  final MatchRequestStatus status;
  final DateTime createdAt;

  /// True only when MY team sent this challenge. `cancel_match_request`
  /// enforces `is_team_manager(from_team_id)`, so a row I merely COUNTERED is
  /// not mine to withdraw — offering the button there would raise "Only
  /// managers of the requesting team can cancel". The design's
  /// "Countered by you" row shows Withdraw; this is where that diverges.
  final bool canWithdraw;

  /// The clock that actually governs this row: `counter_expires_at` once
  /// countered (24h), otherwise `proposal_expires_at` (48h).
  final DateTime? expiresAt;

  /// "Sat 12 Sep · 4:30 PM" — the live proposal.
  final String whenLabel;

  /// "Gaddafi Ground B · T20 · 11-a-side".
  final String metaLabel;

  /// Free-text note from the challenger. Rendered under a hairline rule.
  final String? message;

  /// Countered rows only: the terms that were superseded, struck through.
  final String? supersededLabel;

  /// Countered rows only: the terms now on the table.
  final String? counterLabel;

  bool get isCountered => status == MatchRequestStatus.countered;

  /// A countered row is on the tighter 24h clock, and the design prints that
  /// next to the timer so the shorter deadline is explained rather than felt.
  bool get onCounterClock => isCountered;

  Duration? get remaining {
    final e = expiresAt;
    if (e == null) return null;
    final d = e.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  ExpiryTier get tier {
    final r = remaining;
    if (r == null) return ExpiryTier.calm;
    if (r.inHours < 6) return ExpiryTier.urgent;
    if (r.inHours < 24) return ExpiryTier.soon;
    return ExpiryTier.calm;
  }

  /// Tier decides the shape of this string as well as its colour: a calm row
  /// says "Expires 41h", a soon row just "9h", an urgent one counts minutes.
  String get expiryLabel {
    final r = remaining;
    if (r == null) return '';
    switch (tier) {
      case ExpiryTier.calm:
        return r.inDays >= 2 ? 'Expires ${r.inDays}d' : 'Expires ${r.inHours}h';
      case ExpiryTier.soon:
        return '${r.inHours}h';
      case ExpiryTier.urgent:
        if (r.inHours >= 1) return '${r.inHours}h ${r.inMinutes % 60}m';
        return '${r.inMinutes}m';
    }
  }

  /// "Needs your reply" / "Countered" / "Awaiting reply" / "Countered by you".
  /// The label names the ACTOR, which is what lets one component sit in either
  /// tab without ambiguity.
  String get statusLabel {
    if (isCountered) return isInbound ? 'Countered' : 'Countered by you';
    return isInbound ? 'Needs your reply' : 'Awaiting reply';
  }
}
