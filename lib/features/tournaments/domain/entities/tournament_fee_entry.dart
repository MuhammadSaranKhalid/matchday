import 'package:meta/meta.dart';

/// How a fee was handed over. Cash is the default because these cups are
/// settled at the ground — matchday never holds the money (artboard 24c).
enum PaymentChannel {
  cash('cash', 'Cash'),
  jazzCash('jazzcash', 'JazzCash'),
  easyPaisa('easypaisa', 'EasyPaisa'),
  bankTransfer('bank_transfer', 'Bank transfer'),
  other('other', 'Other');

  const PaymentChannel(this.wire, this.label);
  final String wire;
  final String label;

  static PaymentChannel? fromWire(String? wire) =>
      values.where((c) => c.wire == wire).firstOrNull;
}

/// Where a team stands on its entry fee. Deliberately three states and not a
/// boolean: "partial" is the common case at a weekend cup and the ledger is
/// useless without it.
enum FeeState {
  paid('Paid in full'),
  partial('Partial'),
  unpaid('Unpaid');

  const FeeState(this.label);
  final String label;
}

/// One approved team's line in the fee ledger (artboard 24c).
///
/// The ledger is a bookkeeping surface, not a dunning screen — nothing here
/// carries a "overdue" flag, because money never turns red on this screen.
@immutable
class TournamentFeeEntry {
  const TournamentFeeEntry({
    required this.registrationId,
    required this.teamId,
    required this.teamName,
    required this.entryFee,
    required this.amountPaid,
    this.teamMonogram,
    this.teamLogoUrl,
    this.channel,
    this.reference,
    this.recordedAt,
    this.recordedByName,
  });

  final String registrationId;
  final String teamId;
  final String teamName;
  final String? teamMonogram;
  final String? teamLogoUrl;

  /// The tournament's per-team fee. Zero for a free cup, in which case the
  /// ledger has nothing to reconcile and the screen says so.
  final double entryFee;
  final double amountPaid;

  final PaymentChannel? channel;
  final String? reference;
  final DateTime? recordedAt;
  final String? recordedByName;

  double get outstanding {
    final owed = entryFee - amountPaid;
    return owed <= 0 ? 0 : owed;
  }

  FeeState get state {
    if (entryFee <= 0 || amountPaid >= entryFee) return FeeState.paid;
    if (amountPaid > 0) return FeeState.partial;
    return FeeState.unpaid;
  }

  /// The two-letter fallback crest used everywhere a logo is missing.
  String get monogram {
    final explicit = teamMonogram?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit.toUpperCase();
    final words = teamName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return teamName.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentFeeEntry &&
          other.registrationId == registrationId &&
          other.amountPaid == amountPaid &&
          other.entryFee == entryFee &&
          other.channel == channel &&
          other.reference == reference &&
          other.recordedAt == recordedAt;

  @override
  int get hashCode => Object.hash(
        registrationId,
        amountPaid,
        entryFee,
        channel,
        reference,
        recordedAt,
      );
}

/// The three totals across the top of the ledger (artboard 24c).
@immutable
class FeeLedgerTotals {
  const FeeLedgerTotals({
    required this.expected,
    required this.collected,
    required this.teamCount,
    required this.unsettledTeams,
  });

  factory FeeLedgerTotals.from(List<TournamentFeeEntry> entries) {
    var expected = 0.0;
    var collected = 0.0;
    var unsettled = 0;
    for (final e in entries) {
      expected += e.entryFee;
      collected += e.amountPaid;
      if (e.state != FeeState.paid) unsettled++;
    }
    return FeeLedgerTotals(
      expected: expected,
      collected: collected,
      teamCount: entries.length,
      unsettledTeams: unsettled,
    );
  }

  final double expected;
  final double collected;
  final int teamCount;

  /// Teams that still owe something — the "3 teams" under Outstanding.
  final int unsettledTeams;

  double get outstanding {
    final owed = expected - collected;
    return owed <= 0 ? 0 : owed;
  }

  /// 0–1. Drives the progress bar; guards the free-cup divide-by-zero.
  double get collectedFraction {
    if (expected <= 0) return 1;
    final f = collected / expected;
    return f.clamp(0.0, 1.0);
  }

  int get collectedPercent => (collectedFraction * 100).round();
}
