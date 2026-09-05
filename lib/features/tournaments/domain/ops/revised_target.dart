import 'package:meta/meta.dart';

/// How the organiser arrived at the revised target (artboards 27m, 28b).
enum TargetMethod {
  /// Average run rate. Fully computed here — it is arithmetic, not a table.
  runRate('run_rate', 'Standard run-rate'),

  /// Duckworth–Lewis–Stern. The organiser reads the figure off the official
  /// DLS table (or the ICC app) and enters it; see the note on
  /// [RevisedTargetCalculator] for why this app does not compute it.
  dls('dls', 'DLS revised target'),

  /// The organiser sets the number outright — a local playing condition, or a
  /// figure both captains agreed at the ground.
  custom('custom', 'Custom target');

  const TargetMethod(this.wire, this.label);
  final String wire;
  final String label;

  static TargetMethod fromWire(String? wire) =>
      values.where((m) => m.wire == wire).firstOrNull ?? runRate;
}

/// The state of a match at the moment play stopped (artboards 27m, 28b).
@immutable
class StoppageContext {
  const StoppageContext({
    required this.originalOvers,
    required this.originalQuota,
    required this.inningsNumber,
    this.firstInningsRuns,
    this.chasingRuns = 0,
    this.chasingWickets = 0,
    this.chasingLegalBalls = 0,
    this.ballsPerOver = 6,
  });

  /// Overs per side before the interruption — 20 for a T20.
  final int originalOvers;

  /// Maximum overs one bowler may send down before the interruption.
  final int originalQuota;

  /// 1 while the side batting first is still in; 2 during the chase.
  final int inningsNumber;

  /// The first innings total. Null while the first innings is still going —
  /// a target cannot exist yet, so only the overs reduction is offered.
  final int? firstInningsRuns;

  final int chasingRuns;
  final int chasingWickets;

  /// Legal balls the chasing side has faced. 70 for "11.4 overs".
  final int chasingLegalBalls;

  final int ballsPerOver;

  bool get isChaseInterrupted => inningsNumber >= 2 && firstInningsRuns != null;

  /// "11.4" — cricket's `O.B` notation, a display transform of a ball count.
  String get oversBowledText {
    final overs = chasingLegalBalls ~/ ballsPerOver;
    final balls = chasingLegalBalls % ballsPerOver;
    return '$overs.$balls';
  }
}

/// What the sheet shows back to the organiser before they commit.
///
/// Every field is derived, so the preview the organiser reads to the captains
/// and the values written by `reviseMatchConditions` are the same numbers.
@immutable
class RevisedTargetPreview {
  const RevisedTargetPreview({
    required this.revisedOvers,
    required this.bowlerQuota,
    required this.method,
    required this.target,
    required this.ballsRemaining,
    required this.runsRequired,
    required this.parScore,
    required this.runsScored,
    required this.isValid,
    this.invalidReason,
  });

  final int revisedOvers;

  /// Max overs per bowler after the reduction.
  final int bowlerQuota;
  final TargetMethod method;

  /// Runs the chasing side needs to win. Null during a first-innings
  /// stoppage, where there is nothing to chase yet.
  final int? target;

  /// Balls left in the revised innings. Negative overs are impossible: the
  /// calculator floors this at zero.
  final int ballsRemaining;

  /// Runs still needed. Null when there is no target.
  final int? runsRequired;

  /// Where the chasing side "should" be right now, by simple proportion of the
  /// revised innings played. Null when there is no target.
  final int? parScore;

  /// What the chasing side actually has, so par can be read as a difference.
  final int runsScored;

  final bool isValid;
  final String? invalidReason;

  /// Runs per over the chase now needs. Null when there is no target, and
  /// infinite is reported as null rather than as a nonsense number.
  double? get requiredRunRate {
    final needed = runsRequired;
    if (needed == null || ballsRemaining <= 0) return null;
    return needed * 6 / ballsRemaining;
  }

  /// "Panthers +3" — runs ahead of (or behind) par at the stoppage.
  int? get parDifference {
    final par = parScore;
    return par == null ? null : runsScored - par;
  }
}

