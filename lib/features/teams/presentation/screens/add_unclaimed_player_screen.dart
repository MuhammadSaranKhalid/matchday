import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../controllers/add_unclaimed_player_controller.dart';
import '../providers/teams_providers.dart';
import '../state/add_unclaimed_player_state.dart';

/// "Add as unclaimed player" — a 2-step wizard (Name → Details → Success).
/// Faithful Flutter port of Flow B from the design bundle's
/// `Add Players Flow.html` — happy path plus the two inline edges:
///
///   * b-dupe         — name already on the squad blocks Continue
///   * b-step2-clash  — jersey number already in active use shows inline error
///
/// Flow A (search registered players), b-match, and b-soft-cap are out of
/// scope for this slice.
class AddUnclaimedPlayerScreen extends ConsumerStatefulWidget {
  const AddUnclaimedPlayerScreen({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<AddUnclaimedPlayerScreen> createState() =>
      _AddUnclaimedPlayerScreenState();
}

class _AddUnclaimedPlayerScreenState
    extends ConsumerState<AddUnclaimedPlayerScreen> {
  late final TextEditingController _name;
  late final TextEditingController _jersey;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _jersey = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _jersey.dispose();
    super.dispose();
  }

  void _syncControllers(AddUnclaimedPlayerState s) {
    // Keep TextEditingControllers in sync after `Add another` resets state.
    if (_name.text != s.name) {
      _name.value = TextEditingValue(
        text: s.name,
        selection: TextSelection.collapsed(offset: s.name.length),
      );
    }
    if (_jersey.text != s.jersey) {
      _jersey.value = TextEditingValue(
        text: s.jersey,
        selection: TextSelection.collapsed(offset: s.jersey.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = widget.teamId;
    final state = ref.watch(addUnclaimedPlayerControllerProvider(teamId));
    final controller =
        ref.watch(addUnclaimedPlayerControllerProvider(teamId).notifier);

    _syncControllers(state);

    ref.listen<AddUnclaimedPlayerState>(
      addUnclaimedPlayerControllerProvider(teamId),
      (prev, next) {
        final err = next.submitError;
        if (err != null && prev?.submitError != err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      },
    );

    final rosterAsync = ref.watch(rosterProvider(teamId));
    final teamAsync = ref.watch(teamProvider(teamId));

    final roster = rosterAsync.value ?? const <RosterMember>[];
    final team = teamAsync.value;

    // Existing names (case-insensitive) for the dupe check, and the
    // jersey → owner map for the clash error message.
    final existingNames = <String, RosterMember>{};
    final jerseyOwners = <int, String>{};
    for (final r in roster) {
      existingNames[r.displayName.trim().toLowerCase()] = r;
      final j = r.member.jerseyNumber;
      if (j != null) jerseyOwners[j] = r.displayName;
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (state.step) {
          AddUnclaimedPlayerStep.name => _StepName(
              state: state,
              controller: controller,
              nameController: _name,
              existingNames: existingNames,
            ),
          AddUnclaimedPlayerStep.details => _StepDetails(
              state: state,
              controller: controller,
              jerseyController: _jersey,
              jerseyOwners: jerseyOwners,
            ),
          AddUnclaimedPlayerStep.success => _SuccessView(
              state: state,
              team: team,
              onAddAnother: () {
                controller.resetForAnother();
                _name.clear();
                _jersey.clear();
              },
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome
// ─────────────────────────────────────────────────────────────────────────────

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title, required this.sub, this.onBack});

  final String title;
  final String sub;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      decoration: const Border(
              bottom: BorderSide(color: CkColors.hairline, width: 1))
          .toBoxDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.chevron_left, size: 22, color: CkColors.ink),
              padding: EdgeInsets.zero,
              splashRadius: 22,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1.1,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// Tiny extension so the Border above can render via BoxDecoration.
extension on Border {
  BoxDecoration toBoxDecoration() => BoxDecoration(border: this);
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});
  final int step;
  static const _total = 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: List.generate(_total, (i) {
          final filled = i < step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == _total - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: filled ? CkColors.ink : CkColors.paper2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.flex = 2,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: disabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: CkColors.ink,
            foregroundColor: CkColors.paper,
            disabledBackgroundColor: CkColors.paper2,
            disabledForegroundColor: CkColors.muted,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: CkType.body(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: CkColors.paper,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: CkColors.paper,
            foregroundColor: CkColors.ink,
            side: const BorderSide(color: CkColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
            textStyle: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.child,
    this.optional = false,
    this.hint,
    this.errorText,
  });

  final String label;
  final Widget child;
  final bool optional;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                  children: [
                    TextSpan(text: label.toUpperCase()),
                    if (optional)
                      const TextSpan(
                        text: ' · OPTIONAL',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ),
            if (hint != null && !hasError)
              Text(
                hint!,
                style: CkType.mono(fontSize: 11, color: CkColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? CkColors.red : CkColors.hairline,
              width: 1,
            ),
          ),
          child: child,
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: CkColors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: CkType.body(
                    fontSize: 11.5,
                    color: CkColors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.state});
  final AddUnclaimedPlayerState state;

  @override
  Widget build(BuildContext context) {
    final j = state.jersey.trim();
    final crestLabel = j.isEmpty ? '?' : '#$j';
    final meta = _composeMeta(state);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          _DashedCrest(label: crestLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.name.trim().isEmpty
                            ? 'New player'
                            : state.name.trim(),
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.02,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _UnclaimedPill(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: CkType.mono(
                    fontSize: 11,
                    color: CkColors.muted,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _composeMeta(AddUnclaimedPlayerState s) {
    final role = s.playingRole?.label ?? 'Role TBD';
    final parts = <String>[role];
    if (s.battingStyle != null) parts.add(s.battingStyle!.label);
    if (s.bowlingStyle != null) parts.add(s.bowlingStyle!.label);
    return parts.join(' · ');
  }
}

class _DashedCrest extends StatelessWidget {
  const _DashedCrest({required this.label, this.size = 36});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _DashedRectPainter(),
        child: Center(
          child: Text(
            label,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02,
              color: CkColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = (dist + dashWidth).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(dist, next), Offset.zero);
        dist = next + dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UnclaimedPill extends StatelessWidget {
  const _UnclaimedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Text(
        'UNCLAIMED',
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Name
// ─────────────────────────────────────────────────────────────────────────────

class _StepName extends StatelessWidget {
  const _StepName({
    required this.state,
    required this.controller,
    required this.nameController,
    required this.existingNames,
  });

  final AddUnclaimedPlayerState state;
  final AddUnclaimedPlayerController controller;
  final TextEditingController nameController;
  final Map<String, RosterMember> existingNames;

  RosterMember? get _duplicate {
    final key = state.name.trim().toLowerCase();
    if (key.isEmpty) return null;
    return existingNames[key];
  }

  @override
  Widget build(BuildContext context) {
    final dupe = _duplicate;
    final isBlocked = dupe != null;
    final canContinue = state.name.trim().isNotEmpty && !isBlocked;

    return Column(
      children: [
        const _FlowHeader(
          title: 'Add unclaimed player',
          sub: 'Step 1 of 2 · Name',
        ),
        const _Stepper(step: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _FieldShell(
                label: 'Player name',
                errorText: dupe != null
                    ? 'Already in your squad — placeholder${dupe.member.jerseyNumber != null ? ' · #${dupe.member.jerseyNumber}' : ''}'
                    : null,
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setName,
                  onSubmitted: (_) {
                    if (canContinue) controller.next();
                  },
                  style: CkType.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.01,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: 'e.g. Saif Khan',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 16,
                      color: CkColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              if (dupe != null) ...[
                const SizedBox(height: 12),
                _ExistingPlayerCard(member: dupe),
              ] else ...[
                const SizedBox(height: 14),
                const _ExplainerCard(),
              ],
            ],
          ),
        ),
        _StickyFooter(
          children: [
            _GhostBtn(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            _PrimaryBtn(
              label: 'Continue',
              onPressed: canContinue ? controller.next : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: CkColors.amber.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: CkType.body(
                  fontSize: 12,
                  color: CkColors.ink2,
                  height: 1.45,
                ),
                children: const [
                  TextSpan(
                    text: 'Unclaimed players',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  TextSpan(
                    text:
                        " hold a roster spot with stats but no profile. Anyone with the name + your team's invite code can claim later.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingPlayerCard extends StatelessWidget {
  const _ExistingPlayerCard({required this.member});
  final RosterMember member;

  @override
  Widget build(BuildContext context) {
    final j = member.member.jerseyNumber;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALREADY IN SQUAD',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DashedCrest(label: j != null ? '#$j' : '?'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.member.playerType == PlayerType.unclaimed
                          ? 'Player · unclaimed'
                          : 'Player',
                      style: CkType.mono(fontSize: 11, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Details
// ─────────────────────────────────────────────────────────────────────────────

class _StepDetails extends StatelessWidget {
  const _StepDetails({
    required this.state,
    required this.controller,
    required this.jerseyController,
    required this.jerseyOwners,
  });

  final AddUnclaimedPlayerState state;
  final AddUnclaimedPlayerController controller;
  final TextEditingController jerseyController;
  final Map<int, String> jerseyOwners;

  String? _jerseyErrorText() {
    final n = state.jerseyNumber;
    if (n == null) return null;
    final owner = jerseyOwners[n];
    if (owner == null) return null;
    final free = _suggestFreeNumbers();
    final freeText = free.isEmpty ? '' : ' Try ${free.join(', ')}.';
    return '#$n taken by $owner.$freeText';
  }

  List<int> _suggestFreeNumbers() {
    final taken = jerseyOwners.keys.toSet();
    final candidates = <int>[];
    // Walk 1..99 and surface the three lowest unused.
    for (var i = 1; i <= 99 && candidates.length < 3; i++) {
      if (!taken.contains(i)) candidates.add(i);
    }
    return candidates;
  }

  @override
  Widget build(BuildContext context) {
    final jerseyError = _jerseyErrorText();
    final canSubmit = !state.submitting && jerseyError == null;

    return Column(
      children: [
        _FlowHeader(
          title: 'Details for ${state.name.trim()}',
          sub: 'Step 2 of 2 · All optional',
          onBack: controller.back,
        ),
        const _Stepper(step: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _FieldShell(
                      label: 'Jersey #',
                      optional: true,
                      hint: jerseyError == null ? '0–99' : null,
                      errorText: jerseyError,
                      child: TextField(
                        controller: jerseyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        onChanged: controller.setJersey,
                        style: CkType.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: CkColors.ink,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          hintText: '—',
                          hintStyle: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 16,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _SelectField<PlayingRole>(
                      label: 'Role',
                      placeholder: 'Pick role',
                      value: state.playingRole,
                      options: PlayingRole.values,
                      labelFor: (r) => r.label,
                      onChanged: controller.setPlayingRole,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SelectField<BattingStyle>(
                label: 'Batting',
                placeholder: 'RHB / LHB',
                value: state.battingStyle,
                options: BattingStyle.values,
                labelFor: (b) => b.label,
                onChanged: controller.setBattingStyle,
              ),
              const SizedBox(height: 14),
              _SelectField<BowlingStyle>(
                label: 'Bowling',
                placeholder: 'RFM / SLA / OS / —',
                value: state.bowlingStyle,
                options: BowlingStyle.values,
                labelFor: (b) => b.label,
                onChanged: controller.setBowlingStyle,
              ),
              const SizedBox(height: 18),
              Text(
                "PREVIEW · HOW THEY'LL SHOW IN THE SQUAD",
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _PreviewRow(state: state),
              if (state.hasDetails) ...[
                const SizedBox(height: 12),
                _AmberNotice(name: state.name.trim()),
              ],
            ],
          ),
        ),
        _StickyFooter(
          children: [
            _GhostBtn(label: 'Back', onPressed: controller.back),
            _PrimaryBtn(
              label: 'Add to squad',
              busy: state.submitting,
              onPressed: canSubmit ? controller.submit : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _AmberNotice extends StatelessWidget {
  const _AmberNotice({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: CkColors.amber,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.priority_high_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'When ${name.isEmpty ? 'this player' : name} joins MatchDay and '
              'claims this spot, your details are locked in until they edit them.',
              style: CkType.body(
                fontSize: 12,
                color: const Color(0xFF6A4D1A), // amber-ink, matches design
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final String placeholder;
  final T? value;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T?>(
      context: context,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                decoration: BoxDecoration(
                  color: CkColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ),
              // Options scroll if the enum is long (e.g. Bowling has 7 + Clear,
              // which can exceed the sheet's half-screen default on small
              // phones).
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final o in options)
                        ListTile(
                          title: Text(
                            labelFor(o),
                            style: CkType.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: o == value
                              ? const Icon(Icons.check,
                                  color: CkColors.ink, size: 18)
                              : null,
                          onTap: () => Navigator.of(sheetCtx).pop(o),
                        ),
                      if (value != null)
                        ListTile(
                          title: Text(
                            'Clear',
                            style: CkType.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CkColors.muted,
                            ),
                          ),
                          onTap: () => Navigator.of(sheetCtx).pop(null),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // `null` from the sheet means: the sheet was dismissed by tapping outside
    // OR the user picked Clear. Disambiguate by distinguishing the two cases
    // — but here we treat both as no-op-or-clear via the Clear tile only, so
    // a swipe-dismiss leaves the value as-is.
    if (picked != null || value != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return _FieldShell(
      label: label,
      optional: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  v == null ? placeholder : labelFor(v),
                  style: v == null
                      ? CkType.body(
                          fontSize: 16,
                          color: CkColors.muted,
                          fontWeight: FontWeight.w500,
                        ).copyWith(fontStyle: FontStyle.italic)
                      : CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.01,
                        ),
                ),
              ),
              const Icon(Icons.expand_more, color: CkColors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.state,
    required this.team,
    required this.onAddAnother,
  });

  final AddUnclaimedPlayerState state;
  final Team? team;
  final VoidCallback onAddAnother;

  String get _inviteCode {
    final t = team;
    if (t == null) return 'MATCHDAY-${DateTime.now().year}';
    final mono = t.logoMonogram;
    final stem = (mono != null && mono.trim().length >= 3)
        ? mono.trim()
        : _firstWord(t.name);
    return '${stem.toUpperCase()}-${DateTime.now().year}';
  }

  static String _firstWord(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'TEAM';
    final first = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return first.isEmpty ? 'TEAM' : first;
  }

  @override
  Widget build(BuildContext context) {
    final name = state.name.trim();
    final teamName = team?.name ?? 'your team';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 60, 26, 16),
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: CkColors.ink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: CkColors.paper,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Added to squad.',
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.03,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${name.isEmpty ? 'They' : name} now hold a spot. They'll "
                'appear in the playing XI picker like any other player.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 13.5,
                  color: CkColors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              _ReceiptRow(state: state),
              const SizedBox(height: 12),
              _ShareStrip(
                teamName: teamName,
                inviteCode: _inviteCode,
                playerName: name,
              ),
            ],
          ),
        ),
        _StickyFooter(
          children: [
            _GhostBtn(label: 'Add another', onPressed: onAddAnother),
            _PrimaryBtn(
              label: 'Done',
              flex: 1,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.state});
  final AddUnclaimedPlayerState state;

  @override
  Widget build(BuildContext context) {
    final j = state.jersey.trim();
    final crestLabel = j.isEmpty ? '?' : '#$j';
    final meta = [
      state.playingRole?.label ?? 'Role TBD',
      if (state.battingStyle != null) state.battingStyle!.label,
      if (state.bowlingStyle != null) state.bowlingStyle!.label,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          _DashedCrest(label: crestLabel, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.name.trim().isEmpty
                            ? 'New player'
                            : state.name.trim(),
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _UnclaimedPill(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: CkType.mono(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStrip extends StatelessWidget {
  const _ShareStrip({
    required this.teamName,
    required this.inviteCode,
    required this.playerName,
  });

  final String teamName;
  final String inviteCode;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_forward_rounded,
              size: 16, color: CkColors.amber.withValues(alpha: 0.95)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: CkType.body(
                  fontSize: 12,
                  color: const Color(0xFF6A4D1A),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'Share $teamName invite code '),
                  TextSpan(
                    text: inviteCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  TextSpan(
                    text:
                        ' so ${playerName.isEmpty ? 'they' : playerName} can claim this spot.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CkColors.amber,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'SHARE',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
