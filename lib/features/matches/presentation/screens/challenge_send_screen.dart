import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/format_preset.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';
import '../widgets/challenge/ch_role_pill.dart';
import '../widgets/challenge/step_format.dart';
import '../widgets/challenge/step_pick_xi.dart';
import '../widgets/challenge/step_review.dart';
import '../widgets/challenge/step_when_where.dart';

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
  const ChallengeSendScreen({super.key, this.fromTeamId});

  /// Optional preselected team. When null the screen renders the team-pick
  /// step first; when set it skips straight to the opponent picker.
  final String? fromTeamId;

  @override
  ConsumerState<ChallengeSendScreen> createState() =>
      _ChallengeSendScreenState();
}

enum _Step { team, opponent, format, whenWhere, xi, review }

class _ChallengeSendScreenState extends ConsumerState<ChallengeSendScreen> {
  late _Step _step;
  bool _busy = false;

  // Form data — sane defaults so a captain in a rush can hit Continue × 3.
  Team? _fromTeam;
  Team? _opponent;
  bool _isOpenChallenge = false;
  String _opponentSearch = '';

  // Format — preset id + the snapshotted MatchFormat that ships.
  String? _presetId;
  int _overs = 20;
  int _playersPerSide = 11;
  MatchBallType _ball = MatchBallType.tape;
  int _maxOversPerBowler = 4;
  int _ballsPerOver = 6;
  int _inningsPerSide = 1;
  int? _endChangeBalls;

  // When & where — day + time as separate state, combined for send.
  DateTime? _pickedDay;
  String? _pickedTime; // 'HH:mm'

  // Pick XI — selected player ids + the keeper id.
  final Set<String> _xi = <String>{};
  String? _keeperId;

