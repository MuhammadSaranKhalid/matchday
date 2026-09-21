import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_relationship.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';
import '../widgets/challenge/step_format.dart';
import '../widgets/challenge/step_review.dart';
import '../widgets/challenge/step_when_where.dart';
import '../widgets/wizard/step_open_or_direct.dart';
import '../widgets/wizard/wizard_kit.dart';

/// Sender side of the challenge handshake. 6 steps on one screen, matching
/// the Match Challenge Flow design:
/// 1. Team — which of your teams is issuing (auto-skipped when you manage 1)
/// 2. Opponent — pick the team you're challenging
/// 3. Format — preset tile grid (no knob overrides per final landing)
/// 4. When & Where — day strip + time chips + venue (with map preview)
/// 5. Pick XI — squad checklist + wicket-keeper picker
/// 6. Review + optional message → send
///
/// Entry is the `+ Challenge` button on My Matches → `/challenge`
/// (no preselected team) or `/teams/:teamId/challenge` for a deep link.
class ChallengeSendScreen extends ConsumerStatefulWidget {
  const ChallengeSendScreen({
    super.key,
    this.fromTeamId,
    this.openOnly = false,
  });

  /// Optional preselected team. When null the screen renders the team-pick
  /// step first; when set it skips straight to the opponent picker.
  final String? fromTeamId;

  /// Entered from a pool surface (My challenges → New challenge), where the
  /// open-vs-direct question is already answered. The opponent step is then
  /// dropped from the flow entirely rather than shown pre-answered: a step
  /// whose only outcome is the one you already chose is not a step.
  final bool openOnly;

  @override
  ConsumerState<ChallengeSendScreen> createState() =>
      _ChallengeSendScreenState();
}

/// Scheduling only. Locking an XI is deliberately NOT part of posting a
/// challenge — see [_steps].
enum _Step { team, opponent, format, whenWhere, review }

class _ChallengeSendScreenState extends ConsumerState<ChallengeSendScreen> {
  late _Step _step;
  bool _busy = false;

  // Form data — sane defaults so a captain in a rush can hit Continue × 3.
  Team? _fromTeam;
  Team? _opponent;
  bool _isOpenChallenge = false;
  String _opponentSearch = '';

  // Format — the three questions artboard 07 asks, plus the engine defaults
  // that ride along unchanged.
  int _overs = 20;
  int _playersPerSide = 11;
  MatchBallType _ball = MatchBallType.tape;
  // Engine knobs the design does not expose. They ride along at their
  // defaults so the format the challenge ships is still complete.
  final int _maxOversPerBowler = 4;
  final int _ballsPerOver = 6;
  final int _inningsPerSide = 1;
  final int? _endChangeBalls = null;

  // When & where — day + time as separate state, combined for send.
  DateTime? _pickedDay;
  String? _pickedTime; // 'HH:mm'

  // When & where — Flexible drops the time so the card reads "Flexible".
  bool _flexible = false;

  final _venueCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  /// The steps this run actually walks, in order. Both the team step and the
  /// opponent step drop out depending on how the wizard was entered, so
  /// everything downstream — progress, "step N of M", next/back — counts off
  /// this list rather than the enum.
  ///
  /// Posting a challenge is **scheduling**, not team selection: it settles
  /// when, where and what format. Who actually plays is decided at the ground,
  /// on the match-start lineup screen, where a captain can still add the two
  /// lads who turned up. Committing an XI here would freeze a squad days early
  /// and make every late change a re-post.
  ///
  /// The server already expects this — `send_match_request` defaults
  /// `from_team_xi` to empty, and `accept_match_request` then materialises the
  /// full active roster (migration 20260529142241), which the lineup screen
  /// narrows on the day. Tournament fixtures are a different matter: their
  /// squads are locked to the registration list, and they are not created
  /// through this wizard.
  List<_Step> get _steps => [
    if (widget.fromTeamId == null) _Step.team,
    if (!widget.openOnly) _Step.opponent,
    _Step.format,
    _Step.whenWhere,
    _Step.review,
  ];

