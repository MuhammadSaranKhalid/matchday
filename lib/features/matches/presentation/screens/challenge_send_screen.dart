import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';

/// Sender side of the challenge handshake. 5 steps on one screen, matching
/// the Challenge Flow v3 design:
/// 1. Team — which of your teams is issuing (auto-skipped when you manage 1)
/// 2. Opponent — pick the team you're challenging
/// 3. Format — match type, ball, overs per side, per-bowler max (slider)
/// 4. When & Where — date chips + time grid + venue (with map preview)
/// 5. Review + optional message → send
///
/// v1 ships Friendly only — League / Cup-tie tiles render disabled and the
/// Stakes step is omitted entirely per the locked scope. Entry is the
/// `+ Challenge` button on My Matches → `/challenge` (no preselected team)
/// or `/teams/:teamId/challenge` for a deep link.
class ChallengeSendScreen extends ConsumerStatefulWidget {
  const ChallengeSendScreen({super.key, this.fromTeamId});

  /// Optional preselected team. When null the screen renders the team-pick
  /// step first; when set it skips straight to the opponent picker.
  final String? fromTeamId;

  @override
  ConsumerState<ChallengeSendScreen> createState() =>
      _ChallengeSendScreenState();
}

enum _Step { team, opponent, format, whenWhere, review }

class _ChallengeSendScreenState extends ConsumerState<ChallengeSendScreen> {
  late _Step _step;
  bool _busy = false;

  // Form data — sane defaults so a captain in a rush can hit Continue × 3.
  Team? _fromTeam;
  Team? _opponent;
  String _opponentSearch = '';
  int _overs = 20;
  int _playersPerSide = 11;
  MatchBallType _ball = MatchBallType.tape;
  int _maxOversPerBowler = 4;
  int _ballsPerOver = 6;
  int _inningsPerSide = 1;
  int? _endChangeBalls;
  DateTime? _startTime;
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