  final _venueCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _step = widget.fromTeamId == null ? _Step.team : _Step.opponent;
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
    if (d == null || t == null) return null;
    final parts = t.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(d.year, d.month, d.day, h, m);
  }

  bool get _canContinue {
    switch (_step) {
      case _Step.team:
        return _fromTeam != null;
      case _Step.opponent:
        return _isOpenChallenge || _opponent != null;
      case _Step.format:
        // Preset always selected (seeded to first preset on load).
        return _overs > 0 && _playersPerSide >= 5 && _playersPerSide <= 15;
      case _Step.whenWhere:
        final start = _startTime;
        return start != null && _venueCtrl.text.trim().isNotEmpty;
      case _Step.xi:
        return _xi.length == _playersPerSide &&
            _keeperId != null &&
            _xi.contains(_keeperId);
      case _Step.review:
        return true;
    }
  }

  /// Effective from-team id — either the route param or the picked team.
  String? get _resolvedFromTeamId =>
      widget.fromTeamId ?? _fromTeam?.id.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(step: _step, onBack: _onBack),
            Expanded(child: _body()),
            _Footer(
              label: _ctaLabel,
              enabled: _canContinue && !_busy,
              busy: _busy,
              hint: _step == _Step.format
                  ? 'Both captains can change format up to 12h before the toss.'
                  : null,
              onPressed: () => _advance(),
            ),
          ],
        ),
      ),
    );
  }

  String get _ctaLabel {
    if (_step == _Step.review) {
      return _isOpenChallenge ? 'Broadcast open challenge' : 'Send challenge';
    }
    if (_step == _Step.team && _fromTeam != null) {
      return 'Continue as ${_fromTeam!.name} →';
    }
    if (_step == _Step.opponent) {
      if (_isOpenChallenge) return 'Continue with Open Challenge →';
      if (_opponent != null) return 'Continue vs ${_opponent!.name} →';
    }
    if (_step == _Step.format) {
      final label = _presetLabel ?? 'T$_overs';
      return 'Continue · $label · $_playersPerSide/side';
    }
    if (_step == _Step.whenWhere && _startTime != null) {
      final venue = _venueCtrl.text.trim();
      final whenLabel = _whenShort(_startTime!);
      if (venue.isEmpty) return 'Continue · $whenLabel →';
      return 'Continue · $whenLabel · ${_venueShort(venue)} →';
    }
    if (_step == _Step.xi) {
      if (_xi.length < _playersPerSide) {
        return 'Pick ${_playersPerSide - _xi.length} more';
      }
      if (_keeperId == null) return 'Choose a keeper';
      return 'Continue';
    }
    return 'Continue →';
  }

  /// Display label for the currently-picked preset. The screen doesn't keep
  /// the preset's label in state (only the id + the snapshotted knobs), so
  /// this looks it up from the cached `formatPresetsProvider` value.
  String? get _presetLabel {
    if (_presetId == null) return null;
    final presets =
        ref.read(formatPresetsProvider).value ?? const <FormatPreset>[];
    for (final p in presets) {
      if (p.id == _presetId) return p.label;
    }
    return null;
  }

  String _whenShort(DateTime t) {
    final dow =
        const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$dow $hh:$mm';
  }

  String _venueShort(String v) {
    // Strip everything after the first " · " so the CTA stays tight.
    final i = v.indexOf(' · ');
    return i == -1 ? v : v.substring(0, i);
  }

  void _onBack() {
    final atFirst =
        _step == _Step.team || (_step == _Step.opponent && widget.fromTeamId != null);
    if (atFirst) {
      context.pop();
    } else {
      setState(() => _step = _Step.values[_step.index - 1]);
    }
  }

  void _advance() {
    if (_step == _Step.review) {
      _send();
      return;
    }
    // Leaving When & where → Pick XI: try to auto-skip when the roster size
    // exactly matches the format (no choice for the captain to make).
    if (_step == _Step.whenWhere) {
      final teamId = _resolvedFromTeamId;
      final rosterSize = teamId == null
          ? 0
          : ref.read(rosterProvider(teamId)).value?.length ?? 0;
      if (rosterSize > 0 && rosterSize == _playersPerSide) {
        final roster = ref.read(rosterProvider(teamId!)).value!;
        _xi
          ..clear()
          ..addAll(roster.map((r) => r.member.playerId));
        _keeperId = _pickKeeperId(roster);
        setState(() => _step = _Step.review);
        return;
      }
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  /// Default keeper pick — first WK-role row, else row 2, else row 1.
  /// Mirrors `StepXI` line 170 in the JSX.
  String? _pickKeeperId(List<RosterMember> roster) {
    final slice = roster.take(_playersPerSide).toList();
    if (slice.isEmpty) return null;
    for (final r in slice) {
      if (r.member.role == MemberRole.wicketKeeper) return r.member.playerId;
    }
    return slice.length >= 2
        ? slice[1].member.playerId
        : slice.first.member.playerId;
  }

  Future<void> _send() async {
    final opp = _opponent;
    final start = _startTime;
    final fromId = _resolvedFromTeamId;
    if ((!_isOpenChallenge && opp == null) || start == null || fromId == null) return;
    setState(() => _busy = true);
    final result = await ref.read(matchesRepositoryProvider).sendMatchChallenge(
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
          message: _messageCtrl.text.trim().isEmpty
              ? null
              : _messageCtrl.text.trim(),
          playersPerSide: _playersPerSide,
          fromTeamXi: _xi.toList(),
          fromTeamKeeperId: _keeperId,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (id) {
        ref.invalidate(myMatchChallengesProvider);
        context.go('/challenges/${id.value}/sent');
      },
    );
  }

  /// Apply a format preset — snapshots every knob from the chosen format
  /// (see CRICKET_FORMATS.md). Resets the XI because `playersPerTeam` may
  /// have changed; the captain re-picks on the next step.
  void _applyPreset(FormatPreset p) {
    setState(() {
      final f = p.format;
      _presetId = p.id;
      _overs = f.oversPerInnings;
      _playersPerSide = f.playersPerTeam;
      _ball = f.ballType;
      _ballsPerOver = f.ballsPerOver;
      _inningsPerSide = f.inningsPerSide;
      _maxOversPerBowler = f.maxOversPerBowler;
      _endChangeBalls = f.endChangeBalls;
      _xi.clear();
      _keeperId = null;
    });
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
              child: Text('Pick a team to issue the challenge as.'));
        }
        return _OpponentStep(
          query: _opponentSearch,
          selected: _opponent,
          isOpen: _isOpenChallenge,
          fromTeamId: TeamId(fromId),
          onSearch: (q) => setState(() => _opponentSearch = q),
          onPick: (t) => setState(() {
            _opponent = t;
            _isOpenChallenge = false;
          }),
          onPickOpen: () => setState(() {
            _opponent = null;
            _isOpenChallenge = true;
          }),
        );
      case _Step.format:
        return StepFormat(
          selectedPresetId: _presetId,
          onPicked: _applyPreset,
        );
      case _Step.whenWhere:
        return StepWhenWhere(
          selectedDay: _pickedDay,
          selectedTime: _pickedTime,
          venue: _venueCtrl.text,
          onDayPicked: (d) => setState(() => _pickedDay = d),
          onTimePicked: (t) => setState(() => _pickedTime = t),
          onVenueChanged: (v) {
            // Keep the controller and state in sync so back/forward
            // navigation through the wizard never strands the text field.
            if (_venueCtrl.text != v) _venueCtrl.text = v;
            setState(() {});
          },
        );
      case _Step.xi:
        return _PickXiStep(
          fromTeamId: _resolvedFromTeamId,
          playersNeeded: _playersPerSide,
          xi: _xi,
          keeperId: _keeperId,
          onToggle: (id) => setState(() {
            if (_xi.contains(id)) {
              _xi.remove(id);
              if (_keeperId == id) _keeperId = null;
            } else {
              _xi.add(id);
            }
          }),
          onKeeper: (id) => setState(() => _keeperId = id),
          onAutoFill: (roster) {
            setState(() {
              _xi
                ..clear()
                ..addAll(
                  roster.take(_playersPerSide).map((r) => r.member.playerId),
                );
              _keeperId = _pickKeeperId(roster);
            });
          },
          onClear: () => setState(() {
            _xi.clear();
            _keeperId = null;
          }),
        );
      case _Step.review:
        return _ReviewStepHost(
          fromTeam: _fromTeam,
          fromTeamId: _resolvedFromTeamId,
          opponent: _opponent,
          isOpen: _isOpenChallenge,
          startTime: _startTime!,
          venue: _venueCtrl.text.trim(),
          format: MatchFormat(
            oversPerInnings: _overs,
            playersPerTeam: _playersPerSide,
            ballType: _ball,
            maxOversPerBowler: _maxOversPerBowler,
            ballsPerOver: _ballsPerOver,
            inningsPerSide: _inningsPerSide,
            endChangeBalls: _endChangeBalls,
          ),
          presetLabel: _presetLabel ?? 'Custom',
          pickedXiIds: _xi,
          keeperId: _keeperId,
          messageController: _messageCtrl,
          // Rebuild on every keystroke so the "X LEFT" counter + section
          // hint stay in sync as the message grows.
          onMessageChanged: () => setState(() {}),
        );
    }
  }
}

