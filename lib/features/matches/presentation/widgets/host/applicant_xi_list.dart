import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/domain/entities/roster_member.dart';
import '../../../../teams/domain/entities/team_member.dart';

/// One named player in an applicant's XI.
class XiEntry {
  const XiEntry({
    required this.name,
    required this.initials,
    this.captain = false,
    this.keeper = false,
  });

  final String name;
  final String initials;
  final bool captain;
  final bool keeper;
}

/// Resolves an applicant's XI ids against their roster.
///
/// Player ids are polymorphic (a profile id **or** an unclaimed id), so this
/// matches on [TeamMember.playerId] rather than assuming either. An id with no
/// roster row still gets a row — the host should see that the XI has eleven
/// names in it even if one of them cannot be resolved.
List<XiEntry> resolveXi({
  required List<String> xi,
  required List<RosterMember> roster,
  String? keeperId,
}) {
  final byId = {for (final m in roster) m.member.playerId: m};

  return [
    for (final id in xi)
      if (byId[id] case final member?)
        XiEntry(
          name: member.displayName,
          initials: _initials(member.displayName),
          captain: member.member.topRole.hasMatchAuthority,
          // The keeper is whoever the applicant nominated for THIS match.
          // There is no team-level keeper to fall back on any more — that was
          // a duplicate of match_players.role and always the weaker answer.
          keeper: id == keeperId,
        )
      else
        XiEntry(name: 'Unnamed player', initials: '—', keeper: id == keeperId),
  ];
}

String _initials(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '—';
  if (words.length == 1) {
    final one = words.first;
    return (one.length >= 2 ? one.substring(0, 2) : one).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

/// The applicant's line-up as ruled rows with C / WK marks — `Pool.dc.html`
/// artboard 16. Enough to judge the opponent before accepting.
///
/// Long XIs collapse to [previewCount] with a "+ N more" row; the design shows
/// the collapsed form, and the row expands rather than truncating outright,
/// because a host deciding on an opponent should be able to see all eleven.
class ApplicantXiList extends StatefulWidget {
  const ApplicantXiList({
    super.key,
    required this.entries,
    this.previewCount = 4,
  });

  final List<XiEntry> entries;
  final int previewCount;

  @override
  State<ApplicantXiList> createState() => _ApplicantXiListState();
}

class _ApplicantXiListState extends State<ApplicantXiList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.entries;
    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          'This team applied without naming an XI.',
          style: CkType.body(fontSize: 13, color: CkColors.muted),
        ),
      );
    }

    final hidden = all.length - widget.previewCount;
    final shown =
        _expanded || hidden <= 0 ? all : all.take(widget.previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) _row(i + 1, shown[i]),
        if (!_expanded && hidden > 0)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CkColors.hairline)),
              ),
              child: Text(
                '+ $hidden more'.toUpperCase(),
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: CkColors.soft,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(int number, XiEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$number',
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: CkColors.soft,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.hairline),
            ),
            child: Text(
              entry.initials,
              style: CkType.display(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CkColors.ink2,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
                letterSpacing: -0.01,
              ),
            ),
          ),
          if (entry.captain) _mark('C'),
          if (entry.captain && entry.keeper) const SizedBox(width: 5),
          if (entry.keeper) _mark('WK'),
        ],
      ),
    );
  }

  Widget _mark(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: CkColors.paper,
        ),
      ),
    );
  }
}
