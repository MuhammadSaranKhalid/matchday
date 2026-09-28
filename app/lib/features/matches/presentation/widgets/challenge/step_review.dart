import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../pool/pool_challenge_card.dart';
import '../pool/pool_icons.dart';
import '../wizard/wizard_kit.dart';

/// Review & post — `Pool.dc.html` artboard 10.
///
/// Every block is editable, and the commit is spelled out rather than left to
/// be discovered: 48 hours on the board, 24 on the code. The primary stays ink
/// — posting is not destructive, so it earns no red.
class StepReview extends StatelessWidget {
  const StepReview({
    super.key,
    required this.team,
    this.opponentName,
    this.onEditOpponent,
    required this.formatLine,
    required this.whenLine,
    required this.whereLine,
    this.xiLine,
    required this.noteController,
    required this.onEditFormat,
    required this.onEditWhen,
    required this.onEditWhere,
    this.onEditXi,
  });

  final Team? team;
  final String? opponentName;
  final VoidCallback? onEditOpponent;
  final String formatLine;
  final String whenLine;
  final String whereLine;

  /// Null on a friendly or open challenge, which settles scheduling only —
  /// the XI is picked at the ground, so there is nothing to review here.
  final String? xiLine;
  final TextEditingController noteController;
  final VoidCallback onEditFormat;
  final VoidCallback onEditWhen;
  final VoidCallback onEditWhere;
  final VoidCallback? onEditXi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        Row(
          children: [
            Crest(
              short: teamMonogram(team),
              color: teamCrestColor(team),
              logoUrl: team?.logoUrl,
              size: 46,
              radius: 13,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'POSTING AS',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team?.name ?? 'Your team',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                      letterSpacing: -0.01,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CkColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (opponentName != null)
                _Row(
                  label: 'Opponent',
                  value: opponentName!,
                  onEdit: onEditOpponent ?? () {},
                  first: true,
                ),
              _Row(
                label: 'Format',
                value: formatLine,
                onEdit: onEditFormat,
                first: opponentName == null,
              ),
              _Row(label: 'When', value: whenLine, onEdit: onEditWhen),
              _Row(label: 'Where', value: whereLine, onEdit: onEditWhere),
              if (xiLine case final line?)
                _Row(label: 'Your XI', value: line, onEdit: onEditXi ?? () {}),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WizardFieldLabel(
          opponentName != null ? 'Note to opponent' : 'Note to applicants',
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.line),
          ),
          child: TextField(
            controller: noteController,
            maxLines: 3,
            minLines: 2,
            maxLength: 280,
            style: CkType.body(
              fontSize: 13,
              height: 1.5,
              color: CkColors.ink2,
            ).copyWith(fontStyle: FontStyle.italic),
            decoration: bareInput(
              hintText:
                  opponentName != null
                      ? 'Anything they should know? (optional)'
                      : 'Anything applicants should know? (optional)',
              hintStyle: CkType.body(
                fontSize: 13,
                height: 1.5,
                color: CkColors.soft,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: PoolIcon(PoolIcons.clockMuted, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: CkType.body(
                    fontSize: 11.5,
                    height: 1.5,
                    color: CkColors.muted,
                  ),
                  children:
                      opponentName != null
                          ? [
                            const TextSpan(text: 'Opponent will be notified. Code expires in '),
                            TextSpan(text: '24 hours', style: _strong),
                            const TextSpan(text: '.'),
                          ]
                          : [
                            const TextSpan(text: 'Live on the board for '),
                            TextSpan(text: '48 hours', style: _strong),
                            const TextSpan(text: '. Share code works for '),
                            TextSpan(text: '24 hours', style: _strong),
                            const TextSpan(text: '.'),
                          ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static TextStyle get _strong => CkType.body(
    fontSize: 11.5,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: CkColors.ink2,
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onEdit,
    this.first = false,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          border:
              first
                  ? null
                  : const Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.07,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'EDIT',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