/// Bridges the screen's `_fromTeam` + roster (via `rosterProvider`) into
/// the domain-agnostic [StepReview] view shape. Kept here for the same
/// reason as [_PickXiStep] — the widget stays portable.
class _ReviewStepHost extends ConsumerWidget {
  const _ReviewStepHost({
    required this.fromTeam,
    required this.fromTeamId,
    required this.opponent,
    required this.isOpen,
    required this.startTime,
    required this.venue,
    required this.format,
    required this.presetLabel,
    required this.pickedXiIds,
    required this.keeperId,
    required this.messageController,
    required this.onMessageChanged,
  });

  final Team? fromTeam;
  final String? fromTeamId;
  final Team? opponent;
  final bool isOpen;
  final DateTime startTime;
  final String venue;
  final MatchFormat format;
  final String presetLabel;
  final Set<String> pickedXiIds;
  final String? keeperId;
  final TextEditingController messageController;
  final VoidCallback onMessageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the from-team — when the wizard was deep-linked via
    // `/teams/:teamId/challenge`, `_fromTeam` is null because the team-pick
    // step was skipped; fall back to looking the team up from myTeams.
    final resolvedFromTeam = fromTeam ?? _lookupFromTeam(ref);
    if (resolvedFromTeam == null) {
      return const Center(child: CircularProgressIndicator(color: CkColors.ink));
    }

    // Map the picked roster ids to XiCandidates for the chip strip.
    final picked = fromTeamId == null
        ? const <XiCandidate>[]
        : ref.watch(rosterProvider(fromTeamId!)).maybeWhen(
              data: (roster) => roster
                  .where((r) => pickedXiIds.contains(r.member.playerId))
                  .map(_toCandidate)
                  .toList(growable: false),
              orElse: () => const <XiCandidate>[],
            );

    return StepReview(
      fromTeam: resolvedFromTeam,
      opponent: opponent,
      isOpen: isOpen,
      format: format,
      presetLabel: presetLabel,
      startTime: startTime,
      venue: venue,
      pickedXi: picked,
      keeperId: keeperId,
      messageController: messageController,
      onMessageChanged: onMessageChanged,
    );
  }

  Team? _lookupFromTeam(WidgetRef ref) {
    if (fromTeamId == null) return null;
    final teams = ref.watch(myTeamsProvider).maybeWhen(
          data: (t) => t,
          orElse: () => const <Team>[],
        );
    for (final t in teams) {
      if (t.id.value == fromTeamId) return t;
    }
    return null;
  }

  static XiCandidate _toCandidate(RosterMember r) {
    final role = r.member.role == MemberRole.wicketKeeper
        ? ChPlayingRole.wk
        : ChPlayingRole.bat;
    return XiCandidate(
      id: r.member.playerId,
      name: r.displayName,
      role: role,
      captain: r.member.role == MemberRole.captain,
    );
  }
}

