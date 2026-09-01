import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_standing.dart';

/// Pinned-column points table engineered for a 390px mobile viewport.
class CkStandingsTable extends StatefulWidget {
  const CkStandingsTable({
    super.key,
    required this.standings,
    this.qualificationCutRank = 4,
    this.cutLabel = 'QUALIFICATION CUT LINE (TOP 4 ADVANCE)',
    this.onTeamTap,
  });

  final List<TournamentStanding> standings;
  final int qualificationCutRank;
  final String cutLabel;
  final ValueChanged<String>? onTeamTap;

  @override
  State<CkStandingsTable> createState() => _CkStandingsTableState();
}

class _CkStandingsTableState extends State<CkStandingsTable> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  String? _expandedTeamId;

  @override
  void initState() {
    super.initState();
    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    if (widget.standings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No standings records yet. Matches in progress will compute points table automatically.',
          style: CkType.body(fontSize: 13, color: CkColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Detect distinct groups
    final groups = <String>{};
    for (final s in widget.standings) {
      if (s.groupId != null && s.groupId!.trim().isNotEmpty) {
        groups.add(s.groupId!.trim());
      }
    }
    final sortedGroups = groups.toList()..sort();
    final hasMultipleGroups = sortedGroups.length > 1;

    final displayedStandings = List<TournamentStanding>.from(
      _selectedGroupId == null
          ? widget.standings
          : widget.standings.where((s) => s.groupId == _selectedGroupId),
    )..sort((a, b) {
        final ptsCmp = b.points.compareTo(a.points);
        if (ptsCmp != 0) return ptsCmp;
        return b.netRunRate.compareTo(a.netRunRate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMultipleGroups) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildGroupPill(
                  label: 'All Teams (${widget.standings.length})',
                  isSelected: _selectedGroupId == null,
                  onTap: () => setState(() => _selectedGroupId = null),
                ),
                const SizedBox(width: 8),
                ...sortedGroups.map((grp) {
                  final grpCount =
                      widget.standings.where((s) => s.groupId == grp).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildGroupPill(
                      label: '$grp ($grpCount)',
                      isSelected: _selectedGroupId == grp,
                      onTap: () => setState(() => _selectedGroupId = grp),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: CkColors.hairline),
        ],
        _buildHeader(),
        const Divider(height: 1, thickness: 1, color: CkColors.hairline),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedStandings.length,
          itemBuilder: (context, index) {
            final standing = displayedStandings[index];
            final rank = index + 1;
            final isCutLine = rank == widget.qualificationCutRank &&
                index < displayedStandings.length - 1;

            return Column(
              children: [
                _buildRow(standing, rank),
                if (_expandedTeamId == standing.teamId)
                  _buildExpandedDetails(standing),
                if (isCutLine) _buildCutLine(),
                const Divider(height: 1, thickness: 1, color: CkColors.hairline),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CkColors.ink : CkColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : CkColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 38,
      color: CkColors.paper2,
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.only(left: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              'TEAM',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: CkColors.muted,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _headerCell('P', 34),
                  _headerCell('W', 34),
                  _headerCell('L', 34),
                  _headerCell('T', 30),
                  _headerCell('NR', 30),
                  _headerCell('PTS', 42, isBold: true),
                  _headerCell('NRR', 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, {bool isBold = false}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          color: isBold ? CkColors.ink : CkColors.muted,
        ),
      ),
    );
  }

  Widget _buildRow(TournamentStanding standing, int rank) {
    final isExpanded = _expandedTeamId == standing.teamId;
    final teamName = standing.teamName ?? 'Team';
    final monogram = teamName.length >= 2
        ? teamName.substring(0, 2).toUpperCase()
        : teamName;

    Color parsedColor = CkColors.ink2;
    if (standing.teamPrimaryColor != null &&
        standing.teamPrimaryColor!.startsWith('#')) {
      final hex = standing.teamPrimaryColor!.replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          _expandedTeamId = isExpanded ? null : standing.teamId;
        });
      },
      child: Container(
        height: 48,
        color: isExpanded ? CkColors.paper2 : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 140,
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '$rank',
                      style: CkType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: rank <= widget.qualificationCutRank
                            ? CkColors.green
                            : CkColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: parsedColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        monogram,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teamName,
                      style: CkType.display(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _bodyScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _dataCell('${standing.matchesPlayed}', 34),
                    _dataCell('${standing.wins}', 34),
                    _dataCell('${standing.losses}', 34),
                    _dataCell('${standing.ties}', 30),
                    _dataCell('${standing.noResults}', 30),
                    _dataCell('${standing.points}', 42, isBold: true),
                    _dataCell(standing.formattedNrr, 64, isMono: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataCell(String val, double width,
      {bool isBold = false, bool isMono = true}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        val,
        style: isMono
            ? CkType.mono(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? CkColors.ink : CkColors.ink2,
              )
            : CkType.body(fontSize: 12),
      ),
    );
  }

  Widget _buildCutLine() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: const BoxDecoration(
        color: CkColors.cream,
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_drop_up, size: 14, color: Color(0xFF6B5414)),
          const SizedBox(width: 4),
          Text(
            widget.cutLabel,
            style: CkType.mono(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B5414),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(TournamentStanding s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CkColors.paper2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RUN RATE BREAKDOWN',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batting: ${s.runsScored} runs in ${s.oversFaced.toStringAsFixed(1)} ov',
                  style: CkType.body(fontSize: 11.5, color: CkColors.ink2),
                ),
              ),
              Expanded(
                child: Text(
                  'Bowling: ${s.runsConceded} runs in ${s.oversBowled.toStringAsFixed(1)} ov',
                  style: CkType.body(fontSize: 11.5, color: CkColors.ink2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
