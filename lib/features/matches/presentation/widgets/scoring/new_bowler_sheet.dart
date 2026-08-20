// Opening-bowler and end-of-over bowler selection.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import 'sheet_kit.dart';

class NewBowlerSheet extends StatefulWidget {
  const NewBowlerSheet({super.key, 
    required this.overNumber,
    required this.justBowled,
    required this.people,
    this.title = 'Next bowler?',
    this.kicker,
  });
  final int overNumber;
  final String? justBowled;
  final List<SheetPerson> people;
  final String title;
  final String? kicker;
  @override
  State<NewBowlerSheet> createState() => _NewBowlerSheetState();
}

class _NewBowlerSheetState extends State<NewBowlerSheet> {
  String? _pick;
  @override
  Widget build(BuildContext context) {
    final kicker = widget.kicker ?? 'OVER ${widget.overNumber} COMPLETE';
    final sub = widget.justBowled == null
        ? 'Pick the player who will bowl the first over.'
        : '${widget.justBowled} can\'t bowl two overs in a row.';
    return SheetScrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHead(
              kicker: kicker,
              title: widget.title,
              subtitle: sub,
            ),
            SheetPersonGrid(
              people: widget.people,
              value: _pick,
              onPick: (id) => setState(() => _pick = id),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SheetGhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SheetPrimaryButton(
                    label: 'Start over',
                    onTap: _pick == null
                        ? null
                        : () => Navigator.of(context).pop(_pick),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