  bool get _canContinue {
    switch (_step) {
      case _Step.team:
        return _fromTeam != null;
      case _Step.opponent:
        return _opponent != null;
      case _Step.format:
        return _overs > 0 && _playersPerSide >= 5 && _playersPerSide <= 15;
      case _Step.whenWhere:
        return _startTime != null &&
            _startTime!.isAfter(DateTime.now()) &&
            _venueCtrl.text.trim().isNotEmpty;
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
    if (_step == _Step.review) return 'Send challenge';
    if (_step == _Step.team && _fromTeam != null) {
      return 'Continue as ${_fromTeam!.name} →';
    }
    if (_step == _Step.format) {
      return 'Continue · T$_overs ${_ballShort(_ball)} →';
    }
    if (_step == _Step.whenWhere && _startTime != null) {
      final venue = _venueCtrl.text.trim();
      final whenLabel = _whenShort(_startTime!);
      if (venue.isEmpty) return 'Continue · $whenLabel →';
      return 'Continue · $whenLabel · ${_venueShort(venue)} →';
    }
    return 'Continue →';
  }

  String _ballShort(MatchBallType b) {
    switch (b) {
      case MatchBallType.leather:
        return 'hardball';
      case MatchBallType.tape:
        return 'tape';
      case MatchBallType.tennis:
        return 'tennis';
    }
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
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  Future<void> _send() async {
    final opp = _opponent;
    final start = _startTime;
    final fromId = _resolvedFromTeamId;
    if (opp == null || start == null || fromId == null) return;
    setState(() => _busy = true);
    final result = await ref.read(matchesRepositoryProvider).sendMatchChallenge(
          fromTeamId: TeamId(fromId),
          toTeamId: opp.id,
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

  /// Apply a format preset — fills every knob from the chosen format
  /// (see CRICKET_FORMATS.md). The detailed controls below stay editable.
  void _applyPreset(_FormatPreset p) {
    setState(() {
      _overs = p.overs;
      _playersPerSide = p.players;
      _ballsPerOver = p.ballsPerOver;
      _inningsPerSide = p.inningsPerSide;
      _maxOversPerBowler = p.maxOversPerBowler;
      _endChangeBalls = p.endChangeBalls;
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
          fromTeamId: TeamId(fromId),
          onSearch: (q) => setState(() => _opponentSearch = q),
          onPick: (t) => setState(() => _opponent = t),
        );
      case _Step.format:
        return _FormatStep(
          overs: _overs,
          playersPerSide: _playersPerSide,
          ball: _ball,
          maxOversPerBowler: _maxOversPerBowler,
          ballsPerOver: _ballsPerOver,
          inningsPerSide: _inningsPerSide,
          onPreset: _applyPreset,
          onChange: ({overs, players, ball, maxOversPerBowler}) {
            setState(() {
              if (overs != null) _overs = overs;
              if (players != null) _playersPerSide = players;
              if (ball != null) _ball = ball;
              if (maxOversPerBowler != null) {
                _maxOversPerBowler = maxOversPerBowler;
              }
            });
          },
        );
      case _Step.whenWhere:
        return _WhenWhereStep(
          startTime: _startTime,
          onPickTime: (t) => setState(() => _startTime = t),
          venueController: _venueCtrl,
          onVenueChanged: () => setState(() {}),
        );
      case _Step.review:
        return _ReviewStep(
          opponent: _opponent!,
          startTime: _startTime!,
          venue: _venueCtrl.text.trim(),
          format: MatchFormat(
            oversPerInnings: _overs,
            playersPerTeam: _playersPerSide,
            ballType: _ball,
            maxOversPerBowler: _maxOversPerBowler,
          ),
          messageCtrl: _messageCtrl,
        );
    }
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
        _Step.review => 'One last look.',
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
            TextField(
              decoration: InputDecoration(
                hintText: 'Search teams',
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
                  selected: selected?.id == t.id,
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

// ─── Step 2 · Format ──────────────────────────────────────────────────────

class _FormatStep extends StatelessWidget {
  const _FormatStep({
    required this.overs,
    required this.playersPerSide,
    required this.ball,
    required this.maxOversPerBowler,
    required this.ballsPerOver,
    required this.inningsPerSide,
    required this.onPreset,
    required this.onChange,
  });

  final int overs;
  final int playersPerSide;
  final MatchBallType ball;
  final int maxOversPerBowler;
  final int ballsPerOver;
  final int inningsPerSide;
  final void Function(_FormatPreset) onPreset;
  final void Function({
    int? overs,
    int? players,
    MatchBallType? ball,
    int? maxOversPerBowler,
  }) onChange;

  static const _overOptions = <({int v, String l, String sub})>[
    (v: 5, l: 'T5', sub: 'street'),
    (v: 10, l: 'T10', sub: 'fast'),
    (v: 15, l: '15 ov', sub: ''),
    (v: 20, l: 'T20', sub: 'standard'),
    (v: 25, l: '25 ov', sub: ''),
    (v: 50, l: 'ODI', sub: '50 ov'),
  ];

  /// Which preset (if any) the current knob values match, for highlighting.
  _FormatPreset? get _active {
    for (final p in _FormatPreset.values) {
      if (p.overs == overs &&
          p.players == playersPerSide &&
          p.ballsPerOver == ballsPerOver &&
          p.inningsPerSide == inningsPerSide &&
          p.maxOversPerBowler == maxOversPerBowler) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      children: [
        const _SectionLabel('Format'),
        _PresetRow(current: _active, onPick: onPreset),
        const SizedBox(height: 14),
        const _SectionLabel('Match type'),
        const _MatchTypeGrid(),
        const SizedBox(height: 14),
        const _SectionLabel('Ball'),
        Row(
          children: [
            for (var i = 0; i < MatchBallType.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _BallPill(
                  label: _ballLabel(MatchBallType.values[i]),
                  selected: ball == MatchBallType.values[i],
                  onTap: () => onChange(ball: MatchBallType.values[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Overs per side'),
        _OversGrid(
          options: _overOptions,
          selected: overs,
          onTap: (v) => onChange(overs: v),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Players a side'),
        _PlayersStepper(
          value: playersPerSide,
          onChanged: (v) => onChange(players: v),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Per bowler · max'),
        _MaxOversSlider(
          value: maxOversPerBowler,
          totalOvers: overs,
          onChanged: (v) => onChange(maxOversPerBowler: v),
        ),
      ],
    );
  }

  String _ballLabel(MatchBallType b) {
    switch (b) {
      case MatchBallType.leather:
        return 'Hardball';
      case MatchBallType.tape:
        return 'Tape ball';
      case MatchBallType.tennis:
        return 'Tennis';
    }
  }
}

// ─── Format presets ───────────────────────────────────────────────────────

/// Format presets — each fills every knob from CRICKET_FORMATS.md. The Hundred
/// is modelled as 20 five-ball "overs" (= 100 balls); Test is unlimited overs
/// across two innings. No preset highlighted = a custom knob combination.
enum _FormatPreset {
  t10('T10', 10, 11, 6, 1, 2, null),
  t20('T20', 20, 11, 6, 1, 4, null),
  odi('ODI', 50, 11, 6, 1, 10, null),
  hundred('The Hundred', 20, 11, 5, 1, 4, 10),
  sixes('Sixes', 5, 6, 5, 1, 1, null),
  eightAside('8-a-side', 20, 8, 6, 1, 4, null),
  test('Test', 0, 11, 6, 2, 0, null);

  const _FormatPreset(
    this.label,
    this.overs,
    this.players,
    this.ballsPerOver,
    this.inningsPerSide,
    this.maxOversPerBowler,
    this.endChangeBalls,
  );
  final String label;
  final int overs;
  final int players;
  final int ballsPerOver;
  final int inningsPerSide;
  final int maxOversPerBowler;
  final int? endChangeBalls;
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.current, required this.onPick});
  final _FormatPreset? current;
  final void Function(_FormatPreset) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in _FormatPreset.values)
          _PresetChip(
            label: p.label,
            selected: p == current,
            onTap: () => onPick(p),
          ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? CkColors.ink : CkColors.line),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _PlayersStepper extends StatelessWidget {
  const _PlayersStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepBtn(
            icon: Icons.remove,
            onTap: value > 5 ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value a side',
            style: CkType.body(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: value < 15 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: CkColors.ink,
      disabledColor: CkColors.soft,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// 3-column Match Type tile grid. v1: Friendly enabled (selected); League +
/// Cup tie shown but disabled (no backend support) — they render at 0.4
/// opacity with the same shape as Friendly so the visual hierarchy matches
/// the design.
class _MatchTypeGrid extends StatelessWidget {
  const _MatchTypeGrid();

  static const _tiles = <({String id, String label, String sub, bool enabled})>[
    (id: 'friendly', label: 'Friendly', sub: 'No ladder', enabled: true),
    (id: 'league', label: 'League', sub: 'Counts for points', enabled: false),
    (id: 'tour', label: 'Cup tie', sub: 'In a bracket', enabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _MatchTypeTile(
              label: _tiles[i].label,
              sub: _tiles[i].sub,
              selected: _tiles[i].id == 'friendly',
              enabled: _tiles[i].enabled,
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchTypeTile extends StatelessWidget {
  const _MatchTypeTile({
    required this.label,
    required this.sub,
    required this.selected,
    required this.enabled,
  });
  final String label;
  final String sub;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                )),
            const SizedBox(height: 2),
            Text(sub,
                style: CkType.body(fontSize: 10.5, color: CkColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Full-width ink-or-paper pill (radius 999, design's Ball row spec).
class _BallPill extends StatelessWidget {
  const _BallPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.paper : CkColors.ink,
            )),
      ),
    );
  }
}

/// 3-column Overs grid with big primary label (Inter Tight 17) + muted
/// sub-label (10px) — "T20 · standard", "T5 · street" etc.
class _OversGrid extends StatelessWidget {
  const _OversGrid({
    required this.options,
    required this.selected,
    required this.onTap,
  });
  final List<({int v, String l, String sub})> options;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <List<({int v, String l, String sub})>>[];
    for (var i = 0; i < options.length; i += 3) {
      rows.add(options.sublist(i, (i + 3).clamp(0, options.length)));
    }
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: i < rows[r].length
                      ? _OversTile(
                          option: rows[r][i],
                          selected: rows[r][i].v == selected,
                          onTap: () => onTap(rows[r][i].v),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _OversTile extends StatelessWidget {
  const _OversTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final ({int v, String l, String sub}) option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.l,
                style: CkType.display(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                )),
            if (option.sub.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(option.sub,
                    style:
                        CkType.body(fontSize: 10, color: CkColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-bowler max-overs slider widget (paper2 card with big number left,
/// slider middle, mono "overs" right). The design shows a horizontal slider
/// from 1..total/3 with the current value rendered as a big numeric.
class _MaxOversSlider extends StatelessWidget {
  const _MaxOversSlider({
    required this.value,
    required this.totalOvers,
    required this.onChanged,
  });
  final int value;
  final int totalOvers;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Cap by 1/3 of the innings overs (real cricket rule for limited overs),
    // and clamp the value into [1, max] so the slider can't get stuck.
    final maxOvers = (totalOvers ~/ 3).clamp(1, totalOvers).toInt();
    final v = value.clamp(1, maxOvers).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: CkColors.ink,
                inactiveTrackColor: CkColors.hairline,
                thumbColor: CkColors.paper,
                overlayColor: CkColors.ink.withValues(alpha: 0.08),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: v,
                min: 1,
                max: maxOvers.toDouble(),
                divisions: maxOvers - 1 == 0 ? 1 : maxOvers - 1,
                onChanged: (d) => onChanged(d.round()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('overs',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: CkColors.muted,
              )),
        ],
      ),
    );
  }
}

// ─── Step 4 · When & Where (combined) ─────────────────────────────────────

class _WhenWhereStep extends StatelessWidget {
  const _WhenWhereStep({
    required this.startTime,
    required this.onPickTime,
    required this.venueController,
    required this.onVenueChanged,
  });

  final DateTime? startTime;
  final ValueChanged<DateTime> onPickTime;
  final TextEditingController venueController;
  final VoidCallback onVenueChanged;

  static const _timeSlots = <_TimeSlot>[
    _TimeSlot(7, 0),
    _TimeSlot(9, 30),
    _TimeSlot(15, 0),
    _TimeSlot(17, 0),
    _TimeSlot(18, 30),
    _TimeSlot(19, 30),
    _TimeSlot(20, 30),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickedDay = startTime == null
        ? null
        : DateTime(startTime!.year, startTime!.month, startTime!.day);
    final pickedSlot = startTime == null
        ? null
        : _TimeSlot(startTime!.hour, startTime!.minute);
    final days = List.generate(5, (i) => today.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      children: [
        const _SectionLabel('Date'),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length + 1, // last item is "Pick…"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == days.length) {
                return _DateChip(
                  primary: 'Pick…',
                  secondary: 'Custom',
                  disabled: false,
                  selected: false,
                  onTap: () async {
                    final last = days.last;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: last.add(const Duration(days: 1)),
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 90)),
                    );
                    if (picked == null) return;
                    final slot = pickedSlot ?? const _TimeSlot(18, 30);
                    onPickTime(DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      slot.h,
                      slot.m,
                    ));
                  },
                );
              }
              final d = days[i];
              final isToday = i == 0;
              final isTomorrow = i == 1;
              final picked = pickedDay == d;
              return _DateChip(
                primary: isToday
                    ? 'Today'
                    : isTomorrow
                        ? 'Tomorrow'
                        : _dow(d),
                secondary: isToday || isTomorrow
                    ? '${_dow(d)} ${d.day}'
                    : '${d.day}',
                // Per design: today is opt-in (disabled by default for
                // same-day) — but we keep it tappable since users may want
                // to challenge today.
                disabled: false,
                selected: picked,
                onTap: () {
                  final slot = pickedSlot ?? const _TimeSlot(18, 30);
                  onPickTime(DateTime(d.year, d.month, d.day, slot.h, slot.m));
                },
              );
            },
          ),
        ),
        const _SectionLabel('Time'),
        _TimeGrid(
          slots: _timeSlots,
          selected: pickedSlot,
          onPick: (s) {
            final d = pickedDay ?? today.add(const Duration(days: 2));
            onPickTime(DateTime(d.year, d.month, d.day, s.h, s.m));
          },
          onOther: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 18, minute: 30),
            );
            if (time == null) return;
            final d = pickedDay ?? today.add(const Duration(days: 2));
            onPickTime(DateTime(d.year, d.month, d.day, time.hour, time.minute));
          },
        ),
        const _SectionLabel('Venue'),
        _MapPreview(label: venueController.text.trim()),
        const SizedBox(height: 8),
        TextField(
          controller: venueController,
          decoration: InputDecoration(
            hintText: 'e.g. Model Town · Pitch 2',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            isDense: true,
          ),
          onChanged: (_) => onVenueChanged(),
        ),
        const SizedBox(height: 6),
        Text(
          'Free-text for now — type the ground exactly as you’d send on '
          'WhatsApp.',
          style: CkType.body(
            fontSize: 11,
            color: CkColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.primary,
    required this.secondary,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });
  final String primary;
  final String secondary;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.hairline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(primary,
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  )),
              const SizedBox(height: 2),
              Text(secondary,
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({
    required this.slots,
    required this.selected,
    required this.onPick,
    required this.onOther,
  });

  final List<_TimeSlot> slots;
  final _TimeSlot? selected;
  final ValueChanged<_TimeSlot> onPick;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final s in slots)
        _TimePill(
          label: s.toString(),
          selected: selected == s,
          onTap: () => onPick(s),
        ),
      _TimePill(label: 'Other', selected: false, onTap: onOther),
    ];
    // 4-column grid.
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 4) {
      final slice = items.sublist(i, (i + 4).clamp(0, items.length));
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
        child: Row(
          children: [
            for (var j = 0; j < 4; j++) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(
                child: j < slice.length ? slice[j] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: selected ? CkColors.paper : CkColors.ink,
            )),
      ),
    );
  }
}

/// Decorative SVG-ish map preview (gridded paper2 box + path lines + an
/// ink pin with halo + a floating chip showing the picked venue + distance).
/// Pure visual flavour — venue selection happens in the text field below.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CkColors.paper,
                border: Border.all(color: CkColors.hairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label.isEmpty ? 'Pick or type your venue' : label,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: label.isEmpty ? CkColors.muted : CkColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 20px grid.
    final grid = Paint()
      ..color = CkColors.hairline
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Two meandering paths.
    final road = Paint()
      ..color = CkColors.muted.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final p1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.45,
        size.width * 0.5, size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.8,
        size.width, size.height * 0.45,
      );
    canvas.drawPath(p1, road);
    final road2 = Paint()
      ..color = CkColors.muted.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final p2 = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.3, size.height * 0.65,
        size.width * 0.6, size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.95,
        size.width, size.height * 0.75,
      );
    canvas.drawPath(p2, road2);
    // Pin with halo.
    final pin = Offset(size.width * 0.4, size.height * 0.5);
    canvas.drawCircle(
      pin,
      11,
      Paint()
        ..color = CkColors.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(pin, 5, Paint()..color = CkColors.ink);
    // Two muted dots for context.
    final dot = Paint()..color = CkColors.muted;
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.7), 3, dot);
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.3), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimeSlot {
  const _TimeSlot(this.h, this.m);
  final int h;
  final int m;

  @override
  bool operator ==(Object other) =>
      other is _TimeSlot && other.h == h && other.m == m;
  @override
  int get hashCode => Object.hash(h, m);
  @override
  String toString() =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// ─── Step 5 · Review ──────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.opponent,
    required this.startTime,
    required this.venue,
    required this.format,
    required this.messageCtrl,
  });

  final Team opponent;
  final DateTime startTime;
  final String venue;
  final MatchFormat format;
  final TextEditingController messageCtrl;

  @override
  Widget build(BuildContext context) {
    Widget row(String key, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Text(key.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border.all(color: CkColors.hairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              row('Opponent', opponent.name),
              row('Format',
                  'T${format.oversPerInnings} · ${format.playersPerTeam}/side · '
                      '${_ballName(format.ballType)} · '
                      '${format.maxOversPerBowler} ov/bowler'),
              row('When', _human(startTime)),
              row('Venue', venue),
              row('Type', 'Friendly'),
              row('Stakes', 'No pot'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Optional message'),
        TextField(
          controller: messageCtrl,
          maxLength: 280,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(280)],
          decoration: InputDecoration(
            hintText: 'Last time was close — bring your A team. Snacks on us.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Expires 48h after sending if there’s no reply.',
          textAlign: TextAlign.center,
          style: CkType.body(fontSize: 11, color: CkColors.muted),
        ),
      ],
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

String _dow(DateTime t) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];

String _ballName(MatchBallType b) {
  switch (b) {
    case MatchBallType.leather:
      return 'Hardball';
    case MatchBallType.tape:
      return 'Tape ball';
    case MatchBallType.tennis:
      return 'Tennis';
  }
}

String _human(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${_dow(t)} ${t.day} · $hh:$mm';
}