/// The one implementation of rain-revision arithmetic in the app.
///
/// ## Why DLS is entered rather than computed
///
/// Duckworth–Lewis–Stern is a lookup against the official resource table, not
/// a formula. Reproducing that table from memory is exactly the failure this
/// codebase already paid for once — see the scoring banner in CLAUDE.md, where
/// three disagreeing implementations of the laws appeared because the
/// arithmetic was written twice more "for convenience". A revised target
/// decides a real cup, so a table that is subtly wrong is worse than no table:
/// it is wrong *confidently*.
///
/// So the split is deliberate:
///
///  * **Run rate** is arithmetic and is computed here, exactly.
///  * **DLS** is a lookup. The organiser reads it off the official table or
///    the ICC's own app and types it in. The design already has them reading
///    the number back to both captains before committing — this keeps the
///    authority where it already sat.
///  * **Custom** is the organiser's own figure.
///
/// Everything *around* the target — balls left, required rate, par, the bowler
/// quota — is plain arithmetic and is computed for all three methods.
abstract final class RevisedTargetCalculator {
  /// A result needs at least this many overs per side (28b states the rule).
  static const int minimumOvers = 5;

  /// Standard playing condition: no bowler may send down more than a fifth of
  /// the innings. 20 overs → 4, 15 → 3, 14 → 3.
  static int quotaFor(int overs, {int bowlers = 5}) {
    if (overs <= 0) return 0;
    return (overs + bowlers - 1) ~/ bowlers;
  }

  /// Average-run-rate target: the first innings score scaled by the ratio of
  /// the two innings' lengths, plus one to win.
  static int runRateTarget({
    required int firstInningsRuns,
    required int originalOvers,
    required int revisedOvers,
  }) {
    if (originalOvers <= 0) return firstInningsRuns + 1;
    final scaled = firstInningsRuns * revisedOvers / originalOvers;
    return scaled.ceil() + 1;
  }

  /// Builds the preview the sheet renders.
  ///
  /// [enteredTarget] is only consulted for [TargetMethod.dls] and
  /// [TargetMethod.custom]; for [TargetMethod.runRate] the target is derived.
  static RevisedTargetPreview preview({
    required StoppageContext context,
    required int revisedOvers,
    required TargetMethod method,
    int? enteredTarget,
    int? bowlerQuotaOverride,
  }) {
    final quota = bowlerQuotaOverride ?? quotaFor(revisedOvers);

    String? invalid;
    if (revisedOvers < minimumOvers) {
      invalid = 'A result needs at least $minimumOvers overs per side.';
    } else if (revisedOvers > context.originalOvers) {
      invalid = 'Overs can only be reduced, not extended.';
    } else if (context.isChaseInterrupted &&
        revisedOvers * context.ballsPerOver < context.chasingLegalBalls) {
      // The chase has already passed the proposed length — reducing to here
      // would end the match retroactively, which is not a revision.
      invalid = 'The chase has already reached ${context.oversBowledText} '
          'overs — set at least ${_oversCeil(context)}.';
    }

    int? target;
    if (context.isChaseInterrupted) {
      switch (method) {
        case TargetMethod.runRate:
          target = runRateTarget(
            firstInningsRuns: context.firstInningsRuns!,
            originalOvers: context.originalOvers,
            revisedOvers: revisedOvers,
          );
        case TargetMethod.dls:
        case TargetMethod.custom:
          target = enteredTarget;
          if (target == null) {
            invalid ??= method == TargetMethod.dls
                ? 'Enter the target from the official DLS table.'
                : 'Enter the target you have agreed.';
          } else if (target < 1) {
            invalid ??= 'A target must be at least 1 run.';
          }
      }
    }

    final totalBalls = revisedOvers * context.ballsPerOver;
    final ballsRemaining = context.isChaseInterrupted
        ? (totalBalls - context.chasingLegalBalls).clamp(0, totalBalls)
        : totalBalls;

    int? runsRequired;
    int? par;
    if (target != null) {
      final needed = target - context.chasingRuns;
      runsRequired = needed < 0 ? 0 : needed;
      // Where the chase "should" be, by share of the revised innings played.
      par = totalBalls <= 0
          ? null
          : (target * context.chasingLegalBalls / totalBalls).round();
    }

    return RevisedTargetPreview(
      revisedOvers: revisedOvers,
      bowlerQuota: quota,
      method: method,
      target: target,
      ballsRemaining: ballsRemaining,
      runsRequired: runsRequired,
      parScore: par,
      runsScored: context.chasingRuns,
      isValid: invalid == null,
      invalidReason: invalid,
    );
  }

  /// Smallest legal revised length given how far the chase has already gone.
  static int _oversCeil(StoppageContext c) {
    final full = (c.chasingLegalBalls + c.ballsPerOver - 1) ~/ c.ballsPerOver;
    return full < minimumOvers ? minimumOvers : full;
  }

  /// The smallest revision the organiser may pick right now.
  static int minimumSelectableOvers(StoppageContext context) =>
      context.isChaseInterrupted ? _oversCeil(context) : minimumOvers;
}
