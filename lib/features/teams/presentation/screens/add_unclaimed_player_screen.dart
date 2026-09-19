import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/player_skills.dart';
import '../controllers/add_unclaimed_player_controller.dart';
import '../state/add_unclaimed_player_state.dart';

/// Add-offline-player flow using the established Matchday stepped-sheet visual
/// language. The player is created through the cleaned repository/RPC path.
class AddUnclaimedPlayerScreen extends ConsumerWidget {
  const AddUnclaimedPlayerScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addUnclaimedPlayerControllerProvider(teamId));
    final controller =
        ref.read(addUnclaimedPlayerControllerProvider(teamId).notifier);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (state.step) {
          AddUnclaimedPlayerStep.success => _Success(
              name: state.name,
              onDone: () => context.canPop()
                  ? context.pop()
                  : context.go('/teams/$teamId/manage?tab=roster'),
              onAnother: controller.resetForAnother,
            ),
          _ => Column(
              children: [
                _TopBar(
                  step: state.step == AddUnclaimedPlayerStep.name ? 1 : 2,
                  onBack: () {
                    if (state.step == AddUnclaimedPlayerStep.details) {
                      controller.back();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/teams/$teamId/manage?tab=roster');
                    }
                  },
                ),
                Expanded(
                  child: state.step == AddUnclaimedPlayerStep.name
                      ? _NameStep(state: state, onChanged: controller.setName)
                      : _DetailsStep(
                          state: state,
                          onJersey: controller.setJersey,
                          onRole: controller.setPlayingRole,
                          onBatting: controller.setBattingStyle,
                          onBowling: controller.setBowlingStyle,
                        ),
                ),
                _Footer(
                  state: state,
                  onContinue: controller.next,
                  onSubmit: controller.submit,
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    'ADD OFFLINE PLAYER · $step/2',
                    textAlign: TextAlign.center,
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .10,
                      color: CkColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                Expanded(child: _bar(true)),
                const SizedBox(width: 4),
                Expanded(child: _bar(step >= 2)),
              ],
            ),
          ),
          const Divider(height: 1, color: CkColors.hairline),
        ],
      );

  Widget _bar(bool active) => Container(
        height: 3,
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
        ),
      );
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.state, required this.onChanged});
  final AddUnclaimedPlayerState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
        children: [
          Text(
            'Who are you adding?',
            style: CkType.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -.025,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add a teammate who does not have a Matchday account yet. They can claim this roster identity later.',
            style: CkType.body(fontSize: 13, height: 1.45, color: CkColors.muted),
          ),
          const SizedBox(height: 26),
          Text(
            'PLAYER NAME',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            initialValue: state.name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: onChanged,
            style: CkType.body(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Saif Khan',
              filled: true,
              fillColor: CkColors.paper2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CkColors.hairline),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: CkColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This creates an offline roster placeholder, not a user account. Matchday can link it to the real player later.',
                    style: CkType.body(fontSize: 11.5, height: 1.4, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.state,
    required this.onJersey,
    required this.onRole,
    required this.onBatting,
    required this.onBowling,
  });
  final AddUnclaimedPlayerState state;
  final ValueChanged<String> onJersey;
  final ValueChanged<PlayingRole?> onRole;
  final ValueChanged<BattingStyle?> onBatting;
  final ValueChanged<BowlingStyle?> onBowling;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: CkColors.ink,
                child: Text(
                  state.name.trim().isEmpty ? '?' : state.name.trim()[0].toUpperCase(),
                  style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700, color: CkColors.paper),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.name, style: CkType.display(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Offline roster player', style: CkType.body(fontSize: 12, color: CkColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _label('JERSEY NUMBER'),
          TextFormField(
            initialValue: state.jersey,
            onChanged: onJersey,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            decoration: const InputDecoration(hintText: 'Optional · e.g. 7'),
          ),
          const SizedBox(height: 20),
          _label('PLAYING ROLE'),
          _OptionWrap<PlayingRole>(
            values: PlayingRole.values,
            selected: state.playingRole,
            label: (value) => value.label,
            onTap: onRole,
          ),
          const SizedBox(height: 20),
          _label('BATTING'),
          _OptionWrap<BattingStyle>(
            values: BattingStyle.values,
            selected: state.battingStyle,
            label: (value) => value.label,
            onTap: onBatting,
          ),
          const SizedBox(height: 20),
          _label('BOWLING'),
          _OptionWrap<BowlingStyle>(
            values: BowlingStyle.values,
            selected: state.bowlingStyle,
            label: (value) => value.label,
            onTap: onBowling,
          ),
          if (state.submitError != null) ...[
            const SizedBox(height: 16),
            Text(state.submitError!, style: CkType.body(fontSize: 12, color: CkColors.red)),
          ],
        ],
      );

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          value,
          style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .10, color: CkColors.muted),
        ),
      );
}

class _OptionWrap<T> extends StatelessWidget {
  const _OptionWrap({
    required this.values,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T?> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(label(value)),
              selected: selected == value,
              onSelected: (yes) => onTap(yes ? value : null),
              selectedColor: CkColors.ink,
              backgroundColor: CkColors.paper2,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected == value ? CkColors.paper : CkColors.ink,
              ),
              side: const BorderSide(color: CkColors.hairline),
            ),
        ],
      );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.onContinue,
    required this.onSubmit,
  });
  final AddUnclaimedPlayerState state;
  final VoidCallback onContinue;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final first = state.step == AddUnclaimedPlayerStep.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: state.submitting || (first && state.name.trim().isEmpty)
              ? null
              : first
                  ? onContinue
                  : () => onSubmit(),
          child: state.submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(first ? 'Continue' : 'Add player'),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.name, required this.onDone, required this.onAnother});
  final String name;
  final VoidCallback onDone;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: CkColors.greenSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 34, color: CkColors.green),
              ),
              const SizedBox(height: 18),
              Text(
                '$name is in the squad.',
                textAlign: TextAlign.center,
                style: CkType.display(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.02),
              ),
              const SizedBox(height: 7),
              Text(
                'They can claim this roster identity later when they join Matchday.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 13, height: 1.4, color: CkColors.muted),
              ),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: const Text('Back to roster'))),
              TextButton(onPressed: onAnother, child: const Text('Add another player')),
            ],
          ),
        ),
      );
}