// ─── Pick XI bridge ───────────────────────────────────────────────────────

/// Bridges `rosterProvider` → `StepPickXi`'s [XiCandidate] view shape.
///
/// Lives here (instead of inside `step_pick_xi.dart`) so the widget itself
/// stays domain-agnostic and easy to integrate elsewhere.
class _PickXiStep extends ConsumerWidget {
  const _PickXiStep({
    required this.fromTeamId,
    required this.playersNeeded,
    required this.xi,
    required this.keeperId,
    required this.onToggle,
    required this.onKeeper,
    required this.onAutoFill,
    required this.onClear,
  });

  final String? fromTeamId;
  final int playersNeeded;
  final Set<String> xi;
  final String? keeperId;
  final ValueChanged<String> onToggle;
  final ValueChanged<String?> onKeeper;
  final ValueChanged<List<RosterMember>> onAutoFill;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fromTeamId == null) {
      return const Center(child: Text('Pick a team first.'));
    }
    final async = ref.watch(rosterProvider(fromTeamId!));
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          e.toString(),
          style: CkType.body(fontSize: 12, color: CkColors.muted),
        ),
      ),
      data: (roster) {
        if (roster.length < playersNeeded) {
          return _NotEnoughPlayers(have: roster.length, need: playersNeeded);
        }
        final candidates = roster.map(_toCandidate).toList(growable: false);
        return StepPickXi(
          roster: candidates,
          playersNeeded: playersNeeded,
          xi: xi,
          keeperId: keeperId,
          onToggle: onToggle,
          onKeeper: onKeeper,
          onAutoFill: () => onAutoFill(roster),
          onClear: onClear,
        );
      },
    );
  }

  XiCandidate _toCandidate(RosterMember r) {
    final role = r.member.role == MemberRole.wicketKeeper
        ? ChPlayingRole.wk
        : ChPlayingRole.bat;
    return XiCandidate(
      id: r.member.playerId,
      name: r.displayName,
      role: role,
      captain: r.member.role == MemberRole.captain,
    );
  }
}

class _NotEnoughPlayers extends StatelessWidget {
  const _NotEnoughPlayers({required this.have, required this.need});
  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'NEEDS ${need - have} MORE',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkInk.amber,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough players',
            style: CkType.display(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'This format needs $need a side. Your squad has $have. Go back and pick a smaller format, or add players from your team page.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.ink2,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header / Footer ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onBack});
  final _Step step;
  final VoidCallback onBack;

  String get _title => switch (step) {
        _Step.team => "Who's playing?",
        _Step.opponent => 'Who do you want to play?',
        _Step.format => 'How will we play?',
        _Step.whenWhere => 'When and where?',
        _Step.xi => 'Pick for this match.',
        _Step.review => 'Review & send.',
      };

  @override
  Widget build(BuildContext context) {
    final i = step.index;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
            const SizedBox(width: 4),
            Text(
              'STEP ${i + 1} OF ${_Step.values.length} · CHALLENGE',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: CkColors.muted,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_Step.values.length, (j) {
              final past = j < i;
              final current = j == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: j == _Step.values.length - 1 ? 0 : 4),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: past
                          ? CkColors.green
                          : current
                              ? CkColors.ink
                              : const Color(0x1A14120E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            _title,
            style: CkType.display(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.hint,
  });

  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  /// Optional hint line shown above the primary CTA. Used on the Format
  /// step to explain "Both captains can change format up to 12h before
  /// the toss." per the design.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null) ...[
            Center(
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 11,
                  color: CkColors.muted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          CkButton(
            label: label,
            busy: busy,
            onPressed: enabled ? onPressed : null,
          ),
        ],
      ),
    );
  }
}

// ─── Step 1 · Team (which side of mine sends?) ────────────────────────────

