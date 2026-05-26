import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// About tab — optional disbanded callout (archived) + about prose + details
/// table + managers list.
class TpAboutTab extends StatelessWidget {
  const TpAboutTab({super.key, required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        if (team.archived != null) _DisbandedCallout(date: team.archived!),
        if (team.about.isNotEmpty) ...[
          Text('ABOUT', style: tpMono()),
          const SizedBox(height: 6),
          Text(
            team.about,
            style: CkType.body(
              fontSize: 14,
              color: CkColors.ink2,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (team.details.isNotEmpty) ...[
          Text('DETAILS', style: tpMono()),
          const SizedBox(height: 8),
          _DetailsTable(rows: team.details),
          const SizedBox(height: 18),
        ],
        if (team.managers.isNotEmpty) ...[
          Text('MANAGERS · ${team.managers.length}', style: tpMono()),
          const SizedBox(height: 8),
          _ManagersList(managers: team.managers),
        ],
      ],
    );
  }
}

class _DisbandedCallout extends StatelessWidget {
  const _DisbandedCallout({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: CustomPaint(
        painter: _DashedPainter(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: CkColors.paper2,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISBANDED · ${date.toUpperCase()}',
                    style: tpMono(color: CkColors.ink)),
                const SizedBox(height: 6),
                Text(
                  "This team's record is preserved for historical "
                  'reference. Profile and stats are read-only.',
                  style: CkType.body(
                    fontSize: 12.5,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DetailsTable extends StatelessWidget {
  const _DetailsTable({required this.rows});
  final List<TpDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: CkColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label.toUpperCase(),
                      style: tpMono(),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ManagersList extends StatelessWidget {
  const _ManagersList({required this.managers});
  final List<TpManagerRow> managers;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '–';
    if (parts.length == 1) {
      final first = parts.first;
      return first.length >= 2
          ? first.substring(0, 2).toUpperCase()
          : first.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < managers.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: CkColors.hairline)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      shape: BoxShape.circle,
                      border: Border.all(color: CkColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(managers[i].name),
                      style: CkType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: CkColors.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          managers[i].name,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          managers[i].role,
                          style: CkType.body(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