  @override
  void initState() {
    super.initState();
    _isOpenChallenge = widget.openOnly;
    _step = _steps.first;
    _seedWhen();
  }

  /// Open the When & where step already answered, the way artboard 08 draws
  /// it — a day chip lit and a time in the field. A wizard that opens with a
  /// disabled Continue makes the captain do setup before it will let them
  /// start, and the common case really is "a couple of hours from now".
  ///
  /// Rounded to the next half hour, and rolled to tomorrow morning if that
  /// would land after the evening.
  void _seedWhen() {
    final soon = DateTime.now().add(const Duration(hours: 2));
    final rounded = DateTime(
      soon.year,
      soon.month,
      soon.day,
      soon.hour,
      soon.minute <= 30 ? 30 : 0,
    ).add(soon.minute <= 30 ? Duration.zero : const Duration(hours: 1));

    final tooLate = rounded.hour >= 21 || rounded.day != DateTime.now().day;
    final start =
        tooLate
            ? DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ).add(const Duration(days: 1, hours: 9))
            : rounded;

    _pickedDay = DateTime(start.year, start.month, start.day);
    _pickedTime =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _venueCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  /// Combine day + time into a `DateTime` for review + send. Returns null
  /// when either piece is missing.
  DateTime? get _startTime {
    final d = _pickedDay;
    final t = _pickedTime;
    // Flexible posts the day with no committed hour; the card then renders
    // "Flexible" rather than a time both captains would have to honour.
    if (d != null && _flexible) return DateTime(d.year, d.month, d.day);
    if (d == null || t == null) return null;
    final parts = t.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(d.year, d.month, d.day, h, m);
  }

  bool get _canContinue {
    if (_busy) return false;
    switch (_step) {
      case _Step.team:
        return _fromTeam != null;
      case _Step.opponent:
        // Open needs nothing further; Direct has to name its opponent.
        return _isOpenChallenge || _opponent != null;
      case _Step.format:
        return _overs > 0 && _playersPerSide >= 5 && _playersPerSide <= 15;
      case _Step.whenWhere:
        // The venue is explicitly optional (artboard 08), and Flexible stands
        // in for a time nobody has agreed yet — so a day is all this step
        // actually requires.
        return _pickedDay != null && (_flexible || _pickedTime != null);
      case _Step.review:
        return true;
    }
  }

