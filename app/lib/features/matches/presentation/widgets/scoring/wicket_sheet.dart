// Multi-stage dismissal entry: type -> fielder -> run-out end -> next batter.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';
import 'sheet_kit.dart';

class WicketResult {
  const WicketResult({
    required this.type,
    this.fielderMatchPlayerId,
    this.whoOutNonStriker = false,
    this.runsBefore = 0,
    this.nextBatterMatchPlayerId,
  });
  final WicketType type;
  final String? fielderMatchPlayerId;
  final bool whoOutNonStriker;
  final int runsBefore;
  final String? nextBatterMatchPlayerId;
}

enum _WicketStage { type, fielder, runout, batter }

class WicketSheet extends StatefulWidget {
  const WicketSheet({
    super.key,
    required this.overs,
    required this.totalRuns,
    required this.totalWickets,
    required this.strikerName,
    required this.nonStrikerName,
    required this.bowlerName,
    required this.fielders,
    required this.bench,
    this.freeHit = false,
  });
  final String overs;
  final int totalRuns;
  final int totalWickets;
  final String strikerName;
  final String nonStrikerName;
  final String bowlerName;
  final List<SheetPerson> fielders;
  final List<SheetPerson> bench;

  /// The delivery being scored is a free hit, so the batter can only be
  /// dismissed by a run-out. The scoring screen already tells the scorer this
  /// in a banner; without it here the sheet contradicted that banner by
  /// offering bowled / caught / LBW / stumped / hit-wicket anyway.
  final bool freeHit;

  @override
  State<WicketSheet> createState() => _WicketSheetState();
}

class _WicketSheetState extends State<WicketSheet> {
  _WicketStage _stage = _WicketStage.type;
  WicketType? _type;
  String? _fielderMpId;
  bool _whoOutNonStriker = false;
  int _runsBefore = 0;
  String? _nextBatterMpId;

  static const _allTypes = [
    (WicketType.bowled, 'Bowled', 'Ball hits the stumps'),
    (WicketType.caught, 'Caught', 'Fielder takes the catch'),
    (WicketType.lbw, 'LBW', 'Leg before wicket'),
    (WicketType.runOut, 'Run out', 'Short of the crease'),
    (WicketType.stumped, 'Stumped', 'Keeper whips the bails'),
    (WicketType.hitWicket, 'Hit wkt', 'Disturbs own stumps'),
  ];

  /// Dismissals that stand on a free hit.
  ///
  /// This list is not a UI opinion — it mirrors, exactly, the server's
  /// `applyBall` guard and the `balls_free_hit_dismissal_check` constraint on
  /// the balls table. Anything outside it is rejected by the write path, so
  /// offering it would only produce a failed save. Anything inside it is a
  /// legal entry, so filtering it out would block a real dismissal.
  ///
  /// `obstructing` and `handled_ball` are also allowed server-side but this
  /// sheet does not offer them on any delivery, free hit or not.
  static const _freeHitTypes = [WicketType.runOut, WicketType.hitWicket];

  List<(WicketType, String, String)> get _types =>
      widget.freeHit
          ? [
            for (final t in _allTypes)
              if (_freeHitTypes.contains(t.$1)) t,
          ]
          : _allTypes;

  bool get _needsFielder =>
      _type == WicketType.caught || _type == WicketType.stumped;
  bool get _isRunout => _type == WicketType.runOut;

  bool get _canProceed {
    switch (_stage) {
      case _WicketStage.type:
        return _type != null;
      case _WicketStage.fielder:
        return _fielderMpId != null;
      case _WicketStage.runout:
        return true;
      case _WicketStage.batter:
        return _nextBatterMpId != null || widget.bench.isEmpty;
    }
  }

  String get _ctaLabel {
    if (_stage == _WicketStage.batter) return 'Confirm wicket';
    if (_stage == _WicketStage.type) {
      if (_needsFielder) return 'Next · fielder';
      if (_isRunout) return 'Next · details';
    }
    return 'Next · batter';
  }

