import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/match_player.dart';

class AddMatchPlayerSheet extends StatefulWidget {
  const AddMatchPlayerSheet({
    super.key,
    required this.onSubmit,
    this.initialSide = MatchTeamSide.a,
  });

  final MatchTeamSide initialSide;
  final Future<void> Function(MatchTeamSide side, String displayName) onSubmit;

  @override
  State<AddMatchPlayerSheet> createState() => _AddMatchPlayerSheetState();
}

class _AddMatchPlayerSheetState extends State<AddMatchPlayerSheet> {
  final _name = TextEditingController();
  late MatchTeamSide _side = widget.initialSide;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add player to this match',
              style: CkType.display(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This player is available for this match only. It does not change the team roster.',
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
            const SizedBox(height: 16),
            SegmentedButton<MatchTeamSide>(
              segments: const [
                ButtonSegment(value: MatchTeamSide.a, label: Text('Team A')),
                ButtonSegment(value: MatchTeamSide.b, label: Text('Team B')),
              ],
              selected: {_side},
              onSelectionChanged:
                  _busy ? null : (value) => setState(() => _side = value.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              enabled: !_busy,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Player name',
                hintText: 'e.g. Replacement Bowler',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed:
                  _busy
                      ? null
                      : () async {
                        final name = _name.text.trim();
                        if (name.isEmpty) return;
                        setState(() => _busy = true);
                        await widget.onSubmit(_side, name);
                        if (mounted) setState(() => _busy = false);
                      },
              child: Text(_busy ? 'Adding…' : 'Add to match'),
            ),
          ],
        ),
      ),
    );
  }
}