  /// Effective from-team id — either the route param or the picked team.
  String? get _resolvedFromTeamId => widget.fromTeamId ?? _fromTeam?.id.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizardTopBar(
              title: _barTitle,
              onBack: _onBack,
              trailing: _barTrailing,
            ),
            WizardProgress(index: _steps.indexOf(_step), total: _steps.length),
            Expanded(child: _body()),
            WizardFooter(
              label: _ctaLabel,
              enabled: _canContinue,
              busy: _busy,
              hint:
                  _step == _Step.format
                      ? 'Both captains can change format up to 12h before the toss.'
                      : null,
              onPressed: _advance,
            ),
          ],
        ),
      ),
    );
  }

  /// Most steps are "New challenge"; the two that are really their own screen
  /// say what they are.
  String get _barTitle => _step == _Step.review ? 'Review' : 'New challenge';

  Widget get _barTrailing =>
      WizardStepCount(index: _steps.indexOf(_step), total: _steps.length);

  String get _ctaLabel {
    // Artboard 06–09 all read plainly "Continue"; only the commit names what
    // it does. The old screen restated the current selection on every button,
    // which made the CTA a status line rather than an action.
    if (_step != _Step.review) return 'Continue';
    return _isOpenChallenge ? 'Post to the pool' : 'Send challenge';
  }

  void _onBack() {
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i <= 0) {
      context.pop();
    } else {
      setState(() => _step = steps[i - 1]);
    }
  }

  void _advance() {
    if (_step == _Step.review) {
      _send();
      return;
    }
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i >= 0 && i < steps.length - 1) {
      setState(() => _step = steps[i + 1]);
    }
  }

  Future<void> _send() async {
    final opp = _opponent;
    final start = _startTime;
    final fromId = _resolvedFromTeamId;
    if ((!_isOpenChallenge && opp == null) || start == null || fromId == null) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(matchesRepositoryProvider)
        .sendMatchChallenge(
          fromTeamId: TeamId(fromId),
          toTeamId: _isOpenChallenge ? null : opp?.id,
          proposedStartTime: start,
          proposedVenue: _venueCtrl.text.trim(),
          proposedFormat: MatchFormat(
            oversPerInnings: _overs,
            playersPerTeam: _playersPerSide,
            ballType: _ball,
            maxOversPerBowler: _maxOversPerBowler,
            ballsPerOver: _ballsPerOver,
            inningsPerSide: _inningsPerSide,
            endChangeBalls: _endChangeBalls,
          ),
          message:
              _messageCtrl.text.trim().isEmpty
                  ? null
                  : _messageCtrl.text.trim(),
          playersPerSide: _playersPerSide,
          // Empty by design: the accept RPC fills the match with the full
          // active roster, and the lineup screen picks the XI at the ground.
          fromTeamXi: const [],
          fromTeamKeeperId: null,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (id) {
        ref.invalidate(myMatchChallengesProvider);
        context.go('/challenges/${id.value}/sent');
      },
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.team:
        return _TeamStep(
          selected: _fromTeam,
          onPick: (t) => setState(() => _fromTeam = t),
          onSingle: (t) {
            // Auto-pick + auto-advance when the captain has exactly one team.
            if (_fromTeam == null) {
              _fromTeam = t;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _step == _Step.team) {
                  setState(() => _step = _Step.opponent);
                }
              });
            }
          },
        );
      case _Step.opponent:
        final fromId = _resolvedFromTeamId;
        if (fromId == null) {
          return const Center(
            child: Text('Pick a team to issue the challenge as.'),
          );
        }
        return StepOpenOrDirect(
          isOpen: _isOpenChallenge,
          onSelect:
              (bool open) => setState(() {
                _isOpenChallenge = open;
                if (open) _opponent = null;
              }),
          // The design draws only the fork, because its Open card is selected.
          // Direct has to name a team somewhere and the flow is six steps
          // either way, so the picker unfolds under the card that asked for it
          // rather than becoming a seventh step.
          directContent: _OpponentPicker(
            query: _opponentSearch,
            selected: _opponent,
            fromTeamId: TeamId(fromId),
            onSearch: (q) => setState(() => _opponentSearch = q),
            onPick: (t) => setState(() => _opponent = t),
          ),
        );
      case _Step.format:
        return StepFormat(
          overs: _overs,
          ball: _ball,
          playersPerSide: _playersPerSide,
          onOvers: (v) => setState(() => _overs = v),
          onBall: (b) => setState(() => _ball = b),
          onPlayers: (n) => setState(() => _playersPerSide = n),
        );
      case _Step.whenWhere:
        return StepWhenWhere(
          day: _pickedDay,
          time: _minutesFromHhmm(_pickedTime),
          flexible: _flexible,
          venueController: _venueCtrl,
          onDay: (d) => setState(() => _pickedDay = d),
          onTime:
              (m) => setState(() {
                _pickedTime =
                    '${(m ~/ 60).toString().padLeft(2, '0')}:'
                    '${(m % 60).toString().padLeft(2, '0')}';
              }),
          onFlexible: (v) => setState(() => _flexible = v),
        );
      case _Step.review:
        return _ReviewStepHost(
          fromTeam: _fromTeam,
          fromTeamId: _resolvedFromTeamId,
          opponent: _opponent,
          isOpen: _isOpenChallenge,
          day: _pickedDay,
          timeLabel:
              _flexible
                  ? 'Flexible'
                  : (_pickedTime == null
                      ? 'Not set'
                      : clockLabel(_minutesFromHhmm(_pickedTime)!)),
          venue: _venueCtrl.text.trim(),
          formatLine: formatSpecLine(
            overs: _overs,
            ball: _ball,
            playersPerSide: _playersPerSide,
          ),
          noteController: _messageCtrl,
          onEdit: (s) => setState(() => _step = s),
        );
    }
  }

  /// 'HH:mm' → minutes since midnight, the shape artboard 08's field speaks.
  static int? _minutesFromHhmm(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first);
    if (h == null) return null;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }
}