/// Per-row role on the team-pick step. Pulled from the user's relationship
/// to the team (owner/manager/captain via team_members). v1 simplification:
/// users only see teams they own/manage (via `myTeamsProvider`'s filter), so
/// every visible row is treated as CAPTAIN. Vice-captain + manager-disabled
/// rendering paths are kept so we can wire them in when the team-members
/// role surfaces.
enum _MyTeamRole { captain, viceCaptain, manager }

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
    final mineAsync = ref.watch(myTeamsProvider);
    return mineAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(e.toString(), textAlign: TextAlign.center),
        ),
      ),
      data: (mine) {
        if (mine.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(18, 32, 18, 18),
            child: Text(
              'You need to manage a team to issue a challenge. Create or '
              'join one first.',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (mine.length == 1) {
          onSingle(mine.single);
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
                'You captain ${_countLabel(mine.length)}. Issue the challenge '
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
            for (final t in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MyTeamRow(
                  team: t,
                  role: _MyTeamRole.captain,
                  disabledNote: null,
                  selected: selected?.id == t.id,
                  onTap: () => onPick(t),
                ),
              ),
            const SizedBox(height: 6),
            const _InfoCard(
              text:
                  "Manager-only teams can’t initiate challenges. Get the "
                  'captain to send it, or ask them to promote you.',
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
  final _MyTeamRole role;
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
                      style: CkType.body(
                        fontSize: 12,
                        color: CkColors.muted,
                      ),
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
                  child: const Icon(Icons.check, size: 14, color: CkColors.paper),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _secondaryLine(Team t) {
    if (t.city != null && t.city!.isNotEmpty) return t.city!;
    if (t.tagline != null && t.tagline!.isNotEmpty) return t.tagline!;
    if (t.homeGround != null && t.homeGround!.isNotEmpty) return t.homeGround!;
    return 'Tap to issue the challenge';
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final _MyTeamRole role;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (role) {
      _MyTeamRole.captain => ('CAPTAIN', CkColors.red, CkColors.paper),
      _MyTeamRole.viceCaptain =>
        ('VICE-CAPTAIN', CkColors.cream, CkColors.ink2),
      _MyTeamRole.manager => ('MANAGER', CkColors.paper2, CkColors.ink2),
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

class _OpponentStep extends ConsumerWidget {
  const _OpponentStep({
    required this.query,
    required this.selected,
    required this.isOpen,
    required this.fromTeamId,
    required this.onSearch,
    required this.onPick,
    required this.onPickOpen,
  });

  final String query;
  final Team? selected;
  final bool isOpen;
  final TeamId fromTeamId;
  final ValueChanged<String> onSearch;
  final ValueChanged<Team> onPick;
  final VoidCallback onPickOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTeamsProvider);
    return allAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (teams) {
        final q = query.trim().toLowerCase();
        final visible = teams
            .where((t) => t.id != fromTeamId)
            .where((t) =>
                q.isEmpty || t.name.toLowerCase().contains(q))
            .toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            // Option 1: Broadcast as Open Pool Challenge with Share Code
            InkWell(
              onTap: onPickOpen,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOpen ? CkColors.paper2 : CkColors.paper,
                  border: Border.all(
                    color: isOpen ? CkColors.ink : CkColors.hairline,
                    width: isOpen ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isOpen ? CkColors.ink : CkColors.paper2,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Icon(
                        Icons.public,
                        size: 22,
                        color: isOpen ? CkColors.paper : CkColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Open Challenge',
                                style: CkType.display(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Pill(label: 'BROADCAST', tone: PillTone.green),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Post to match pool & generate 6-digit share code',
                            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (isOpen)
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: CkColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: CkColors.paper),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(color: CkColors.hairline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR DIRECT 1-ON-1 CHALLENGE',
                    style: CkType.mono(fontSize: 9.5, fontWeight: FontWeight.w700, color: CkColors.muted),
                  ),
                ),
                const Expanded(child: Divider(color: CkColors.hairline)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search specific opponent team',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CkColors.hairline),
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
            const SizedBox(height: 12),
            for (final t in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TeamRow(
                  team: t,
                  selected: selected?.id == t.id && !isOpen,
                  onTap: () => onPick(t),
                ),
              ),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No teams match your search.',
                    textAlign: TextAlign.center),
              ),
          ],
        );
      },
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
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _teamColor(team.primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_short(team),
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(team.name,
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                    )),
                if (team.city != null)
                  Text(team.city!,
                      style: CkType.body(
                        fontSize: 12,
                        color: CkColors.muted,
                      )),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check, size: 18, color: CkColors.ink),
        ]),
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
      child: Text(label.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: CkColors.muted,
          )),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

String _short(Team t) {
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters = t.name
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

