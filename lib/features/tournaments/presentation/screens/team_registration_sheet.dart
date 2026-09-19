import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_text_field.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// 4-Step Team Registration Wizard for Tournament Entrants (Artboards 29–33).
///
/// Step 1: Select team (Artboard 30)
/// Step 2: Squad picker with pinned counter (Artboard 31)
/// Step 3: Rules & fee agreement (Artboard 32)
/// Step 4: Status tracker (Artboard 33)
class TeamRegistrationSheet extends ConsumerStatefulWidget {
  const TeamRegistrationSheet({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TeamRegistrationSheet> createState() =>
      _TeamRegistrationSheetState();
}

class _TeamRegistrationSheetState extends ConsumerState<TeamRegistrationSheet> {
  static final _money = NumberFormat.decimalPattern();

  int _currentStep = 0; // 0: Team, 1: Squad, 2: Rules & Fee
  String? _selectedTeamId;
  final Set<String> _selectedPlayerIds = {};
  String? _captainPlayerId;
  String? _wicketKeeperPlayerId;

  // Guest players added for this tournament entry
  final List<Map<String, String>> _guestPlayers = [];

  // Step 3 rules agreement
  bool _rulesAgreed = false;
  String? _errorMessage;

  int _minSquad(Tournament t) =>
      (t.rules['min_squad'] as num?)?.toInt() ?? 11;

  int _maxSquad(Tournament t) =>
      (t.rules['max_squad'] as num?)?.toInt() ?? 16;

  int _overs(Tournament t) =>
      (t.format['max_overs'] as num?)?.toInt() ?? 20;

  int _maxPerBowler(Tournament t) =>
      (t.rules['max_overs_per_bowler'] as num?)?.toInt() ?? (_overs(t) ~/ 5).clamp(1, 10);

  String _ballType(Tournament t) =>
      (t.rules['ball_type'] as String?) ?? 'Leather (Red)';

  void _nextStep(Tournament tournament) {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      if (_selectedTeamId == null) {
        setState(() => _errorMessage = 'Please select a team to register.');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      final total = _selectedPlayerIds.length + _guestPlayers.length;
      final min = _minSquad(tournament);
      final max = _maxSquad(tournament);
      if (total < min) {
        setState(() => _errorMessage =
            'Please select at least $min players ($total selected).');
        return;
      }
      if (total > max) {
        setState(() => _errorMessage =
            'Maximum $max players allowed ($total selected).');
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    setState(() => _errorMessage = null);
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submitRegistration() async {
    if (!_rulesAgreed) {
      setState(() => _errorMessage =
          'Please agree to tournament eligibility rules and match schedules.');
      return;
    }

    final allPlayerIds = [
      ..._selectedPlayerIds,
      ..._guestPlayers.map((g) => 'guest_${g['name']}'),
    ];

    final noteParts = <String>[];
    if (_captainPlayerId != null) {
      noteParts.add('Captain: $_captainPlayerId');
    }
    if (_wicketKeeperPlayerId != null) {
      noteParts.add('WK: $_wicketKeeperPlayerId');
    }

    final reg = await ref
        .read(tournamentsControllerProvider.notifier)
        .registerTeam(
          tournamentId: widget.tournamentId,
          teamId: _selectedTeamId!,
          squadPlayerIds: allPlayerIds,
          message: noteParts.isEmpty ? null : noteParts.join(' | '),
        );

    if (reg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted! The organizer has been notified.',
          ),
          backgroundColor: Color(0xFF1E5A2C),
        ),
      );
      // Navigate to status tracker (Artboard 33)
      context.pushReplacement('/tournaments/${widget.tournamentId}/register/status');
    }
  }

  void _showAddGuestDialog() {
    final nameCtrl = TextEditingController();
    String guestRole = 'All-Rounder';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ADD GUEST PLAYER',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CkTextField(
                    label: 'Player Name',
                    controller: nameCtrl,
                    hint: 'e.g. Uncle Asif',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PLAYING ROLE',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Top order',
                      'Middle order',
                      'Pace',
                      'Spin',
                      'All-Rounder',
                      'Wicketkeeper'
                    ].map((role) {
                      final isSel = guestRole == role;
                      return ChoiceChip(
                        label: Text(role),
                        selected: isSel,
                        selectedColor: CkColors.ink,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : CkColors.ink,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: CkColors.paper2,
                        onSelected: (_) {
                          setModalState(() => guestRole = role);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          setState(() {
                            _guestPlayers.add({
                              'name': nameCtrl.text.trim(),
                              'role': guestRole,
                            });
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CkColors.ink,
                        foregroundColor: CkColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add to Squad'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    // Tournament registration is a staff capability. Memberships carry the
    // canonical relationship, so player/captain-only memberships never enter
    // the selectable team list.
    final myTeamsAsync = ref.watch(currentUserTeamMembershipsProvider).whenData(
          (memberships) => memberships
              .where((m) => m.relationship.canRegisterForTournament)
              .map((m) => m.team)
              .toList(growable: false),
        );
    final registrationsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));
    final isBusy = ref.watch(tournamentsControllerProvider).isLoading;

    return tournamentAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: Text('$e')),
      ),
      data: (tournament) {
        return myTeamsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: CkColors.paper,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: CkColors.paper,
            body: Center(child: Text('$e')),
          ),
          data: (myTeams) {
            final allRegs = registrationsAsync.value ?? const <TournamentRegistration>[];
            final registeredTeamIds = allRegs.map((r) => r.teamId).toSet();


            return Scaffold(
              backgroundColor: CkColors.paper,
              appBar: AppBar(
                backgroundColor: CkColors.paper,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    _currentStep == 0 ? Icons.close : Icons.arrow_back,
                    color: CkColors.ink,
                  ),
                  onPressed: _prevStep,
                ),
                titleSpacing: 0,
                title: Text(
                  _currentStep == 0
                      ? tournament.name
                      : '${_selectedTeam(myTeams)?.name ?? "Your team"} · ${tournament.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // Continuous 4px linear progress bar (Artboards 30–32)
                    _buildProgressBar(),

                    // Step indicator and title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STEP ${_currentStep + 1} OF 4',
                              style: CkType.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.12,
                                color: CkColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              switch (_currentStep) {
                                0 => 'Which team is playing?',
                                1 => 'Pick your squad',
                                _ => 'Before you submit',
                              },
                              style: CkType.display(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.02,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFECA39E)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: CkColors.redInk),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: CkType.body(
                                    fontSize: 12,
                                    color: CkColors.redInk,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Step content
                    Expanded(
                      child: switch (_currentStep) {
                        0 => _buildStep1SelectTeam(myTeams, registeredTeamIds, tournament),
                        1 => _buildStep2SquadPicker(myTeams, tournament),
                        _ => _buildStep3RulesAndFee(tournament, myTeams),
                      },
                    ),

                    // Bottom navigation bar (Artboard 30–32)
                    _buildBottomBar(tournament, isBusy),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final fraction = (_currentStep + 1) / 4.0;

    return Container(
      height: 4,
      width: double.infinity,
      color: const Color(0xFFF3F0E9),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Team? _selectedTeam(List<Team> myTeams) {
    if (_selectedTeamId == null) return null;
    return myTeams.where((t) => t.id.value == _selectedTeamId).firstOrNull;
  }

  // ─── Step 1: Select Team (Artboard 30) ─────────────────────────────────────

  Widget _buildStep1SelectTeam(
    List<Team> myTeams,
    Set<String> registeredTeamIds,
    Tournament tournament,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text(
          'YOUR TEAMS · ${myTeams.length}',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        for (final team in myTeams) ...[
          _buildTeamCard(team, registeredTeamIds, tournament),
          const SizedBox(height: 8),
        ],

        // Dashed Create Team Card (Artboard 30)
        InkWell(
          onTap: () => context.push('/teams/create'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CkColors.hairline,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F0E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: CkColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a new team',
                        style: CkType.display(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'You will need at least ${_minSquad(tournament)} players before registering.',
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(
    Team team,
    Set<String> registeredTeamIds,
    Tournament tournament,
  ) {
    final isRegistered = registeredTeamIds.contains(team.id.value);
    // Roster is loaded separately via rosterProvider — use managers count as
    // a conservative floor for Step 1 eligibility; Step 2 shows the real list.
    final rosterAsync = ref.watch(rosterProvider(team.id.value));
    final squadCount = rosterAsync.value?.length ?? 0;
    final minSquad = _minSquad(tournament);
    final hasEnoughPlayers = squadCount >= minSquad;
    final isEligible = !isRegistered && hasEnoughPlayers;
    final isSelected = _selectedTeamId == team.id.value;

    return InkWell(
      onTap: isEligible
          ? () {
              final roster = rosterAsync.value ?? const <RosterMember>[];
              setState(() {
                _selectedTeamId = team.id.value;
                // Pre-select first max-squad members
                _selectedPlayerIds.clear();
                _selectedPlayerIds.addAll(
                  roster.take(_maxSquad(tournament)).map((RosterMember m) => m.member.playerId),
                );
                if (roster.isNotEmpty) {
                  _captainPlayerId ??= roster.first.member.playerId;
                  if (roster.length > 1) {
                    _wicketKeeperPlayerId ??= roster[1].member.playerId;
                  }
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: isEligible ? 1.0 : 0.75,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? CkColors.ink
                : CkColors.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle indicator (Artboard 30)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? CkColors.ink
                      : isEligible
                          ? const Color(0xFFB9B1A2)
                          : CkColors.hairline,
                  width: isSelected ? 5 : 1.5,
                ),
                color: isSelected ? CkColors.paper : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            // Monogram
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0E9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEligible ? CkColors.hairline : const Color(0xFFB9B1A2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                (team.name.length >= 2 ? team.name.substring(0, 2) : 'TM').toUpperCase(),
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isEligible ? CkColors.ink : CkColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isEligible ? CkColors.ink : CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isRegistered)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4ECDD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDED0AC)),
                      ),
                      child: Text(
                        'ALREADY REGISTERED · PENDING',
                        style: CkType.mono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B5414),
                        ),
                      ),
                    )
                  else if (!hasEnoughPlayers)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4ECDD),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDED0AC)),
                          ),
                          child: Text(
                            'NEEDS $minSquad PLAYERS · HAS $squadCount',
                            style: CkType.mono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B5414),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/teams/${team.id.value}'),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Add players to this team →',
                              style: CkType.body(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: CkColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '$squadCount players · eligible',
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
       ),
      ),
    );
  }

  // ─── Step 2: Squad Picker (Artboard 31) ────────────────────────────────────

  Widget _buildStep2SquadPicker(List<Team> myTeams, Tournament tournament) {
    final roster = _selectedTeamId != null
        ? (ref.watch(rosterProvider(_selectedTeamId!)).value ?? const <RosterMember>[])
        : const <RosterMember>[];
    final totalSelected = _selectedPlayerIds.length + _guestPlayers.length;
    final minSquad = _minSquad(tournament);
    final maxSquad = _maxSquad(tournament);
    final hasMetMin = totalSelected >= minSquad;
    final remainingSlots = (maxSquad - totalSelected).clamp(0, maxSquad);

    return Column(
      children: [
        // Pinned sticky squad counter card (Artboard 31)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT SQUAD ROSTER',
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.10,
                          color: CkColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasMetMin
                            ? 'Minimum $minSquad met · $remainingSlots slots left'
                            : 'Need ${minSquad - totalSelected} more to meet minimum $minSquad',
                        style: CkType.body(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: hasMetMin ? const Color(0xFF1E5A2C) : const Color(0xFF8C5311),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$totalSelected',
                        style: CkType.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: ' / $maxSquad',
                        style: CkType.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Player roster list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CkColors.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final member in roster) ...[
                        _buildPlayerRow(member.member.playerId, member.displayName),
                        const Divider(height: 1, color: CkColors.hairline),
                      ],
                    for (final guest in _guestPlayers) ...[
                      _buildGuestRow(guest),
                      const Divider(height: 1, color: CkColors.hairline),
                    ],
                    // Footnote
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '* Unclaimed guest player on team roster.',
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Add guest button
              OutlinedButton.icon(
                onPressed: _showAddGuestDialog,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add Guest Player to Squad'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CkColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(String playerId, [String? displayName]) {
    final isSelected = _selectedPlayerIds.contains(playerId);
    final isCaptain = _captainPlayerId == playerId;
    final isWK = _wicketKeeperPlayerId == playerId;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPlayerIds.remove(playerId);
            if (isCaptain) _captainPlayerId = null;
            if (isWK) _wicketKeeperPlayerId = null;
          } else {
            _selectedPlayerIds.add(playerId);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? CkColors.ink : CkColors.paper,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected ? CkColors.ink : const Color(0xFFB9B1A2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: CkColors.paper)
                  : null,
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0E9),
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              alignment: Alignment.center,
              child: Text(
                (displayName ?? playerId).substring(0, (displayName ?? playerId).length >= 2 ? 2 : 1).toUpperCase(),
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName ?? playerId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isCaptain) ...[
                    const SizedBox(width: 4),
                    Text('(CAPT)', style: CkType.mono(fontSize: 9.5, fontWeight: FontWeight.w700, color: CkColors.muted)),
                  ],
                  if (isWK) ...[
                    const SizedBox(width: 4),
                    Text('(WK)', style: CkType.mono(fontSize: 9.5, fontWeight: FontWeight.w700, color: CkColors.muted)),
                  ],
                ],
              ),
            ),
            // C and WK designation pills
            if (isSelected) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _captainPlayerId = isCaptain ? null : playerId;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCaptain ? CkColors.ink : const Color(0xFFF3F0E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'C',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isCaptain ? CkColors.paper : CkColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _wicketKeeperPlayerId = isWK ? null : playerId;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isWK ? CkColors.ink : const Color(0xFFF3F0E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'WK',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isWK ? CkColors.paper : CkColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(Map<String, String> guest) {
    final name = guest['name'] ?? 'Guest';
    final role = guest['role'] ?? 'Player';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.check, size: 13, color: CkColors.paper),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB9B1A2), style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: Text(
              name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
              style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, color: CkColors.muted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '*$name (Guest)',
              style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(role, style: CkType.body(fontSize: 11, color: CkColors.muted)),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: CkColors.muted),
            onPressed: () => setState(() => _guestPlayers.remove(guest)),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Rules & Fee (Artboard 32) ─────────────────────────────────────

  Widget _buildStep3RulesAndFee(Tournament tournament, List<Team> myTeams) {
    final fee = tournament.entryFee ?? 0;
    final totalPlayers = _selectedPlayerIds.length + _guestPlayers.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text(
          'MATCH RULES',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),

        // 2x2 rules grid (Artboard 32)
        Container(
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRuleCell('Overs per innings', '${_overs(tournament)}'),
                  ),
                  Container(width: 1, height: 56, color: CkColors.hairline),
                  Expanded(
                    child: _buildRuleCell('Max per bowler', '${_maxPerBowler(tournament)}'),
                  ),
                ],
              ),
              const Divider(height: 1, color: CkColors.hairline),
              Row(
                children: [
                  Expanded(
                    child: _buildRuleCell('Ball', _ballType(tournament)),
                  ),
                  Container(width: 1, height: 56, color: CkColors.hairline),
                  Expanded(
                    child: _buildRuleCell('Your squad', '$totalPlayers of ${_minSquad(tournament)}–${_maxSquad(tournament)}'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Rules bullet points (Artboard 32)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBullet('Points: win 2 · tie or no result 1 · loss 0'),
              _buildBullet('Teams that do not arrive within 20 minutes of start forfeit the match'),
              _buildBullet('Squads are locked once the draw is published — no substitutions after that'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Entry Fee card (Artboard 32)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECDD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDED0AC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ENTRY FEE',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: const Color(0xFF6B5414),
                      ),
                    ),
                  ),
                  Text(
                    fee > 0 ? 'PKR ${_money.format(fee)}' : 'FREE',
                    style: CkType.mono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                fee > 0
                    ? 'This tournament has an entry fee of PKR ${_money.format(fee)}. '
                      'Please arrange cash or bank transfer directly with the organiser. '
                      'Your registration will show as Pending Payment until they confirm.'
                    : 'This tournament is free to enter. Your registration will sit in review until approved.',
                style: CkType.body(
                  fontSize: 12,
                  height: 1.5,
                  color: const Color(0xFF4A4339),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Mandatory Agreement Checkbox Card (Artboard 32)
        InkWell(
          onTap: () => setState(() => _rulesAgreed = !_rulesAgreed),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _rulesAgreed ? CkColors.ink : CkColors.hairline,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _rulesAgreed ? CkColors.ink : CkColors.paper,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _rulesAgreed ? CkColors.ink : const Color(0xFFB9B1A2),
                      width: 1.5,
                    ),
                  ),
                  child: _rulesAgreed
                      ? const Icon(Icons.check, size: 13, color: CkColors.paper)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I have read the rules and understand the entry fee is arranged directly with the organiser.',
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.45,
                      color: const Color(0xFF4A4339),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCell(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CkType.body(fontSize: 11, color: CkColors.muted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: CkType.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: const BoxDecoration(
              color: CkColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: CkType.body(fontSize: 11.5, height: 1.4, color: CkColors.ink2),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation Bar ─────────────────────────────────────────────────

  Widget _buildBottomBar(Tournament tournament, bool isBusy) {
    final totalSelected = _selectedPlayerIds.length + _guestPlayers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CkColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == 0 ? 'Cancel' : 'Back',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          _nextStep(tournament);
                        } else {
                          _submitRegistration();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_currentStep == 2 && !_rulesAgreed)
                      ? const Color(0xFFF3F0E9)
                      : CkColors.ink,
                  foregroundColor: (_currentStep == 2 && !_rulesAgreed)
                      ? CkColors.muted
                      : CkColors.paper,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CkColors.paper,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            switch (_currentStep) {
                              0 => 'Continue',
                              1 => 'Continue · $totalSelected selected',
                              _ => 'Submit Registration',
                            },
                            style: CkType.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_currentStep == 2 && !_rulesAgreed)
                                  ? CkColors.muted
                                  : CkColors.paper,
                            ),
                          ),
                          if (_currentStep < 2) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: (_currentStep == 2 && !_rulesAgreed)
                                  ? CkColors.muted
                                  : CkColors.paper,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