/// Bridges the screen's `_fromTeam` + roster (via `rosterProvider`) into
/// the domain-agnostic [StepReview] view shape. Kept here for the same
/// reason as [_PickXiStep] — the widget stays portable.
/// Bridges the screen's team + roster into artboard 10's summary lines.
class _ReviewStepHost extends ConsumerWidget {
  const _ReviewStepHost({
    required this.fromTeam,
    required this.fromTeamId,
    required this.opponent,
    required this.isOpen,
    required this.day,
    required this.timeLabel,
    required this.venue,
    required this.formatLine,
    required this.noteController,
    required this.onEdit,
  });

  final Team? fromTeam;
  final String? fromTeamId;
  final Team? opponent;
  final bool isOpen;
  final DateTime? day;
  final String timeLabel;
  final String venue;
  final String formatLine;
  final TextEditingController noteController;
  final ValueChanged<_Step> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepReview(
      team: isOpen ? fromTeam : (opponent ?? fromTeam),
      formatLine: formatLine,
      whenLine: day == null ? 'Not set' : '${_dayLabel(day!)} · $timeLabel',
      whereLine: venue.isEmpty ? 'To be agreed' : venue,
      noteController: noteController,
      onEditFormat: () => onEdit(_Step.format),
      onEditWhen: () => onEdit(_Step.whenWhere),
      onEditWhere: () => onEdit(_Step.whenWhere),
    );
  }
}

/// "Today" / "Tomorrow" / "Sat, Sep 6" for the review's When row.
String _dayLabel(DateTime d) {
  final now = DateTime.now();
  final delta =
      DateTime(
        d.year,
        d.month,
        d.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Tomorrow';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

// ─── Header / Footer ──────────────────────────────────────────────────────

class _TeamStep extends ConsumerWidget {
  const _TeamStep({
    required this.selected,
    required this.onPick,
    required this.onSingle,
  });

  final Team? selected;
  final ValueChanged<Team> onPick;
  final ValueChanged<Team> onSingle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mineAsync = ref.watch(currentUserTeamMembershipsProvider);
    return mineAsync.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(e.toString(), textAlign: TextAlign.center),
            ),
          ),
      data: (memberships) {
        final mine = memberships
            .where((membership) => membership.relationship.canSendChallenge)
            .toList(growable: false);
        if (mine.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(18, 32, 18, 18),
            child: Text(
              'You need to own or manage a team to issue a challenge. Create '
              'one or ask an owner to appoint you as manager.',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (mine.length == 1) {
          onSingle(mine.single.team);
          return const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                'You manage ${_countLabel(mine.length)}. Issue the challenge '
                "as one of them — your XI options come from this squad later.",
                style: CkType.body(
                  fontSize: 13,
                  color: CkColors.ink2,
                  height: 1.45,
                ),
              ),
            ),
            const _SectionLabel('Eligible to challenge as'),
            const SizedBox(height: 8),
            for (final membership in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MyTeamRow(
                  team: membership.team,
                  role: membership.relationship,
                  disabledNote: null,
                  selected: selected?.id == membership.team.id,
                  onTap: () => onPick(membership.team),
                ),
              ),
            const SizedBox(height: 6),
            const _InfoCard(
              text:
                  "Captain-only membership can’t initiate challenges. The team "
                  'owner or a manager can send one.',
            ),
          ],
        );
      },
    );
  }

  static String _countLabel(int n) {
    if (n == 2) return 'two sides';
    if (n == 3) return 'three sides';
    if (n == 4) return 'four sides';
    if (n == 5) return 'five sides';
    return '$n sides';
  }
}