  void _next() {
    if (!_canProceed) return;
    if (_stage == _WicketStage.type) {
      if (_needsFielder) {
        setState(() => _stage = _WicketStage.fielder);
      } else if (_isRunout) {
        setState(() => _stage = _WicketStage.runout);
      } else {
        setState(() => _stage = _WicketStage.batter);
      }
      return;
    }
    if (_stage == _WicketStage.fielder || _stage == _WicketStage.runout) {
      setState(() => _stage = _WicketStage.batter);
      return;
    }
    if (_stage == _WicketStage.batter) {
      Navigator.of(context).pop(
        WicketResult(
          type: _type!,
          fielderMatchPlayerId: _fielderMpId,
          whoOutNonStriker: _isRunout && _whoOutNonStriker,
          runsBefore: _isRunout ? _runsBefore : 0,
          nextBatterMatchPlayerId: _nextBatterMpId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      _WicketStage.type,
      if (_needsFielder) _WicketStage.fielder,
      if (_isRunout) _WicketStage.runout,
      _WicketStage.batter,
    ];
    final activeIdx = stages.indexOf(_stage);

    return SheetScrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (var i = 0; i < stages.length; i++) ...[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color:
                              i <= activeIdx ? CkColors.red : CkColors.paper2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (i != stages.length - 1) const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
            if (_stage == _WicketStage.type) ..._typeStage(),
            if (_stage == _WicketStage.fielder) ..._fielderStage(),
            if (_stage == _WicketStage.runout) ..._runoutStage(),
            if (_stage == _WicketStage.batter) ..._batterStage(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SheetGhostButton(
                    label: _stage == _WicketStage.type ? 'Cancel' : 'Back',
                    onTap: () {
                      if (_stage == _WicketStage.type) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _stage = _WicketStage.type);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SheetPrimaryButton(
                    label: _ctaLabel,
                    danger: true,
                    onTap: _canProceed ? _next : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _typeStage() => [
    SheetHead(
      kicker:
          widget.freeHit
              ? 'FREE HIT · ${widget.overs} · ${widget.totalRuns}/${widget.totalWickets}'
              : 'WICKET · ${widget.overs} · ${widget.totalRuns}/${widget.totalWickets}',
      kickerColor: CkColors.red,
      title: 'How was the batter out?',
      subtitle:
          widget.freeHit
              ? '${widget.strikerName} on strike · free hit — only a run-out '
                  'or hit wicket can dismiss.'
              : '${widget.strikerName} on strike · bowler ${widget.bowlerName}',
    ),
    GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: [
        for (final entry in _types)
          SheetChoiceButton(
            title: entry.$2,
            subtitle: entry.$3,
            active: _type == entry.$1,
            onTap: () => setState(() => _type = entry.$1),
            tone: SheetChoiceTone.red,
          ),
      ],
    ),
  ];

  List<Widget> _fielderStage() {
    final isStumped = _type == WicketType.stumped;
    return [
      SheetHead(
        kicker: isStumped ? 'STUMPED BY' : 'CAUGHT BY',
        kickerColor: CkColors.red,
        title: isStumped ? 'Who stumped them?' : 'Who took the catch?',
        subtitle: '${widget.strikerName} · b ${widget.bowlerName}',
      ),
      SheetPersonGrid(
        people: widget.fielders,
        value: _fielderMpId,
        onPick: (id) => setState(() => _fielderMpId = id),
      ),
    ];
  }

  List<Widget> _runoutStage() {
    return [
      const SheetHead(
        kicker: 'RUN OUT',
        kickerColor: CkColors.red,
        title: 'Run-out details',
        subtitle:
            'Which batter was out, and how many runs were completed first?',
      ),
      Text(
        'BATTER OUT',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: SheetChoiceButton(
              title: widget.strikerName,
              subtitle: 'STRIKER',
              active: !_whoOutNonStriker,
              onTap: () => setState(() => _whoOutNonStriker = false),
              tone: SheetChoiceTone.red,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SheetChoiceButton(
              title: widget.nonStrikerName,
              subtitle: 'NON-STRIKER',
              active: _whoOutNonStriker,
              onTap: () => setState(() => _whoOutNonStriker = true),
              tone: SheetChoiceTone.red,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'RUNS COMPLETED BEFORE',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      SheetRunChips(
        value: _runsBefore,
        options: const [0, 1, 2, 3],
        accent: CkColors.red,
        onPick: (r) => setState(() => _runsBefore = r),
      ),
      const SizedBox(height: 16),
      Text(
        'THROWN / TAKEN BY · OPTIONAL',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      SheetPersonGrid(
        people: widget.fielders,
        value: _fielderMpId,
        onPick: (id) => setState(() => _fielderMpId = id),
      ),
    ];
  }

  List<Widget> _batterStage() {
    return [
      SheetHead(
        kicker: '${widget.totalWickets + 1} DOWN',
        kickerColor: CkColors.red,
        title: 'Who comes in?',
      ),
      if (widget.bench.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                "That's all out.",
                style: CkType.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No batters remain. The innings closes.',
                style: CkType.body(
                  fontSize: 12,
                  color: const Color(0xCCFDFAF4),
                ),
              ),
            ],
          ),
        )
      else
        SheetPersonGrid(
          people: widget.bench,
          value: _nextBatterMpId,
          onPick: (id) => setState(() => _nextBatterMpId = id),
        ),
    ];
  }
}