class _MyTeamRow extends StatelessWidget {
  const _MyTeamRow({
    required this.team,
    required this.role,
    required this.selected,
    required this.onTap,
    this.disabledNote,
  });

  final Team team;
  final TeamRelationship role;
  final bool selected;
  final VoidCallback onTap;

  /// Non-null = row is disabled (manager-only, not active, etc.).
  /// Renders the amber "not active on app" line.
  final String? disabledNote;

  @override
  Widget build(BuildContext context) {
    final disabled = disabledNote != null;
    final border = selected ? CkColors.ink : CkColors.hairline;
    return Opacity(
      opacity: disabled ? 0.65 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _teamColor(team.primaryColor),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  _short(team),
                  style: CkType.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CkColors.paper,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            team.name,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RolePill(role: role),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _secondaryLine(team),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                    if (disabledNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          disabledNote!,
                          style: CkType.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CkColors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CkColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: CkColors.paper,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _secondaryLine(Team t) {
    if (t.homeGround != null && t.homeGround!.isNotEmpty) return t.homeGround!;
    if (t.tagline != null && t.tagline!.isNotEmpty) return t.tagline!;
    return 'Tap to issue the challenge';
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final TeamRelationship role;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (role) {
      TeamRelationship.owner => ('OWNER', CkColors.red, CkColors.paper),
      TeamRelationship.manager => ('MANAGER', CkColors.paper2, CkColors.ink2),
      TeamRelationship.captain => ('CAPTAIN', CkColors.cream, CkColors.ink2),
      TeamRelationship.player => ('PLAYER', CkColors.paper2, CkColors.ink2),
      TeamRelationship.none => ('MEMBER', CkColors.paper2, CkColors.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: CkColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: CkType.body(
                fontSize: 11.5,
                color: CkColors.ink2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2 · Opponent ────────────────────────────────────────────────────

/// Artboard 06's Direct branch — search + the teams you can challenge.
class _OpponentPicker extends ConsumerWidget {
  const _OpponentPicker({
    required this.query,
    required this.selected,
    required this.fromTeamId,
    required this.onSearch,
    required this.onPick,
  });

  final String query;
  final Team? selected;
  final TeamId fromTeamId;
  final ValueChanged<String> onSearch;
  final ValueChanged<Team> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all =
        ref.watch(discoverableTeamsProvider(query)).value ?? const <Team>[];
    final q = query.trim().toLowerCase();
    final visible =
        all
            .where((t) => t.id != fromTeamId)
            .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: onSearch,
          style: CkType.body(fontSize: 14, color: CkColors.ink),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search teams',
            hintStyle: CkType.body(fontSize: 14, color: CkColors.soft),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: CkColors.muted,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No teams match that search.',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
          )
        else
          for (final t in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _TeamRow(
                team: t,
                selected: selected?.id == t.id,
                onTap: () => onPick(t),
              ),
            ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.selected,
    required this.onTap,
  });
  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper2 : CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _teamColor(team.primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _short(team),
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    team.name,
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                    ),
                  ),
                  if (team.homeGround != null)
                    Text(
                      team.homeGround!,
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: CkColors.ink),
          ],
        ),
      ),
    );
  }
}

// ─── Atoms ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

String _short(Team t) {
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters =
      t.name
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0])
          .join();
  return letters.isEmpty ? '??' : letters.toUpperCase();
}

Color _teamColor(String? hex) {
  if (hex == null || hex.isEmpty) return CkColors.muted;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return CkColors.muted;
}
